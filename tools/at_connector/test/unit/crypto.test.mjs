import assert from 'node:assert/strict';
import test from 'node:test';
import { aes128EcbPkcs5Encrypt, AtCryptoError, buildEncryptedCredentials, readAtPublicKey } from '../../src/crypto.mjs';

test('AES-128-ECB PKCS padding matches an independent known vector', () => {
  const key = Buffer.from('000102030405060708090a0b0c0d0e0f', 'hex');
  const actual = aes128EcbPkcs5Encrypt('TESTE', key).toString('hex');
  // Cross-checked with OpenSSL 3 `enc -aes-128-ecb` using the same key/input.
  assert.equal(actual, '49ed528cbb62ef866e47b82f0b9aca12');
});

test('AES helper requires exactly 128 bits', () => {
  assert.throws(() => aes128EcbPkcs5Encrypt('secret', Buffer.alloc(15)), AtCryptoError);
});

test('invalid cipher certificate fails without exposing content', () => {
  assert.throws(() => readAtPublicKey(import.meta.filename), /invalid or unreadable/);
});

test('authenticated encryption fails closed while RSA padding is undocumented', () => {
  assert.throws(() => buildEncryptedCredentials({ password: 'never-log-me', created: '2026-01-01T00:00:00Z', publicKey: {}, sessionKey: Buffer.alloc(16) }), /RSA_PADDING_UNCONFIRMED/);
});
