import assert from 'node:assert/strict';
import test from 'node:test';
import { AtTransportError, sanitizedTlsFailure, sendMtlsSoap, tlsMetadataFromSocket } from '../../src/transport.mjs';

test('TLS metadata is captured before the response releases its socket', () => {
  const metadata = tlsMetadataFromSocket({
    authorized: true,
    authorizationError: null,
    getProtocol: () => 'TLSv1.3',
    getCipher: () => ({ standardName: 'TLS_AES_256_GCM_SHA384' }),
  });
  assert.deepEqual(metadata, {
    authorized: true, authorizationError: null, protocol: 'TLSv1.3', cipher: 'TLS_AES_256_GCM_SHA384',
  });
});

test('released TLS socket is handled without throwing or exposing internals', () => {
  assert.deepEqual(tlsMetadataFromSocket(null), {
    authorized: false, authorizationError: null, protocol: null, cipher: null,
  });
});

test('local certificate read failures do not count as network requests', async () => {
  let networkRequests = 0;
  await assert.rejects(() => sendMtlsSoap({
    endpoint: 'https://127.0.0.1:1/', pfxPath: 'definitely-not-present.pfx', pfxPassword: '', xml: '<x/>',
    onRequestStart: () => { networkRequests += 1; },
  }), (error) => error.code === 'TLS_ERROR');
  assert.equal(networkRequests, 0);
});

test('TLS errors retain only stable sanitized code, reason and stage', () => {
  const raw = new Error('unknown ca for CN=123456789 passphrase=never-log-this');
  raw.code = 'ERR_SSL_TLSV1_ALERT_UNKNOWN_CA';
  const details = sanitizedTlsFailure(raw);
  assert.deepEqual(details, {
    tlsErrorCode: 'ERR_SSL_TLSV1_ALERT_UNKNOWN_CA',
    tlsErrorReasonSanitized: 'UNKNOWN_CA',
    tlsStage: 'TLS_HANDSHAKE',
  });
  const serialized = JSON.stringify(new AtTransportError('AT TLS/HTTP request failed', raw).toJSON());
  assert(!serialized.includes('123456789'));
  assert(!serialized.includes('never-log-this'));
  assert(serialized.includes('UNKNOWN_CA'));
});

test('TLS alert numbers are sanitized without retaining raw peer text', () => {
  const details = sanitizedTlsFailure({ code: 'ERR_SSL_SSLV3_ALERT_HANDSHAKE_FAILURE', message: 'peer details: alert number 40; NIF 123456789' });
  assert.equal(details.tlsErrorReasonSanitized, 'TLS_ALERT_40');
  assert.equal(JSON.stringify(details).includes('123456789'), false);
});
