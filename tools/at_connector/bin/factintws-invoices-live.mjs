#!/usr/bin/env node
import https from 'node:https';
import { randomBytes } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { gunzipSync } from 'node:zlib';
import { validateAtUsername } from '../src/auth.mjs';
import { inspectAtCipherPublicKey, readAtPublicKey } from '../src/crypto.mjs';
import { buildFactIntWsLiveReadinessMatrix, buildFactIntWsSecurityMaterial,
  FACTINTWS_ENDPOINT_8443, factIntWsTlsOptions, FactIntWsOperation,
  resolveFactIntWsChannelFromEnvironment } from '../src/factintws.mjs';
import { FactIntWsClient, FactIntWsRepository } from '../src/factintws_client.mjs';
import { factIntInvoiceFieldPresence } from '../src/factintws_parser.mjs';
import { resolveFactIntWsCreated } from '../src/factintws_time.mjs';
import { ntpProviderFromEnvironment } from '../src/ntp.mjs';
import { redact } from '../src/redaction.mjs';
import { inspectPfxReadiness, PfxPreflightClassification, tlsFailureDiagnostic } from '../src/tls_preflight.mjs';
import { tlsMetadataFromSocket } from '../src/transport.mjs';

const required = ['AT_USERNAME', 'AT_PASSWORD', 'AT_CIPHER_CERT_PATH', 'AT_CLIENT_PFX_PATH', 'AT_CLIENT_PFX_PASSWORD'];
const requested = process.argv[2];
const operation = requested === 'pending' ? FactIntWsOperation.PENDING
  : requested === 'sector' ? FactIntWsOperation.BY_SECTOR : null;
let networkRequests = 0;
const output = (value) => process.stdout.write(`${JSON.stringify(redact(value), null, 2)}\n`);
const fail = (classification, message) => { output({ networkRequests, operation, classification, message }); process.exitCode = 2; };

function sendOnceFactory({ pfx, passphrase }) {
  return ({ contract, xml }) => new Promise((resolve, reject) => {
    let tlsStage = 'socket-creation'; let tlsAtSecureConnect = null;
    const request = https.request(contract.endpoint, { method: contract.method, pfx, passphrase,
      rejectUnauthorized: true, ...factIntWsTlsOptions(), headers: { ...contract.headers, 'Content-Length': Buffer.byteLength(xml) }, timeout: 20_000 }, (response) => {
      const tls = tlsMetadataFromSocket(response.socket); const chunks = [];
      response.on('data', (chunk) => chunks.push(chunk));
      response.on('end', () => {
        try { const bytes = Buffer.concat(chunks); const body = response.headers['content-encoding'] === 'gzip'
          ? gunzipSync(bytes).toString('utf8') : bytes.toString('utf8'); resolve({ httpStatus: response.statusCode ?? null, tls, body }); }
        catch (error) { reject(error); }
      });
    });
    request.on('socket', (socket) => { tlsStage = 'tls-handshake'; socket.once('secureConnect', () => {
      tlsAtSecureConnect = tlsMetadataFromSocket(socket); tlsStage = 'http-response';
    }); });
    request.on('timeout', () => request.destroy(new Error('connection timeout')));
    request.on('error', (error) => { error.tlsStage = tlsStage; error.tlsMetadata = tlsAtSecureConnect; reject(error); });
    networkRequests += 1; request.end(xml);
  });
}

async function main() {
  if (!operation) return fail('INVALID_OPERATION', 'Use pending or sector');
  if (process.env.AT_LIVE_TEST !== '1') return fail('LIVE_TEST_DISABLED', 'Explicit opt-in is required');
  if (required.some((key) => !process.env[key])) return fail('AUTH_CONFIGURATION_MISSING', 'Required local configuration is missing');
  const username = validateAtUsername(process.env.AT_USERNAME);
  const pfxPreflight = inspectPfxReadiness({ pfxPath: process.env.AT_CLIENT_PFX_PATH, pfxPassword: process.env.AT_CLIENT_PFX_PASSWORD });
  if (pfxPreflight.classification !== PfxPreflightClassification.READY) return fail(pfxPreflight.classification, 'Local PFX preflight did not pass');
  inspectAtCipherPublicKey(process.env.AT_CIPHER_CERT_PATH);
  const channelResolution = resolveFactIntWsChannelFromEnvironment(process.env);
  const localReadiness = buildFactIntWsLiveReadinessMatrix({ ntpReady: false, pfxReady: true, tlsDiagnosticReady: true, channelReady: true });
  if (Object.entries(localReadiness).some(([name, ready]) => !['NTP_READY', 'READY'].includes(name) && !ready)) return fail('FACTINTWS_LIVE_NOT_READY', 'Offline gates did not pass');
  let pfx; let aesKey;
  try {
    const { created, source: createdSource } = await resolveFactIntWsCreated({ ntpTimeProvider: ntpProviderFromEnvironment(), allowSystemClockFallback: false });
    if (!buildFactIntWsLiveReadinessMatrix({ ntpReady: true, pfxReady: true, tlsDiagnosticReady: true, channelReady: true }).READY) return fail('FACTINTWS_LIVE_NOT_READY', 'Final gates did not pass');
    pfx = readFileSync(process.env.AT_CLIENT_PFX_PATH); aesKey = randomBytes(16);
    const credentials = buildFactIntWsSecurityMaterial({ aesKey, created, password: process.env.AT_PASSWORD, rsaPublicKey: readAtPublicKey(process.env.AT_CIPHER_CERT_PATH) });
    const common = { username, credentials, input: { nif: username.split('/')[0], year: process.env.FACTINTWS_YEAR ?? created.slice(0, 4), channel: channelResolution.channel } };
    const client = new FactIntWsClient({ endpoint: FACTINTWS_ENDPOINT_8443, transport: sendOnceFactory({ pfx, passphrase: process.env.AT_CLIENT_PFX_PASSWORD }) });
    const repository = new FactIntWsRepository(client);
    const result = operation === FactIntWsOperation.PENDING
      ? await repository.pendingInvoices(common)
      : await repository.invoicesBySector({ ...common, input: { ...common.input, sector: process.env.FACTINTWS_SECTOR_CODE, index: '0' } });
    const parsed = result.parsed;
    output({ networkRequests, operation, createdSource, httpStatus: result.httpStatus,
      mTLS: result.tls.authorized ? 'SUCCESS' : 'FAILED', authorized: result.tls.authorized,
      soapFault: parsed.fault ?? null, estadoOperacao: parsed.result?.estadoOperacao ?? null,
      desc: parsed.result?.desc ?? null, invoiceCount: parsed.invoices?.length ?? 0,
      parsedInvoiceCount: result.domainInvoices?.length ?? 0, totalPages: parsed.totalPages,
      pageIndex: parsed.index, paginationRuntimeObserved: parsed.totalPages != null,
      invoiceFieldPresence: (parsed.invoices ?? []).map((invoice, invoiceIndex) => ({ invoiceIndex, fields: factIntInvoiceFieldPresence(invoice) })),
      classification: result.classification });
    if (parsed.fault) process.exitCode = 2;
  } finally { aesKey?.fill(0); pfx?.fill(0); }
}

main().catch((error) => {
  const diagnostic = tlsFailureDiagnostic(error, error.tlsStage || 'runtime');
  output({ networkRequests, operation, classification: error.code ?? 'UNKNOWN_RESPONSE',
    authorized: error.tlsMetadata?.authorized ?? null, tlsVersion: error.tlsMetadata?.protocol ?? null,
    field: error.field ?? null, expectedType: error.expectedType ?? null,
    failedIndex: error.failedIndex ?? null, ...diagnostic });
  process.exitCode = 2;
});
