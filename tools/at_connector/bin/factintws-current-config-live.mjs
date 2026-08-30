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
import { buildFactIntWsLiveMetadata } from '../src/factintws_live_metadata.mjs';
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
let reproducibilityMetadata = null;

function output(value) {
  process.stdout.write(`${JSON.stringify(value, null, 2)}\n`);
}

function safeFault(fault) {
  return fault == null ? null : redact({ code: fault.code ?? null, reason: fault.reason ?? null });
}

function fail(classification, message) {
  output({ reproducibilityMetadata, networkRequests, retries: 0,
    classification, message: redact(message) });
  process.exitCode = 2;
}

function sendOnce({ xml, pfx, passphrase, contract }) {
  return new Promise((resolve, reject) => {
    let tlsStage = 'socket-creation'; let tlsAtSecureConnect = null;
    const request = https.request(contract.endpoint, {
      method: contract.method, pfx, passphrase, rejectUnauthorized: true,
      ...factIntWsTlsOptions(), headers: contract.headers, timeout: 20_000,
    }, (response) => {
      const tls = tlsMetadataFromSocket(response.socket); const chunks = [];
      response.on('data', (chunk) => chunks.push(chunk));
      response.on('end', () => resolve({ httpStatus: response.statusCode ?? null,
        headers: response.headers, tls, tlsAtSecureConnect,
        secureConnectReached: tlsAtSecureConnect != null, bytes: Buffer.concat(chunks) }));
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
  if (process.env.AT_LIVE_TEST !== '1') return fail('LIVE_TEST_DISABLED', 'Explicit opt-in is required');
  if (required.some((key) => !process.env[key])) {
    return fail('AUTH_CONFIGURATION_MISSING', 'Required local configuration is missing');
  }
  const username = validateAtUsername(process.env.AT_USERNAME);
  const pfxPreflight = inspectPfxReadiness({ pfxPath: process.env.AT_CLIENT_PFX_PATH,
    pfxPassword: process.env.AT_CLIENT_PFX_PASSWORD });
  if (pfxPreflight.classification !== PfxPreflightClassification.READY) {
    return fail(pfxPreflight.classification, 'Local PFX preflight did not pass');
  }
  const cipherCertificate = inspectAtCipherPublicKey(process.env.AT_CIPHER_CERT_PATH);
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
      input: { nif: username.split('/')[0], year: '2026', channel } });
    const baseContract = factIntWsHttpContract(FACTINTWS_OPERATION, FACTINTWS_ENDPOINT_8443);
    const contract = Object.freeze({ ...baseContract,
      headers: Object.freeze({ ...baseContract.headers,
        'Content-Length': Buffer.byteLength(xml, 'utf8') }) });
    reproducibilityMetadata = buildFactIntWsLiveMetadata({ cipherCertificate,
      clientCertificateFingerprint: pfxPreflight.clientCertificateFingerprint,
      endpoint: FACTINTWS_ENDPOINT_8443, tlsOptions: factIntWsTlsOptions(),
      contract, xml });

    // The complete sanitized reproducibility record exists before networkRequests changes.
    const response = await sendOnce({ xml, pfx,
      passphrase: process.env.AT_CLIENT_PFX_PASSWORD, contract });
    responseBytes = response.bytes;
    const analysis = analyzeHttpResponseFraming({ bytes: response.bytes,
      headers: response.headers, httpStatus: response.httpStatus });
    let parsed = null; let parserError = null;
    if (analysis.soap11EnvelopeDetected) {
      try { parsed = parseFactIntWsResponse(analysis.decodedText, FACTINTWS_OPERATION); }
      catch (error) { parserError = { code: error.code ?? 'PARSING_ERROR',
        field: error.field ?? null, expectedType: error.expectedType ?? null }; }
    }
    const responseClassification = analysis.soap11EnvelopeDetected ? 'SOAP_XML'
      : analysis.htmlDetected ? 'HTML'
        : analysis.jsonDetected ? 'JSON'
          : analysis.xmlDetected ? 'NON_SOAP_XML'
            : analysis.decodedBinary ? 'BINARY_OR_UNKNOWN' : 'NON_XML';
    const totals = parsed?.totals ?? null;
    const nonZeroSectorCount = (parsed?.sectors ?? []).filter((sector) => [
      sector.provisionalBenefitCents, sector.totalExpensesCents,
      sector.totalVatExpensesCents,
    ].some((value) => value != null && value !== 0)).length;
    const functional = response.httpStatus === 200 && parsed?.fault == null && parsed?.result != null;
    const populationMismatchRemains = functional && totals != null
      && totals.pendingValidation === 0 && totals.provisionalBenefitCents === 0
      && nonZeroSectorCount === 0;
    const http500Reproduced = response.httpStatus === 500 && !analysis.soap11EnvelopeDetected;
    const framing = sanitizedFramingMetadata(analysis);
    output({ reproducibilityMetadata, networkRequests, retries: 0,
      secureConnectReached: response.secureConnectReached,
      authorized: response.tlsAtSecureConnect?.authorized ?? response.tls.authorized,
      tlsVersion: response.tlsAtSecureConnect?.protocol ?? response.tls.protocol,
      cipher: response.tlsAtSecureConnect?.cipher ?? response.tls.cipher,
      httpStatus: response.httpStatus, contentType: framing.contentType,
      contentEncoding: framing.contentEncoding,
      transferEncoding: framing.transferEncoding,
      responseByteLength: framing.responseByteLength,
      responseClassification, soapResponse: analysis.soap11EnvelopeDetected,
      soapFault: safeFault(parsed?.fault), parserError,
      estadoOperacao: parsed?.result?.estadoOperacao ?? null,
      pendingCount: totals?.pendingValidation ?? null,
      provisionalBenefitCents: totals?.provisionalBenefitCents ?? null,
      nonZeroSectorCount: totals ? nonZeroSectorCount : null,
      currentConfigFunctional: functional,
      populationMismatchRemains,
      currentConfigReproducesHttp500: http500Reproduced,
      classification: functional ? 'ECRAINICIAL_CURRENT_CONFIG_FUNCTIONAL'
        : http500Reproduced ? 'CURRENT_CONFIG_REPRODUCES_HTTP_500'
          : parsed?.fault ? 'SOAP_FAULT' : parserError ? 'PARSING_ERROR' : 'UNKNOWN_RESPONSE' });
    if (!functional) process.exitCode = 2;
  } finally { aesKey?.fill(0); pfx?.fill(0); responseBytes?.fill(0); }
}

main().catch((error) => {
  output({ reproducibilityMetadata, networkRequests, retries: 0,
    classification: 'CURRENT_CONFIG_LIVE_INCOMPLETE',
    errorClassification: error.code ?? 'UNKNOWN_RESPONSE',
    ...tlsFailureDiagnostic(error, error.tlsStage || 'runtime') });
  process.exitCode = 2;
});
