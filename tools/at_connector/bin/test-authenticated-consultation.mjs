#!/usr/bin/env node
import { loadConfig } from '../src/config.mjs';
import { assertAuthenticatedConsultationEvidence, protocolEvidence } from '../src/evidence.mjs';
import { redact } from '../src/redaction.mjs';

const dryRun = process.argv.includes('--dry-run');

function print(value) { process.stdout.write(`${JSON.stringify(redact(value), null, 2)}\n`); }

try {
  if (!dryRun) throw new Error('Only --dry-run is available while critical official evidence remains unresolved');
  loadConfig(process.env, { requireAtCredentials: true });
  print({ mode: 'DRY_RUN', networkRequests: 0, evidence: protocolEvidence.map(({ field, value, status }) => ({ field, value, status })) });
  assertAuthenticatedConsultationEvidence();
  throw new Error('Authenticated transport is intentionally unavailable until the evidence gate is updated and reviewed');
} catch (error) {
  print({ result: 'BLOCKED', code: error.code || error.name, message: error.message, networkRequests: 0 });
  process.exitCode = 2;
}
