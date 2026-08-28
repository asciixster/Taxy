import assert from 'node:assert/strict';
import test from 'node:test';
import { tlsMetadataFromSocket } from '../../src/transport.mjs';

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
