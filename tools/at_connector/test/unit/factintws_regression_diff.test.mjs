import assert from 'node:assert/strict';
import test from 'node:test';
import { readFileSync } from 'node:fs';
import { buildFactIntWsEnvelope, FACTINTWS_ENDPOINT_8443,
  factIntWsHttpContract, factIntWsTlsOptions } from '../../src/factintws.mjs';

const reference = readFileSync(new URL(
  '../fixtures/factintws_synthetic/ecra_inicial_runtime_confirmed_envelope.xml',
  import.meta.url,
), 'utf8').replace(/\r?\n$/, '');

function currentEnvelope() {
  return buildFactIntWsEnvelope({ username: 'USER',
    credentials: { encryptedDigest: 'DIGEST', encryptedPassword: 'PASSWORD',
      encryptedNonce: 'NONCE', created: 'CREATED' },
    input: { nif: 'NIF', year: '2026',
      channel: { system: 'A', version: 'Android SDK: 35 (15)' } } });
}

test('current EcraInicial envelope is byte-equivalent to runtime-confirmed reference', () => {
  const current = currentEnvelope();
  assert.equal(current, reference);
  assert.equal(Buffer.compare(Buffer.from(current, 'utf8'), Buffer.from(reference, 'utf8')), 0);
  assert.equal(current.charCodeAt(0), '<'.charCodeAt(0));
  assert.equal(current.startsWith('\uFEFF'), false);
  assert.equal(current.includes('\r\n'), false);
  assert.equal(current.endsWith('\n'), false);
  assert.match(current, /^<\?xml version="1\.0" encoding="utf-8" standalone="no"\?>\n/);
});

test('runtime-confirmed and current HTTP request contracts remain identical', () => {
  const contract = factIntWsHttpContract('EcraInicial', FACTINTWS_ENDPOINT_8443);
  assert.deepEqual(contract.headers, {
    'User-Agent': 'ksoap2-android/2.6.0+',
    SOAPAction: 'http://factemi.at.min_financas.pt/factintws/EcraInicial',
    'Content-Type': 'text/xml;charset=utf-8',
    'Accept-Encoding': 'gzip',
  });
  assert.equal(Object.hasOwn(contract.headers, 'Content-Encoding'), false);
  assert.equal(Object.hasOwn(contract.headers, 'Transfer-Encoding'), false);
  assert.deepEqual(factIntWsTlsOptions(), { minVersion: 'TLSv1.2' });
});

test('declared Content-Length equals actual UTF-8 bytes, not characters', () => {
  const body = currentEnvelope().replace('USER', 'USÉR');
  const declaredContentLength = Buffer.byteLength(body, 'utf8');
  const actualBytes = Buffer.from(body, 'utf8');
  assert.equal(declaredContentLength, actualBytes.length);
  assert.notEqual(declaredContentLength, body.length);
});
