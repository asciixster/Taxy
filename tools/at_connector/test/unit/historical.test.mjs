import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { generateKeyPairSync } from 'node:crypto';
import test from 'node:test';
import { AtErrorCode } from '../../src/errors.mjs';
import { validateAtUsername } from '../../src/auth.mjs';
import { buildHistoricalEnvelope, customerTaxIdFromUsername, HistoricalAtConsultationClient, HISTORICAL_NAMESPACE, sanitizedHistoricalEnvelope, validateHistoricalDateRange } from '../../src/historical.mjs';
import { buildSoapHeaders } from '../../src/transport.mjs';

const { publicKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
const base = {
  username: '123456789/1', password: 'not-a-real-secret', cipherPublicKey: publicKey,
  startDate: '2025-01-01', endDate: '2025-01-02',
  clock: () => new Date('2026-08-28T11:22:33.987Z'), randomSource: () => Buffer.alloc(16, 7),
};

test('primary NIF and historical subuser are both valid usernames', () => {
  assert.equal(validateAtUsername('123456789'), '123456789');
  assert.equal(validateAtUsername('123456789/12'), '123456789/12');
  assert.throws(() => validateAtUsername('12345678'), (error) => error.code === AtErrorCode.INVALID_USERNAME);
  assert.throws(() => validateAtUsername('123456789/12345'), (error) => error.code === AtErrorCode.INVALID_USERNAME);
  assert.equal('SUBUSER_REQUIRED' in AtErrorCode, false);
});

test('CustomerTaxID is derived from primary NIF or subuser base NIF', () => {
  assert.equal(customerTaxIdFromUsername('123456789'), '123456789');
  assert.equal(customerTaxIdFromUsername('123456789/12'), '123456789');
  assert.throws(() => customerTaxIdFromUsername('123456789/1', '987654321'), (error) => error.code === AtErrorCode.CUSTOMER_TAX_ID_MISMATCH);
});

test('historical request reproduces exact SOAP contract and timestamp precision', () => {
  const request = buildHistoricalEnvelope(base);
  assert.equal(HISTORICAL_NAMESPACE, 'http://factemi.at.min_financas.pt/fatshareInvoices');
  assert.equal(request.createdPlaintext, '2026-08-28T11:22:33.000Z');
  assert(request.xml.includes(`xmlns:fat="${HISTORICAL_NAMESPACE}"`));
  assert(request.xml.includes('<fat:InvoicesRequest>'));
  assert(request.xml.includes('<fat:TaxRegistrationNumber>123456789</fat:TaxRegistrationNumber>'));
  assert(request.xml.includes('<fat:nPage>1</fat:nPage><fat:nDocsPage>500</fat:nDocsPage>'));
  for (const field of ['Password', 'Nonce', 'Created']) {
    const encoded = request.xml.match(new RegExp(`<wss:${field}>([^<]+)</wss:${field}>`))[1];
    assert.match(encoded, /^[A-Za-z0-9+/]+={0,2}$/);
  }
  assert.equal(request.soapAction, null);
});

test('current request serializes required body fields in exact order without hidden filters', () => {
  const xml = buildHistoricalEnvelope(base).xml;
  const body = xml.match(/<S:Body>([\s\S]*?)<\/S:Body>/)[1];
  const orderedTags = [...body.matchAll(/<(?:fat:)?([A-Za-z][A-Za-z0-9]*)(?:\s[^>]*)?>/g)]
    .map((match) => match[1]);
  assert.deepEqual(orderedTags, [
    'InvoicesRequest', 'TaxRegistrationNumber', 'StartDate', 'EndDate',
    'Pagination', 'nPage', 'nDocsPage',
  ]);
  for (const absent of [
    'CustomerTaxID', 'Status', 'InvoiceType', 'Sector', 'Country',
    'Origin', 'Situation', 'Role', 'FiscalYear', 'Channel', 'Software', 'Mode',
  ]) assert.equal(body.includes(`<fat:${absent}>`), false, `${absent} must remain absent`);
});

test('sanitized historical contract records the material current-versus-source diff', () => {
  const fixtureUrl = new URL('../fixtures/sanitized/historical-fatshare-request-contract.json', import.meta.url);
  const contract = JSON.parse(readFileSync(fixtureUrl, 'utf8'));
  assert.equal(contract.source, 'HISTORICAL_CODE_EVIDENCE');
  assert.equal(contract.requestRoot, 'InvoicesRequest');
  assert.equal(contract.namespace, HISTORICAL_NAMESPACE);
  assert.equal(contract.customerRolePartyElement, 'CustomerTaxID');
  assert.equal(contract.defaultPartyElement, 'TaxRegistrationNumber');
  assert.deepEqual(contract.fieldOrder, ['party', 'StartDate', 'EndDate', 'Pagination']);
  assert.equal(contract.dateFormat, 'YYYY-MM-DD');
  assert.equal(contract.pageDefault, 1);
  assert.equal(contract.pageSizeDefault, 300);
  assert.equal(contract.pageSizeMinimum, 1);
  assert.equal(contract.pageSizeMaximum, 5000);
  assert.equal(contract.containsAdditionalBodyFilters, false);

  const current = buildHistoricalEnvelope(base).xml;
  assert(current.includes('<fat:TaxRegistrationNumber>'));
  assert.equal(current.includes('<fat:CustomerTaxID>'), false);
  assert(current.includes('<fat:nPage>1</fat:nPage>'));
  assert(current.includes('<fat:nDocsPage>500</fat:nDocsPage>'));
});

test('live harness accepts only an ordered, small date interval', () => {
  assert.deepEqual(validateHistoricalDateRange('2025-01-01', '2025-01-02'), { startDate: '2025-01-01', endDate: '2025-01-02' });
  assert.throws(() => validateHistoricalDateRange('2025-01-02', '2025-01-01'), /must not precede/);
  assert.throws(() => validateHistoricalDateRange('2025-01-01', '2025-01-09'), /7 days/);
});

test('historical transport omits SOAPAction rather than sending an empty header', () => {
  assert.equal('SOAPAction' in buildSoapHeaders('<x/>', undefined), false);
  assert.equal(buildSoapHeaders('<x/>', 'urn:x').SOAPAction, '"urn:x"');
});

test('sanitized envelope contains no credentials, NIF, ciphertext or key material', () => {
  const output = sanitizedHistoricalEnvelope();
  assert(!output.includes('123456789'));
  assert(output.includes('[REDACTED_NIF]'));
  assert(output.includes('[REDACTED]'));
});

test('client permits at most one request and uses no retry', async () => {
  let calls = 0;
  let countedNetworkRequests = 0;
  const client = new HistoricalAtConsultationClient({
    environment: 'test', username: base.username, password: base.password,
    cipherCertificatePath: 'unused', pfxPath: 'unused', pfxPassword: 'unused',
  }, { envelopeBuilder: (input) => buildHistoricalEnvelope({ ...input, cipherPublicKey: publicKey }), onNetworkRequest: () => { countedNetworkRequests += 1; }, transport: async ({ onRequestStart }) => {
    onRequestStart();
    calls += 1;
    return { statusCode: 200, headers: {}, body: '<InvoicesResponse><EstadoOperacao>200</EstadoOperacao><Desc>OK</Desc><totalPages>0</totalPages></InvoicesResponse>', tls: { authorized: true } };
  } });
  const response = await client.fetchOnce({ startDate: '2025-01-01', endDate: '2025-01-02' });
  assert.equal(response.result.operationStatus, 200);
  assert.deepEqual(response.runtimeConfirmedFields, ['namespace']);
  await assert.rejects(() => client.fetchOnce({ startDate: '2025-01-01', endDate: '2025-01-02' }), (error) => error.code === AtErrorCode.RATE_LIMIT_EXCEEDED);
  assert.equal(calls, 1);
  assert.equal(countedNetworkRequests, 1);
});

test('functional primary-login response confirms namespace but not username authorization', async () => {
  const client = new HistoricalAtConsultationClient({
    environment: 'test', username: '123456789', password: base.password,
    cipherCertificatePath: 'unused', pfxPath: 'unused', pfxPassword: 'unused',
  }, {
    envelopeBuilder: (input) => buildHistoricalEnvelope({ ...input, cipherPublicKey: publicKey }),
    transport: async () => ({ statusCode: 200, headers: {}, body: '<InvoicesResponse><EstadoOperacao>200</EstadoOperacao><Desc>OK</Desc></InvoicesResponse>', tls: { authorized: true } }),
  });
  const response = await client.fetchOnce({ startDate: '2025-01-01', endDate: '2025-01-01' });
  assert.deepEqual(response.runtimeConfirmedFields, ['namespace']);
});

test('parsed empty-list operation status is a functional namespace response', async () => {
  const client = new HistoricalAtConsultationClient({
    environment: 'test', username: '123456789', password: base.password,
    cipherCertificatePath: 'unused', pfxPath: 'unused', pfxPassword: 'unused',
  }, {
    envelopeBuilder: (input) => buildHistoricalEnvelope({ ...input, cipherPublicKey: publicKey }),
    transport: async () => ({ statusCode: 200, headers: {}, body: '<InvoicesResponse><EstadoOperacao>486</EstadoOperacao><Desc>Lista vazia.</Desc></InvoicesResponse>', tls: { authorized: true } }),
  });
  const response = await client.fetchOnce({ startDate: '2025-01-01', endDate: '2025-01-01' });
  assert.equal(response.evidenceStatus, 'RUNTIME_BEHAVIOR_CONFIRMED');
  assert.deepEqual(response.runtimeConfirmedFields, ['namespace']);
});
