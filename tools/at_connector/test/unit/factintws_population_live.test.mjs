import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';

const harness = readFileSync(new URL('../../bin/factintws-population-live.mjs', import.meta.url), 'utf8');

test('population diagnostic is bounded and contains only the two approved read-only operations', () => {
  assert.match(harness, /const maximumRequests = 2/);
  assert.match(harness, /FactIntWsOperation\.BY_SECTOR/);
  assert.match(harness, /FactIntWsOperation\.PENDING/);
  assert.doesNotMatch(harness, /ClassificarFatura|RegistarFatura|EliminarFatura|AssociarReceita/);
  assert.match(harness, /retries: 0/);
});

test('each population request records reproducibility metadata before transport', () => {
  const metadata = harness.indexOf("phase: 'BEFORE_REQUEST'");
  const send = harness.indexOf('await sendOnce');
  assert.ok(metadata >= 0 && send > metadata);
  assert.match(harness, /buildFactIntWsLiveMetadata/);
  assert.match(harness, /OFFICIAL_EMPTY_CODSETOR_ALL_SECTOR_QUERY/);
  assert.match(harness, /DIAGNOSTIC_OVERRIDE_READONLY_PENDING_QUERY/);
});

test('real invoice stops the second diagnostic and parser count integrity is fail-closed', () => {
  assert.match(harness, /if \(allSector\.invoiceCount === 0 && allSector\.parserError == null\)/);
  assert.match(harness, /invoices\.length === domainInvoices\.length/);
});
