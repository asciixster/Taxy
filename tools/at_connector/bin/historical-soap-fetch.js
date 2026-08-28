#!/usr/bin/env node
import { loadConfig, loadEnvLocalFallback } from '../src/config.mjs';
import { AtErrorCode } from '../src/errors.mjs';
import { buildHistoricalEnvelope, HistoricalAtConsultationClient, sanitizedHistoricalEnvelope } from '../src/historical.mjs';
import { redact } from '../src/redaction.mjs';

const dryRun = process.argv.includes('--dry-run');
let effectiveEnv = process.env;
let envLocalFound = false;

function output(value) {
  process.stdout.write(`${JSON.stringify(redact(value), null, 2)}\n`);
}

function classify(result) {
  if (result.transport.statusCode === 401) return 'AUTH_ERROR';
  if (result.transport.statusCode === 403) return 'AUTHORIZATION_ERROR';
  const text = `${result.soap.fault?.message || ''} ${result.result?.description || ''}`;
  if (/autentica|credential|password|utilizador/i.test(text)) return 'AUTH_ERROR';
  if (/permiss|autoriza|acesso/i.test(text)) return 'AUTHORIZATION_ERROR';
  if (result.soap.fault && /protocol|schema|xml|namespace|soapaction/i.test(text)) return 'SOAP_PROTOCOL_ERROR';
  if (result.soap.fault) return 'REMOTE_FAULT';
  if (Number.isFinite(result.result?.operationStatus) && result.result.invoices.length === 0) return 'SUCCESS_EMPTY_RESULT';
  if (Number.isFinite(result.result?.operationStatus)) return 'SUCCESS';
  return 'UNKNOWN';
}

function classifyError(error) {
  if ([AtErrorCode.TLS_ERROR, AtErrorCode.CLIENT_CERT_REJECTED].includes(error.code)) return 'TLS_ERROR';
  if (error.code === AtErrorCode.INVALID_RESPONSE) return 'PARSING_ERROR';
  if (error.code === AtErrorCode.AUTH_CONFIGURATION_MISSING) return 'AUTH_CONFIGURATION_MISSING';
  return 'UNKNOWN';
}

let networkRequests = 0;

async function main() {
  const local = loadEnvLocalFallback(process.env);
  effectiveEnv = local.env;
  envLocalFound = local.found;
  const dates = { startDate: effectiveEnv.AT_START_DATE, endDate: effectiveEnv.AT_END_DATE };
  const config = loadConfig(effectiveEnv, { requireAtCredentials: true });
  if (!dates.startDate || !dates.endDate) throw new Error('AT_START_DATE and AT_END_DATE are required');

  if (dryRun) {
    buildHistoricalEnvelope({ ...dates, username: config.username, password: config.password, cipherCertificatePath: config.cipherCertificatePath });
    output({ mode: 'DRY_RUN', source: 'HISTORICAL_CODE_EVIDENCE', networkRequests: 0, envelope: sanitizedHistoricalEnvelope() });
    return;
  }
  if (effectiveEnv.AT_LIVE_TEST !== '1') {
    const error = new Error('Set AT_LIVE_TEST=1 to authorize the single sandbox request');
    error.code = AtErrorCode.LIVE_TEST_DISABLED;
    throw error;
  }

  // Validate the complete envelope before counting the one permitted network attempt.
  buildHistoricalEnvelope({ ...dates, username: config.username, password: config.password, cipherCertificatePath: config.cipherCertificatePath });
  const result = await new HistoricalAtConsultationClient(config, { onNetworkRequest: () => { networkRequests += 1; } }).fetchOnce(dates);
  output({
    mode: 'LIVE_TEST', envLocalFound, networkRequests, interval: dates, tlsAuthorized: result.transport.tls.authorized,
    httpStatus: result.transport.statusCode, classification: classify(result),
    fault: result.soap.fault && { code: result.soap.fault.code, message: result.soap.fault.message },
    operationStatus: result.result?.operationStatus, description: result.result?.description,
    totalPages: result.result?.pagination?.totalPages, invoiceCount: result.result?.invoices.length,
    invoices: result.result?.invoices.map((invoice) => ({
      anonymousInvoiceIndex: invoice.anonymousInvoiceIndex,
      date: invoice.date,
      totalCents: invoice.totalCents,
      taxableCents: invoice.taxableCents,
      vatCents: invoice.vatCents,
      sector: invoice.sector,
      classificationStatus: invoice.classificationStatus,
      pendingStatus: invoice.pendingStatus,
      fieldPresence: invoice.fieldPresence,
    })),
    observedFields: result.result?.observedFields,
    notAvailableFields: result.result?.notAvailableFields,
    unknownElements: result.result?.unknownElements,
    evidenceStatus: result.evidenceStatus, runtimeConfirmedFields: result.runtimeConfirmedFields,
  });
}

main().catch((error) => {
  output({ result: 'BLOCKED_OR_FAILED', envLocalFound, code: error.code || error.name, message: error.message, details: error.details, classification: classifyError(error), networkRequests });
  process.exitCode = 2;
});
