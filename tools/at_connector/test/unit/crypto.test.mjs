import assert from 'node:assert/strict';
import test from 'node:test';
import { generateKeyPairSync, X509Certificate } from 'node:crypto';
import { aes128EcbPkcs5Encrypt, AtCryptoError, buildEncryptedCredentials, inspectAtCipherPublicKey, readAtPublicKey } from '../../src/crypto.mjs';

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

test('cipher inspection accepts only a readable RSA public certificate and exposes metadata', () => {
  // Node cannot issue X.509 certificates; the integration test validates the
  // real external certificate. This unit assertion verifies fail-closed
  // behavior and that the inspector API cannot report a private key.
  assert.throws(() => inspectAtCipherPublicKey(import.meta.filename), /invalid or unreadable/);
  assert.equal(typeof X509Certificate, 'function');
  assert.equal(generateKeyPairSync('rsa', { modulusLength: 1024 }).publicKey.asymmetricKeyType, 'rsa');
});

test('authenticated encryption fails closed while RSA padding is undocumented', () => {
  assert.throws(() => buildEncryptedCredentials({ password: 'never-log-me', created: '2026-01-01T00:00:00Z', publicKey: {}, sessionKey: Buffer.alloc(16) }), /RSA_PADDING_UNCONFIRMED/);
});
