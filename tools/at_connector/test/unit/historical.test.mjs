import assert from 'node:assert/strict';
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
  assert(request.xml.includes('<fat:CustomerTaxID>123456789</fat:CustomerTaxID>'));
  assert(request.xml.includes('<fat:nPage>1</fat:nPage><fat:nDocsPage>500</fat:nDocsPage>'));
  for (const field of ['Password', 'Nonce', 'Created']) {
    const encoded = request.xml.match(new RegExp(`<wss:${field}>([^<]+)</wss:${field}>`))[1];
    assert.match(encoded, /^[A-Za-z0-9+/]+={0,2}$/);
  }
  assert.equal(request.soapAction, null);
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
  const client = new HistoricalAtConsultationClient({
    environment: 'test', username: base.username, password: base.password,
    cipherCertificatePath: 'unused', pfxPath: 'unused', pfxPassword: 'unused',
  }, { envelopeBuilder: (input) => buildHistoricalEnvelope({ ...input, cipherPublicKey: publicKey }), transport: async () => {
    calls += 1;
    return { statusCode: 200, headers: {}, body: '<InvoicesResponse><EstadoOperacao>200</EstadoOperacao><Desc>OK</Desc><totalPages>0</totalPages></InvoicesResponse>', tls: { authorized: true } };
  } });
  const response = await client.fetchOnce({ startDate: '2025-01-01', endDate: '2025-01-02' });
  assert.equal(response.result.operationStatus, 200);
  assert(response.runtimeConfirmedFields.includes('rsaPadding'));
  assert(response.runtimeConfirmedFields.includes('usernameFormat.subuser'));
  await assert.rejects(() => client.fetchOnce({ startDate: '2025-01-01', endDate: '2025-01-02' }), (error) => error.code === AtErrorCode.RATE_LIMIT_EXCEEDED);
  assert.equal(calls, 1);
});

test('successful primary login confirms only primary username runtime shape', async () => {
  const client = new HistoricalAtConsultationClient({
    environment: 'test', username: '123456789', password: base.password,
    cipherCertificatePath: 'unused', pfxPath: 'unused', pfxPassword: 'unused',
  }, {
    envelopeBuilder: (input) => buildHistoricalEnvelope({ ...input, cipherPublicKey: publicKey }),
    transport: async () => ({ statusCode: 200, headers: {}, body: '<InvoicesResponse><EstadoOperacao>200</EstadoOperacao><Desc>OK</Desc></InvoicesResponse>', tls: { authorized: true } }),
  });
  const response = await client.fetchOnce({ startDate: '2025-01-01', endDate: '2025-01-01' });
  assert(response.runtimeConfirmedFields.includes('usernameFormat.primary'));
  assert(!response.runtimeConfirmedFields.includes('usernameFormat.subuser'));
});
