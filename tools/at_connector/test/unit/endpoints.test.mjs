import assert from 'node:assert/strict';
import test from 'node:test';
import { endpointFor } from '../../src/endpoints.mjs';

test('selects official test consultation endpoint', () => {
  assert.equal(endpointFor('test').toString(), 'https://servicos.portaldasfinancas.gov.pt:725/fatshare/ws/fatshareFaturas');
});

test('selects official production consultation structure', () => {
  assert.equal(endpointFor('production').port, '425');
});

test('selects official test submission endpoint', () => {
  assert.equal(endpointFor('test', 'invoiceSubmission').port, '723');
});

test('rejects unknown service', () => {
  assert.throws(() => endpointFor('test', 'invented'), /Unsupported AT service/);
});
