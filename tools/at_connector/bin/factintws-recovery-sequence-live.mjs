#!/usr/bin/env node
import https from 'node:https';
import { randomBytes } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { validateAtUsername } from '../src/auth.mjs';
import { inspectAtCipherPublicKey, readAtPublicKey } from '../src/crypto.mjs';
import { buildFactIntWsEnvelope, buildFactIntWsSecurityMaterial,
  FACTINTWS_ENDPOINT_8443, factIntWsHttpContract, factIntWsTlsOptions,
  FactIntWsOperation, resolveFactIntWsChannelFromEnvironment } from '../src/factintws.mjs';
import { buildFactIntWsLiveMetadata } from '../src/factintws_live_metadata.mjs';
import { parseFactIntWsResponse } from '../src/factintws_parser.mjs';
import { resolveFactIntWsCreated } from '../src/factintws_time.mjs';
import { ntpProviderFromEnvironment } from '../src/ntp.mjs';
import { analyzeHttpResponseFraming, sanitizedFramingMetadata } from '../src/response_framing.mjs';
import { inspectPfxReadiness, PfxPreflightClassification } from '../src/tls_preflight.mjs';
import { tlsMetadataFromSocket } from '../src/transport.mjs';

const required = ['AT_USERNAME', 'AT_PASSWORD', 'AT_CIPHER_CERT_PATH',
  'AT_CLIENT_PFX_PATH', 'AT_CLIENT_PFX_PASSWORD'];
let networkRequests = 0;
const output = (value) => process.stdout.write(`${JSON.stringify(value, null, 2)}\n`);

function responseShape(analysis) {
  if (analysis.soap11EnvelopeDetected) return 'SOAP_XML';
  if (analysis.htmlDetected) return 'HTML';
  if (analysis.jsonDetected) return 'JSON';
  if (analysis.xmlDetected) return 'NON_SOAP_XML';
  return analysis.decodedBinary ? 'BINARY_OR_UNKNOWN' : 'NON_XML';
}

function send({ agent, contract, xml, pfx, passphrase }) {
  return new Promise((resolve, reject) => {
    let secure = null;
    const request = https.request(contract.endpoint, { method: contract.method, agent,
      pfx, passphrase, rejectUnauthorized: true, ...factIntWsTlsOptions(),
      headers: contract.headers, timeout: 20_000 }, (response) => {
      const chunks = [];
      response.on('data', (chunk) => chunks.push(chunk));
      response.on('end', () => resolve({ status: response.statusCode ?? null,
        headers: response.headers, bytes: Buffer.concat(chunks),
        tls: secure ?? tlsMetadataFromSocket(response.socket) }));
    });
    request.on('socket', (socket) => {
      if (socket.encrypted && !socket.connecting) secure = tlsMetadataFromSocket(socket);
      else socket.once('secureConnect', () => { secure = tlsMetadataFromSocket(socket); });
    });
    request.on('timeout', () => request.destroy(new Error('connection timeout')));
    request.on('error', reject);
    networkRequests += 1;
    request.end(xml);
  });
}

async function main() {
  if (process.env.AT_LIVE_TEST !== '1' || required.some((key) => !process.env[key])) {
    output({ networkRequests, classification: 'LIVE_CONFIGURATION_MISSING' });
    process.exitCode = 2; return;
  }
  const username = validateAtUsername(process.env.AT_USERNAME);
  const nif = username.split('/')[0];
  const preflight = inspectPfxReadiness({ pfxPath: process.env.AT_CLIENT_PFX_PATH,
    pfxPassword: process.env.AT_CLIENT_PFX_PASSWORD });
  if (preflight.classification !== PfxPreflightClassification.READY) {
    output({ networkRequests, classification: preflight.classification });
    process.exitCode = 2; return;
  }
  const cipherCertificate = inspectAtCipherPublicKey(process.env.AT_CIPHER_CERT_PATH);
  const rsaPublicKey = readAtPublicKey(process.env.AT_CIPHER_CERT_PATH);
  const channel = resolveFactIntWsChannelFromEnvironment(process.env).channel;
  const pfx = readFileSync(process.env.AT_CLIENT_PFX_PATH);
  const agent = new https.Agent({ keepAlive: true, maxSockets: 1 });
  const keys = []; const responseBuffers = [];
  const phases = [
    { operation: FactIntWsOperation.ECRAINICIAL, phase: 'authentication', year: '2026' },
    { operation: FactIntWsOperation.TAXPAYER, phase: 'taxpayer' },
    { operation: FactIntWsOperation.ECRAINICIAL, phase: 'final', year: '2026' },
  ];
  const results = [];
  try {
    for (const phase of phases) {
      const { created } = await resolveFactIntWsCreated({
        ntpTimeProvider: ntpProviderFromEnvironment(), allowSystemClockFallback: false,
      });
      const aesKey = randomBytes(16); keys.push(aesKey);
      const credentials = buildFactIntWsSecurityMaterial({ aesKey, created,
        password: process.env.AT_PASSWORD, rsaPublicKey });
      const input = { nif, channel, ...(phase.year ? { year: phase.year } : {}) };
      const xml = buildFactIntWsEnvelope({ username, credentials,
        operation: phase.operation, input });
      const base = factIntWsHttpContract(phase.operation, FACTINTWS_ENDPOINT_8443);
      const contract = { ...base, headers: { ...base.headers,
        'Content-Length': Buffer.byteLength(xml, 'utf8') } };
      const metadata = buildFactIntWsLiveMetadata({ cipherCertificate,
        clientCertificateFingerprint: preflight.clientCertificateFingerprint,
        endpoint: FACTINTWS_ENDPOINT_8443, tlsOptions: factIntWsTlsOptions(), contract, xml });
      const response = await send({ agent, contract, xml, pfx,
        passphrase: process.env.AT_CLIENT_PFX_PASSWORD });
      responseBuffers.push(response.bytes);
      const analysis = analyzeHttpResponseFraming({ bytes: response.bytes,
        headers: response.headers, httpStatus: response.status });
      let parsed = null; let parserError = null;
      if (analysis.soap11EnvelopeDetected) {
        try { parsed = parseFactIntWsResponse(analysis.decodedText, phase.operation); }
        catch (error) { parserError = { code: error.code ?? 'PARSING_ERROR',
          field: error.field ?? null }; }
      }
      const framing = sanitizedFramingMetadata(analysis);
      const totals = parsed?.totals ?? null;
      const nonZeroSectorCount = (parsed?.sectors ?? []).filter((sector) => [
        sector.provisionalBenefitCents, sector.totalExpensesCents,
        sector.totalVatExpensesCents,
      ].some((value) => value != null && value !== 0)).length;
      results.push({ phase: phase.phase, operation: phase.operation, metadata,
        secureConnect: response.tls.protocol != null, authorized: response.tls.authorized,
        tlsVersion: response.tls.protocol, cipher: response.tls.cipher,
        httpStatus: response.status, contentType: framing.contentType,
        contentEncoding: framing.contentEncoding, responseByteLength: framing.responseByteLength,
        responseClassification: responseShape(analysis), soap: analysis.soap11EnvelopeDetected,
        estadoOperacao: parsed?.result?.estadoOperacao ?? null, parserError,
        pendingCount: totals?.pendingValidation ?? null,
        provisionalBenefitCents: totals?.provisionalBenefitCents ?? null,
        nonZeroSectorCount: totals ? nonZeroSectorCount : null,
        setCookiePresent: response.headers['set-cookie'] != null });
    }
    const final = results.at(-1);
    const recovered = final.httpStatus === 200 && final.soap && final.parserError == null
      && final.estadoOperacao != null;
    output({ hypothesis: 'BOOTSTRAP_CALL_SEQUENCE_WITH_SHARED_HTTP_AGENT',
      networkRequests, retries: 0, results,
      classification: recovered ? 'ECRAINICIAL_TRANSPORT_RECOVERED'
        : 'BOOTSTRAP_CALL_SEQUENCE_NOT_SUFFICIENT' });
    if (!recovered) process.exitCode = 2;
  } finally {
    agent.destroy(); keys.forEach((key) => key.fill(0));
    responseBuffers.forEach((bytes) => bytes.fill(0)); pfx.fill(0);
  }
}

main().catch((error) => {
  output({ networkRequests, retries: 0, classification: 'RECOVERY_SEQUENCE_INCOMPLETE',
    errorCode: error.code ?? 'UNKNOWN_RESPONSE' });
  process.exitCode = 2;
});
