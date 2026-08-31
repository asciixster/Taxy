#!/usr/bin/env node
import https from 'node:https';
import { randomBytes } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { validateAtUsername } from '../src/auth.mjs';
import { inspectAtCipherPublicKey, readAtPublicKey } from '../src/crypto.mjs';
import { buildFactIntWsEnvelope, buildFactIntWsLiveReadinessMatrix,
  buildFactIntWsSecurityMaterial, FACTINTWS_ENDPOINT_8443,
  FactIntWsOperation, factIntWsHttpContract, factIntWsTlsOptions,
  resolveFactIntWsChannelFromEnvironment } from '../src/factintws.mjs';
import { buildFactIntWsLiveMetadata } from '../src/factintws_live_metadata.mjs';
import { factIntInvoiceFieldPresence, parseFactIntWsResponse,
  toAtInvoiceDomain } from '../src/factintws_parser.mjs';
import { resolveFactIntWsCreated } from '../src/factintws_time.mjs';
import { ntpProviderFromEnvironment } from '../src/ntp.mjs';
import { redact } from '../src/redaction.mjs';
import { analyzeHttpResponseFraming } from '../src/response_framing.mjs';
import { inspectPfxReadiness, PfxPreflightClassification,
  tlsFailureDiagnostic } from '../src/tls_preflight.mjs';
import { tlsMetadataFromSocket } from '../src/transport.mjs';

const required = ['AT_USERNAME', 'AT_PASSWORD', 'AT_CIPHER_CERT_PATH',
  'AT_CLIENT_PFX_PATH', 'AT_CLIENT_PFX_PASSWORD'];
const maximumRequests = 2;
let networkRequests = 0;
const attempts = [];

function output(value) {
  process.stdout.write(`${JSON.stringify(redact(value), null, 2)}\n`);
}

function safeFault(fault) {
  return fault == null ? null : redact({ code: fault.code ?? null,
    reason: fault.reason ?? null });
}

function sendOnce({ xml, pfx, passphrase, contract }) {
  if (networkRequests >= maximumRequests) throw new Error('FactIntWS request budget exhausted');
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
        secureConnectReached: tlsAtSecureConnect != null,
        bytes: Buffer.concat(chunks) }));
    });
    request.on('socket', (socket) => {
      tlsStage = 'tls-handshake';
      socket.once('secureConnect', () => {
        tlsAtSecureConnect = tlsMetadataFromSocket(socket); tlsStage = 'http-response';
      });
    });
    request.on('timeout', () => request.destroy(new Error('connection timeout')));
    request.on('error', (error) => {
      error.tlsStage = tlsStage; error.tlsMetadata = tlsAtSecureConnect; reject(error);
    });
    networkRequests += 1;
    request.end(xml);
  });
}

async function executeReadOnly({ operation, input, hypothesis, pfx, pfxPreflight,
  cipherCertificate, rsaPublicKey, username }) {
  let aesKey; let responseBytes;
  try {
    const { created, source: createdSource } = await resolveFactIntWsCreated({
      ntpTimeProvider: ntpProviderFromEnvironment(), allowSystemClockFallback: false,
    });
    aesKey = randomBytes(16);
    const credentials = buildFactIntWsSecurityMaterial({ aesKey, created,
      password: process.env.AT_PASSWORD, rsaPublicKey });
    const xml = buildFactIntWsEnvelope({ username, credentials, operation, input });
    const baseContract = factIntWsHttpContract(operation, FACTINTWS_ENDPOINT_8443);
    const contract = Object.freeze({ ...baseContract,
      headers: Object.freeze({ ...baseContract.headers,
        'Content-Length': Buffer.byteLength(xml, 'utf8') }) });
    const metadata = buildFactIntWsLiveMetadata({ cipherCertificate,
      clientCertificateFingerprint: pfxPreflight.clientCertificateFingerprint,
      endpoint: FACTINTWS_ENDPOINT_8443, tlsOptions: factIntWsTlsOptions(),
      contract, xml });
    output({ phase: 'BEFORE_REQUEST', requestNumber: networkRequests + 1,
      hypothesis, singleVariable: operation === FactIntWsOperation.BY_SECTOR
        ? 'OFFICIAL_EMPTY_CODSETOR_ALL_SECTOR_QUERY'
        : 'DIAGNOSTIC_OVERRIDE_READONLY_PENDING_QUERY',
      operation, createdSource, reproducibilityMetadata: metadata });

    const response = await sendOnce({ xml, pfx,
      passphrase: process.env.AT_CLIENT_PFX_PASSWORD, contract });
    responseBytes = response.bytes;
    const framing = analyzeHttpResponseFraming({ bytes: response.bytes,
      headers: response.headers, httpStatus: response.httpStatus });
    let parsed = null; let parserError = null;
    if (framing.soap11EnvelopeDetected) {
      try { parsed = parseFactIntWsResponse(framing.decodedText, operation); }
      catch (error) { parserError = { code: error.code ?? 'PARSING_ERROR',
        field: error.field ?? null, expectedType: error.expectedType ?? null,
        failedIndex: error.failedIndex ?? null }; }
    }
    const invoices = parsed?.invoices ?? [];
    const domainInvoices = parserError ? [] : invoices.map((invoice) => toAtInvoiceDomain(invoice));
    const attempt = Object.freeze({ hypothesis, operation,
      httpStatus: response.httpStatus,
      secureConnectReached: response.secureConnectReached,
      authorized: response.tlsAtSecureConnect?.authorized ?? response.tls.authorized,
      tlsVersion: response.tlsAtSecureConnect?.protocol ?? response.tls.protocol,
      soapResponse: framing.soap11EnvelopeDetected,
      soapFault: safeFault(parsed?.fault),
      estadoOperacao: parsed?.result?.estadoOperacao ?? null,
      desc: parsed?.result?.desc ?? null,
      invoiceCount: invoices.length,
      parsedInvoiceCount: domainInvoices.length,
      parserError,
      countIntegrity: parserError == null && invoices.length === domainInvoices.length,
      fieldPresence: invoices.map((invoice, invoiceIndex) => ({ invoiceIndex,
        fields: factIntInvoiceFieldPresence(invoice) })),
    });
    attempts.push(attempt);
    output({ phase: 'AFTER_REQUEST', requestNumber: networkRequests, ...attempt });
    return attempt;
  } finally {
    aesKey?.fill(0); responseBytes?.fill(0);
  }
}

async function main() {
  if (process.env.AT_LIVE_TEST !== '1') throw new Error('Explicit live opt-in is required');
  if (required.some((key) => !process.env[key])) throw new Error('Required local configuration is missing');
  const username = validateAtUsername(process.env.AT_USERNAME);
  const pfxPreflight = inspectPfxReadiness({ pfxPath: process.env.AT_CLIENT_PFX_PATH,
    pfxPassword: process.env.AT_CLIENT_PFX_PASSWORD });
  if (pfxPreflight.classification !== PfxPreflightClassification.READY) {
    throw new Error('Local PFX preflight did not pass');
  }
  const cipherCertificate = inspectAtCipherPublicKey(process.env.AT_CIPHER_CERT_PATH);
  const rsaPublicKey = readAtPublicKey(process.env.AT_CIPHER_CERT_PATH);
  const channel = resolveFactIntWsChannelFromEnvironment(process.env).channel;
  const readiness = buildFactIntWsLiveReadinessMatrix({ ntpReady: true,
    pfxReady: true, tlsDiagnosticReady: true, channelReady: true });
  if (!readiness.READY) throw new Error('FactIntWS live readiness gate did not pass');
  let pfx;
  try {
    pfx = readFileSync(process.env.AT_CLIENT_PFX_PATH);
    const common = { nif: username.split('/')[0], year: '2026', channel };
    const allSector = await executeReadOnly({
      operation: FactIntWsOperation.BY_SECTOR,
      input: { ...common, sector: '', index: '0' },
      hypothesis: 'ECRAINICIAL_AGGREGATE_MISMATCH', pfx, pfxPreflight,
      cipherCertificate, rsaPublicKey, username,
    });
    if (allSector.invoiceCount === 0 && allSector.parserError == null) {
      await executeReadOnly({
        operation: FactIntWsOperation.PENDING, input: common,
        hypothesis: 'DIAGNOSTIC_OVERRIDE_READONLY_ACCOUNT_POPULATION_CONTEXT',
        pfx, pfxPreflight, cipherCertificate, rsaPublicKey, username,
      });
    }
    const real = attempts.find((attempt) => attempt.invoiceCount > 0);
    const controlled = attempts.every((attempt) => attempt.httpStatus === 200
      && attempt.soapResponse && attempt.soapFault == null && attempt.parserError == null);
    output({ phase: 'FINAL', networkRequests, retries: 0,
      allSectorRequestExecuted: attempts.some((attempt) => attempt.operation === FactIntWsOperation.BY_SECTOR),
      allSectorInvoiceCount: attempts.find((attempt) => attempt.operation === FactIntWsOperation.BY_SECTOR)?.invoiceCount ?? null,
      diagnosticPendingExecuted: attempts.some((attempt) => attempt.operation === FactIntWsOperation.PENDING),
      pendingInvoiceCount: attempts.find((attempt) => attempt.operation === FactIntWsOperation.PENDING)?.invoiceCount ?? null,
      realInvoiceResponseObserved: real != null,
      realInvoiceParsingConfirmed: real?.countIntegrity === true,
      classification: real ? 'REAL_INVOICE_OBSERVED'
        : controlled ? 'ACCOUNT_POPULATION_CONTEXT_MISMATCH_REINFORCED'
          : 'POPULATION_DIAGNOSTIC_INCOMPLETE' });
  } finally { pfx?.fill(0); }
}

main().catch((error) => {
  output({ phase: 'FINAL', networkRequests, retries: 0,
    classification: 'POPULATION_DIAGNOSTIC_INCOMPLETE',
    errorClassification: error.code ?? 'UNKNOWN_RESPONSE',
    ...tlsFailureDiagnostic(error, error.tlsStage || 'runtime') });
  process.exitCode = 2;
});
