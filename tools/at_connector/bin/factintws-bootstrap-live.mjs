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
import { FactIntWsClient, FactIntWsRepository,
  runFactIntWsBootstrapSequence } from '../src/factintws_client.mjs';
import { resolveFactIntWsCreated } from '../src/factintws_time.mjs';
import { ntpProviderFromEnvironment } from '../src/ntp.mjs';
import { redact } from '../src/redaction.mjs';
import { inspectPfxReadiness, PfxPreflightClassification,
  tlsFailureDiagnostic } from '../src/tls_preflight.mjs';
import { tlsMetadataFromSocket } from '../src/transport.mjs';

const required = ['AT_USERNAME', 'AT_PASSWORD', 'AT_CIPHER_CERT_PATH',
  'AT_CLIENT_PFX_PATH', 'AT_CLIENT_PFX_PASSWORD'];
let networkRequests = 0;
const output = (value) => process.stdout.write(`${JSON.stringify(redact(value), null, 2)}\n`);
const fail = (classification, message) => {
  output({ networkRequests, classification, message });
  process.exitCode = 2;
};

function sendOnceFactory({ pfx, passphrase }) {
  return ({ contract, xml }) => new Promise((resolve, reject) => {
    let tlsStage = 'socket-creation'; let tlsAtSecureConnect = null;
    const request = https.request(contract.endpoint, {
      method: contract.method, pfx, passphrase, rejectUnauthorized: true,
      ...factIntWsTlsOptions(),
      headers: { ...contract.headers, 'Content-Length': Buffer.byteLength(xml) },
      timeout: 20_000,
    }, (response) => {
      const tls = tlsMetadataFromSocket(response.socket); const chunks = [];
      response.on('data', (chunk) => chunks.push(chunk));
      response.on('end', () => {
        try {
          const bytes = Buffer.concat(chunks);
          const body = response.headers['content-encoding'] === 'gzip'
            ? gunzipSync(bytes).toString('utf8') : bytes.toString('utf8');
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
      error.tlsStage = tlsStage; error.tlsMetadata = tlsAtSecureConnect; reject(error);
    });
    networkRequests += 1;
    request.end(xml);
  });
}

function operationSummary(result) {
  if (!result) return null;
  return Object.freeze({ httpStatus: result.httpStatus,
    estadoOperacao: result.parsed?.result?.estadoOperacao ?? null,
    functional: result.parsed?.fault == null && result.parsed?.result != null });
}

async function main() {
  if (process.env.AT_LIVE_TEST !== '1') {
    return fail('LIVE_TEST_DISABLED', 'Explicit opt-in is required');
  }
  if (required.some((key) => !process.env[key])) {
    return fail('AUTH_CONFIGURATION_MISSING', 'Required local configuration is missing');
  }
  const username = validateAtUsername(process.env.AT_USERNAME);
  const baseNif = username.split('/')[0];
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

  let pfx; const transientKeys = [];
  try {
    pfx = readFileSync(process.env.AT_CLIENT_PFX_PATH);
    const rsaPublicKey = readAtPublicKey(process.env.AT_CIPHER_CERT_PATH);
    const client = new FactIntWsClient({ endpoint: FACTINTWS_ENDPOINT_8443,
      transport: sendOnceFactory({ pfx, passphrase: process.env.AT_CLIENT_PFX_PASSWORD }) });
    const repository = new FactIntWsRepository(client);
    const result = await runFactIntWsBootstrapSequence({ repository,
      contextFor: async (operation, phase) => {
        const { created } = await resolveFactIntWsCreated({
          ntpTimeProvider: ntpProviderFromEnvironment(), allowSystemClockFallback: false,
        });
        const aesKey = randomBytes(16); transientKeys.push(aesKey);
        const credentials = buildFactIntWsSecurityMaterial({ aesKey, created,
          password: process.env.AT_PASSWORD, rsaPublicKey });
        const year = phase.authentication ? created.slice(0, 4)
          : phase.final ? '2026' : undefined;
        return { username, credentials,
          input: { nif: baseNif, ...(operation === FactIntWsOperation.ECRAINICIAL ? { year } : {}), channel } };
      } });
    const final = result.finalOverview;
    const totals = final?.parsed?.totals ?? null;
    const sectors = final?.parsed?.sectors ?? [];
    const nonZeroSectorCount = sectors.filter((sector) => [
      sector.provisionalBenefitCents, sector.totalExpensesCents,
      sector.totalVatExpensesCents,
    ].some((value) => value != null && value !== 0)).length;
    const allZero = totals != null && totals.pendingValidation === 0
      && totals.provisionalBenefitCents === 0 && nonZeroSectorCount === 0;
    const changedPopulation = totals != null && !allZero;
    output({ authenticationEcraInicial: operationSummary(result.authenticationOverview),
      dadosContribuinte: operationSummary(result.taxpayer),
      finalEcraInicial2026: final ? { ...operationSummary(final),
        soapFault: final.parsed?.fault ?? null,
        pendingCount: totals?.pendingValidation ?? null,
        provisionalBenefitCents: totals?.provisionalBenefitCents ?? null,
        nonZeroSectorCount } : null,
      overviewStillAllZero: final ? allZero : null,
      bootstrapSequenceChangedPopulation: final ? changedPopulation : null,
      networkRequests, retries: 0,
      classification: !result.complete ? 'BOOTSTRAP_SEQUENCE_INCOMPLETE'
        : changedPopulation ? 'BOOTSTRAP_CALL_MISSING_CONFIRMED'
          : 'BOOTSTRAP_CALL_SEQUENCE_NOT_SUFFICIENT' });
    if (!result.complete) process.exitCode = 2;
  } finally {
    transientKeys.forEach((key) => key.fill(0));
    pfx?.fill(0);
  }
}

main().catch((error) => {
  if (error.code === 'PARSING_ERROR') {
    output({ networkRequests, retries: 0, classification: 'BOOTSTRAP_SEQUENCE_INCOMPLETE',
      errorClassification: 'PARSING_ERROR', field: error.field ?? null,
      expectedType: error.expectedType ?? null });
    process.exitCode = 2;
    return;
  }
  const diagnostic = tlsFailureDiagnostic(error, error.tlsStage || 'runtime');
  output({ networkRequests, retries: 0, classification: 'BOOTSTRAP_SEQUENCE_INCOMPLETE',
    errorClassification: error.code ?? 'UNKNOWN_RESPONSE',
    field: error.field ?? null, expectedType: error.expectedType ?? null, ...diagnostic });
  process.exitCode = 2;
});
