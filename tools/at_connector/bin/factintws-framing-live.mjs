#!/usr/bin/env node
import https from 'node:https';
import { randomBytes } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { validateAtUsername } from '../src/auth.mjs';
import { inspectAtCipherPublicKey, readAtPublicKey } from '../src/crypto.mjs';
import { buildFactIntWsEnvelope, buildFactIntWsLiveReadinessMatrix,
  buildFactIntWsSecurityMaterial, FACTINTWS_ENDPOINT_8443, FACTINTWS_OPERATION,
  factIntWsHttpContract, factIntWsTlsOptions,
  resolveFactIntWsChannelFromEnvironment } from '../src/factintws.mjs';
import { parseFactIntWsResponse } from '../src/factintws_parser.mjs';
import { resolveFactIntWsCreated } from '../src/factintws_time.mjs';
import { ntpProviderFromEnvironment } from '../src/ntp.mjs';
import { redact } from '../src/redaction.mjs';
import { analyzeHttpResponseFraming, sanitizedFramingMetadata } from '../src/response_framing.mjs';
import { inspectPfxReadiness, PfxPreflightClassification,
  tlsFailureDiagnostic } from '../src/tls_preflight.mjs';
import { tlsMetadataFromSocket } from '../src/transport.mjs';

const required = ['AT_USERNAME', 'AT_PASSWORD', 'AT_CIPHER_CERT_PATH',
  'AT_CLIENT_PFX_PATH', 'AT_CLIENT_PFX_PASSWORD'];
let networkRequests = 0;
const output = (value) => process.stdout.write(`${JSON.stringify(redact(value), null, 2)}\n`);
const fail = (classification, message) => {
  output({ networkRequests, retries: 0, classification, message });
  process.exitCode = 2;
};

function sendFramingRequest({ xml, pfx, passphrase }) {
  const contract = factIntWsHttpContract(FACTINTWS_OPERATION, FACTINTWS_ENDPOINT_8443);
  return new Promise((resolve, reject) => {
    let tlsStage = 'socket-creation'; let tlsAtSecureConnect = null;
    const request = https.request(contract.endpoint, {
      method: contract.method, pfx, passphrase, rejectUnauthorized: true,
      ...factIntWsTlsOptions(),
      headers: { ...contract.headers, 'Content-Length': Buffer.byteLength(xml) },
      timeout: 20_000,
    }, (response) => {
      const tls = tlsMetadataFromSocket(response.socket); const chunks = [];
      response.on('data', (chunk) => chunks.push(chunk));
      response.on('end', () => resolve({ httpStatus: response.statusCode ?? null,
        headers: response.headers, tls, bytes: Buffer.concat(chunks),
        soapAction: contract.headers.SOAPAction }));
    });
    request.on('socket', (socket) => {
      tlsStage = 'tls-handshake';
      socket.once('secureConnect', () => {
        tlsAtSecureConnect = tlsMetadataFromSocket(socket);
        tlsStage = 'http-response';
      });
    });
    request.on('timeout', () => request.destroy(new Error('connection timeout')));
    request.on('error', (error) => {
      error.tlsStage = tlsStage; error.tlsMetadata = tlsAtSecureConnect; reject(error);
    });
    networkRequests = 1;
    request.end(xml);
  });
}

async function main() {
  if (process.env.AT_LIVE_TEST !== '1') {
    return fail('LIVE_TEST_DISABLED', 'Explicit opt-in is required');
  }
  if (required.some((key) => !process.env[key])) {
    return fail('AUTH_CONFIGURATION_MISSING', 'Required local configuration is missing');
  }
  const username = validateAtUsername(process.env.AT_USERNAME);
  const pfxPreflight = inspectPfxReadiness({ pfxPath: process.env.AT_CLIENT_PFX_PATH,
    pfxPassword: process.env.AT_CLIENT_PFX_PASSWORD });
  if (pfxPreflight.classification !== PfxPreflightClassification.READY) {
    return fail(pfxPreflight.classification, 'Local PFX preflight did not pass');
  }
  inspectAtCipherPublicKey(process.env.AT_CIPHER_CERT_PATH);
  const channel = resolveFactIntWsChannelFromEnvironment(process.env).channel;
  const localReadiness = buildFactIntWsLiveReadinessMatrix({ ntpReady: false,
    pfxReady: true, tlsDiagnosticReady: true, channelReady: true });
  if (Object.entries(localReadiness).some(([name, ready]) =>
    !['NTP_READY', 'READY'].includes(name) && !ready)) {
    return fail('FACTINTWS_LIVE_NOT_READY', 'Offline gates did not pass');
  }

  let pfx; let aesKey; let responseBytes;
  try {
    const { created } = await resolveFactIntWsCreated({
      ntpTimeProvider: ntpProviderFromEnvironment(), allowSystemClockFallback: false,
    });
    pfx = readFileSync(process.env.AT_CLIENT_PFX_PATH);
    aesKey = randomBytes(16);
    const credentials = buildFactIntWsSecurityMaterial({ aesKey, created,
      password: process.env.AT_PASSWORD,
      rsaPublicKey: readAtPublicKey(process.env.AT_CIPHER_CERT_PATH) });
    const xml = buildFactIntWsEnvelope({ username, credentials,
      input: { nif: username.split('/')[0], year: created.slice(0, 4), channel } });
    const response = await sendFramingRequest({ xml, pfx,
      passphrase: process.env.AT_CLIENT_PFX_PASSWORD });
    responseBytes = response.bytes;
    const analysis = analyzeHttpResponseFraming({ bytes: response.bytes,
      headers: response.headers, httpStatus: response.httpStatus });
    let parserSuccess = null; let parserError = null;
    if (analysis.soap11EnvelopeDetected) {
      try {
        parseFactIntWsResponse(analysis.decodedText, FACTINTWS_OPERATION);
        parserSuccess = true;
      } catch (error) {
        parserSuccess = false;
        parserError = { code: error.code ?? 'PARSING_ERROR', field: error.field ?? null,
          expectedType: error.expectedType ?? null };
      }
    }
    const framing = sanitizedFramingMetadata(analysis);
    const classification = analysis.soap11EnvelopeDetected
      ? (parserSuccess ? 'SOAP_FRAMING_VALID' : 'SOAP_FUNCTIONAL_PARSING_ERROR')
      : analysis.htmlDetected ? 'HTML_ERROR_PAGE'
        : analysis.jsonDetected ? 'JSON_RESPONSE'
          : analysis.xmlDetected ? 'XML_NON_SOAP_WRAPPER'
            : analysis.binaryOrCompressed ? 'COMPRESSED_BYTES' : 'UNKNOWN_FRAMING';
    output({ networkRequests, retries: 0, soapActionRequest: response.soapAction,
      ...framing, parserSuccess, parserError, classification });
  } finally {
    aesKey?.fill(0); pfx?.fill(0); responseBytes?.fill(0);
  }
}

main().catch((error) => {
  output({ networkRequests, retries: 0, classification: 'FRAMING_DIAGNOSTIC_INCOMPLETE',
    errorClassification: error.code ?? 'UNKNOWN_RESPONSE',
    ...tlsFailureDiagnostic(error, error.tlsStage || 'runtime') });
  process.exitCode = 2;
});
