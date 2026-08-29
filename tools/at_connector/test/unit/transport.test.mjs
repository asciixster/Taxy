import assert from 'node:assert/strict';
import test from 'node:test';
import { AtTransportError, tlsMetadataFromSocket } from '../../src/transport.mjs';

test('TLS metadata is captured before the response releases its socket', () => {
  const metadata = tlsMetadataFromSocket({
    authorized: true,
    authorizationError: null,
    getProtocol: () => 'TLSv1.3',
    getCipher: () => ({ standardName: 'TLS_AES_256_GCM_SHA384', version: 'TLSv1.3' }),
    alpnProtocol: 'http/1.1',
    servername: 'synthetic.example',
  });
  assert.deepEqual(metadata, {
    authorized: true, authorizationError: null, protocol: 'TLSv1.3',
    cipher: 'TLS_AES_256_GCM_SHA384', cipherVersion: 'TLSv1.3', alpnProtocol: 'http/1.1',
    servername: 'synthetic.example',
  });
});

test('released TLS socket is handled without throwing or exposing internals', () => {
  assert.deepEqual(tlsMetadataFromSocket(null), {
    authorized: false, authorizationError: null, protocol: null, cipher: null,
    cipherVersion: null, alpnProtocol: null, servername: null,
  });
});

test('transport failure retains only a sanitized TLS diagnostic for reporting', () => {
  const cause = Object.assign(new Error('NIF 123456789 password=do-not-log handshake failure'), { code: 'ERR_SSL_HANDSHAKE_FAILURE' });
  const error = new AtTransportError('request failed', cause, 'tls-handshake');
  assert.equal(error.tlsDiagnostic.tlsErrorCode, 'ERR_SSL_HANDSHAKE_FAILURE');
  assert.equal(error.tlsDiagnostic.tlsStage, 'tls-handshake');
  assert.deepEqual(error.toJSON().details, { tlsDiagnostic: error.tlsDiagnostic });
  assert(!error.tlsDiagnostic.tlsErrorReasonSanitized.includes('123456789'));
  assert(!error.tlsDiagnostic.tlsErrorReasonSanitized.includes('do-not-log'));
});
