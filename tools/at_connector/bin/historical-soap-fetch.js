#!/usr/bin/env node
import { loadConfig } from '../src/config.mjs';
import { AtErrorCode } from '../src/errors.mjs';
import { buildHistoricalEnvelope, HistoricalAtConsultationClient, sanitizedHistoricalEnvelope } from '../src/historical.mjs';
import { redact } from '../src/redaction.mjs';

const dryRun = process.argv.includes('--dry-run');
const dates = { startDate: process.env.AT_START_DATE, endDate: process.env.AT_END_DATE };

function output(value) {
  process.stdout.write(`${JSON.stringify(redact(value), null, 2)}\n`);
}

function classify(result) {
  const text = `${result.soap.fault?.message || ''} ${result.result?.description || ''}`;
  if (/autentica|credential|password|utilizador/i.test(text)) return AtErrorCode.AUTH_REJECTED;
  if (/permiss|autoriza|acesso/i.test(text)) return AtErrorCode.SUBUSER_PERMISSION_DENIED;
  if (result.soap.fault) return AtErrorCode.SOAP_FAULT;
  return null;
}

async function main() {
  const config = loadConfig(process.env, { requireAtCredentials: true });
  if (!dates.startDate || !dates.endDate) throw new Error('AT_START_DATE and AT_END_DATE are required');

  if (dryRun) {
    buildHistoricalEnvelope({ ...dates, username: config.username, password: config.password, cipherCertificatePath: config.cipherCertificatePath });
    output({ mode: 'DRY_RUN', source: 'HISTORICAL_CODE_EVIDENCE', networkRequests: 0, envelope: sanitizedHistoricalEnvelope() });
    return;
  }
  if (process.env.AT_LIVE_TEST !== '1') {
    const error = new Error('Set AT_LIVE_TEST=1 to authorize the single sandbox request');
    error.code = AtErrorCode.LIVE_TEST_DISABLED;
    throw error;
  }

  const result = await new HistoricalAtConsultationClient(config).fetchOnce(dates);
  output({
    mode: 'LIVE_TEST', networkRequests: 1, tlsAuthorized: result.transport.tls.authorized,
    httpStatus: result.transport.statusCode, outcome: classify(result) || 'RESPONSE_RECEIVED',
    fault: result.soap.fault && { code: result.soap.fault.code, message: result.soap.fault.message, detail: result.soap.fault.detail },
    operationStatus: result.result?.operationStatus, description: result.result?.description,
    totalPages: result.result?.pagination?.totalPages, invoiceCount: result.result?.invoices.length,
    evidenceStatus: result.evidenceStatus, runtimeConfirmedFields: result.runtimeConfirmedFields,
  });
}

main().catch((error) => {
  output({ result: 'BLOCKED_OR_FAILED', code: error.code || error.name, message: error.message, networkRequests: 0 });
  process.exitCode = 2;
});
