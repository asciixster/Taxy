#!/usr/bin/env node
import https from 'node:https';
import { randomBytes } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { gunzipSync } from 'node:zlib';
import { validateAtUsername } from '../src/auth.mjs';
import { inspectAtCipherPublicKey, readAtPublicKey } from '../src/crypto.mjs';
import {
  buildFactIntWsEnvelope, buildFactIntWsLiveReadinessMatrix, buildFactIntWsSecurityMaterial,
  resolveFactIntWsChannelFromEnvironment,
  FACTINTWS_ENDPOINT_8443, FACTINTWS_OPERATION, factIntWsHttpContract, factIntWsTlsOptions,
} from '../src/factintws.mjs';
import { parseFactIntWsResponse } from '../src/factintws_parser.mjs';
import { redact } from '../src/redaction.mjs';
import { tlsMetadataFromSocket } from '../src/transport.mjs';
import { resolveFactIntWsCreated } from '../src/factintws_time.mjs';
import { ntpProviderFromEnvironment } from '../src/ntp.mjs';
import { inspectPfxReadiness, PfxPreflightClassification, tlsFailureDiagnostic } from '../src/tls_preflight.mjs';

const required = ['AT_USERNAME', 'AT_PASSWORD', 'AT_CIPHER_CERT_PATH', 'AT_CLIENT_PFX_PATH', 'AT_CLIENT_PFX_PASSWORD'];
let networkRequests = 0;

function output(value) {
  process.stdout.write(`${JSON.stringify(redact(value), null, 2)}\n`);
}

function fail(code, message) {
  output({ networkRequests, classification: code, message });
  process.exitCode = 2;
}

function classifyFault(fault) {
  const text = `${fault?.code || ''} ${fault?.reason || ''}`;
  if (/auth|credential|password|username|utilizador/i.test(text)) return 'AUTH_ERROR';
  if (/authoriz|permiss|forbidden|acesso/i.test(text)) return 'AUTHORIZATION_ERROR';
  return 'REMOTE_FAULT';
}

function sendOnce({ xml, pfx, passphrase }) {
  const contract = factIntWsHttpContract(FACTINTWS_OPERATION, FACTINTWS_ENDPOINT_8443);
  return new Promise((resolve, reject) => {
    let tlsStage = 'socket-creation';
    let tlsAtSecureConnect = null;
    const request = https.request(contract.endpoint, {
      method: contract.method,
      pfx,
      passphrase,
      rejectUnauthorized: true,
      ...factIntWsTlsOptions(),
      headers: { ...contract.headers, 'Content-Length': Buffer.byteLength(xml) },
      timeout: 20_000,
    }, (response) => {
      const tls = tlsMetadataFromSocket(response.socket);
      const chunks = [];
      response.on('data', (chunk) => chunks.push(chunk));
      response.on('end', () => {
        try {
          const bytes = Buffer.concat(chunks);
          const body = response.headers['content-encoding'] === 'gzip' ? gunzipSync(bytes).toString('utf8') : bytes.toString('utf8');
          resolve({ httpStatus: response.statusCode ?? null, tls, body });
        } catch (error) { reject(error); }
      });
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
      error.tlsStage = tlsStage;
      error.tlsMetadata = tlsAtSecureConnect;
      reject(error);
    });
    request.end(xml);
  });
}

async function main() {
  if (process.env.AT_LIVE_TEST !== '1') return fail('LIVE_TEST_DISABLED', 'Explicit opt-in is required');
  if (required.some((key) => !process.env[key])) return fail('AUTH_CONFIGURATION_MISSING', 'Required local configuration is missing');
  const username = validateAtUsername(process.env.AT_USERNAME);
  const pfxPreflight = inspectPfxReadiness({ pfxPath: process.env.AT_CLIENT_PFX_PATH,
    pfxPassword: process.env.AT_CLIENT_PFX_PASSWORD });
  if (pfxPreflight.classification !== PfxPreflightClassification.READY) {
    return fail(pfxPreflight.classification, 'Local PFX preflight did not pass');
  }
  inspectAtCipherPublicKey(process.env.AT_CIPHER_CERT_PATH);
  const channelResolution = resolveFactIntWsChannelFromEnvironment(process.env);
  // All non-time gates pass before the one permitted NTP exchange.
  const localReadiness = buildFactIntWsLiveReadinessMatrix({ ntpReady: false,
    pfxReady: true, tlsDiagnosticReady: true, channelReady: true });
  const localBlockers = Object.entries(localReadiness)
    .filter(([name, ready]) => name !== 'NTP_READY' && name !== 'READY' && !ready)
    .map(([name]) => name);
  if (localBlockers.length) return fail('FACTINTWS_CHANNEL_VALUES_UNKNOWN',
    `FactIntWS local live gates are not ready: ${localBlockers.join(', ')}`);
  let pfx;
  let aesKey;
  try {
    const ntpTimeProvider = ntpProviderFromEnvironment();
    const { created, source: createdSource } = await resolveFactIntWsCreated({
      ntpTimeProvider, allowSystemClockFallback: false,
    });
    const finalReadiness = buildFactIntWsLiveReadinessMatrix({ ntpReady: true,
      pfxReady: true, tlsDiagnosticReady: true, channelReady: true });
    if (!finalReadiness.READY) return fail('FACTINTWS_LIVE_NOT_READY', 'FactIntWS live readiness matrix did not pass');
    pfx = readFileSync(process.env.AT_CLIENT_PFX_PATH);
    aesKey = randomBytes(16);
    const channel = channelResolution.channel;
    const credentials = buildFactIntWsSecurityMaterial({
      aesKey, created, password: process.env.AT_PASSWORD,
      rsaPublicKey: readAtPublicKey(process.env.AT_CIPHER_CERT_PATH),
    });
    const xml = buildFactIntWsEnvelope({ username, credentials,
      input: { nif: username.split('/')[0], year: created.slice(0, 4), channel } });
    networkRequests = 1;
    const response = await sendOnce({ xml, pfx, passphrase: process.env.AT_CLIENT_PFX_PASSWORD });
    let parsed;
    try { parsed = parseFactIntWsResponse(response.body, FACTINTWS_OPERATION); }
    catch (error) {
      output({ networkRequests, mTLS: response.tls.authorized ? 'SUCCESS' : 'FAILED', authorized: response.tls.authorized,
        httpStatus: response.httpStatus, soapResponse: /^\s*(?:<\?xml[^>]*>\s*)?</.test(response.body) ? 'YES' : 'NO',
        classification: 'PARSING_ERROR', parsingError: error.message });
      process.exitCode = 2; return;
    }
    const classification = parsed.fault ? classifyFault(parsed.fault)
      : 'FACTINTWS_8443_TLS_RUNTIME_CONFIRMED';
    output({ networkRequests, operation: FACTINTWS_OPERATION, createdSource,
      channelValueStatus: channelResolution.status,
      mTLS: response.tls.authorized ? 'SUCCESS' : 'FAILED', authorized: response.tls.authorized,
      authorizationError: response.tls.authorizationError, tlsVersion: response.tls.protocol,
      cipher: response.tls.cipher, cipherVersion: response.tls.cipherVersion,
      alpnProtocol: response.tls.alpnProtocol, servername: response.tls.servername,
      httpStatus: response.httpStatus, soapResponse: 'YES',
      soapFault: parsed.fault || null, estadoOperacao: parsed.result?.estadoOperacao ?? null,
      desc: parsed.result?.desc ?? null, operationResponseDetected: !parsed.fault,
      aggregateFieldPresence: parsed.totals ? Object.fromEntries(Object.entries(parsed.totals).map(([key, value]) => [key, value != null])) : {},
      classification });
    if (parsed.fault) process.exitCode = 2;
  } finally {
    aesKey?.fill(0);
    pfx?.fill(0);
  }
}

main().catch((error) => {
  if (error.code === 'NTP_TIME_UNAVAILABLE' || error.code === 'FACTINTWS_CHANNEL_VALUES_UNKNOWN') {
    output({ networkRequests, classification: error.code, message: error.message });
    process.exitCode = 2; return;
  }
  const identityRejected = /certificate required|bad certificate|certificate unknown/i.test(error.message);
  const tlsError = identityRejected || /ssl|tls|handshake|bad record mac/i.test(error.message);
  const tls12BadRecordMac = error.code === 'ERR_SSL_DECRYPTION_FAILED_OR_BAD_RECORD_MAC';
  const diagnostic = tlsFailureDiagnostic(error, error.tlsStage || 'handshake');
  output({ networkRequests, classification: tls12BadRecordMac
    ? 'TLS12_DID_NOT_RESOLVE_BAD_RECORD_MAC'
    : (identityRejected ? 'FACTINTWS_TLS_IDENTITY_NOT_ACCEPTED' : (tlsError ? 'TLS_ERROR' : 'UNKNOWN')),
    secureConnectReached: error.tlsMetadata != null,
    authorized: error.tlsMetadata?.authorized ?? null,
    authorizationError: error.tlsMetadata?.authorizationError ?? null,
    tlsVersion: error.tlsMetadata?.protocol ?? null,
    cipher: error.tlsMetadata?.cipher ?? null,
    cipherVersion: error.tlsMetadata?.cipherVersion ?? null,
    alpnProtocol: error.tlsMetadata?.alpnProtocol ?? null,
    servername: error.tlsMetadata?.servername ?? null,
    ...diagnostic });
  process.exitCode = 2;
});
