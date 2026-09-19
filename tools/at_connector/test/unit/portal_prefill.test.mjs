import assert from 'node:assert/strict';
import test from 'node:test';
import {
  extractDm3IrsHtmlVersion,
  parseForwardForm,
  summarizePrefillPayload,
} from '../../src/portal_prefill.mjs';

test('extracts the official web client version without exposing values', () => {
  assert.equal(
    extractDm3IrsHtmlVersion('dm3irshtmlVersion: "2.19.18-104491"'),
    '2.19.18-104491',
  );
});

test('parses the SSO participant forwarding form', () => {
  assert.deepEqual(parseForwardForm(`
    <form id="forwardParticipantForm" action="https://irs.portaldasfinancas.gov.pt/sso">
      <input name="ticket" value="opaque">
    </form>`), {
    action: 'https://irs.portaldasfinancas.gov.pt/sso',
    fields: { ticket: 'opaque' },
  });
});

test('summarizes only structural field presence', () => {
  const summary = summarizePrefillPayload(JSON.stringify({
    Rostoq06BT03: [{ nif: 'redacted' }],
    AnexoAq04AT01: [{ rendimento: 1 }],
    AnexoCq04C470: 1,
  }));
  assert.equal(summary.fieldCount, 3);
  assert.equal(summary.populatedFieldCount, 3);
  assert.deepEqual(summary.groups, { Rosto: 1, AnexoA: 1, AnexoC: 1 });
  assert.equal(summary.hasCategoryA, true);
  assert.equal(summary.hasCategoryB, true);
  assert.equal(summary.hasHousehold, true);
});
