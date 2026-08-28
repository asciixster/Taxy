import assert from 'node:assert/strict';
import { constants, generateKeyPairSync, privateDecrypt } from 'node:crypto';
import test from 'node:test';
import { AtTimestampBuilder, AtUsernameTokenBuilder } from '../../src/auth.mjs';
import { generateAes128SessionKey, RsaPaddingMode, rsaEncryptSessionKey } from '../../src/crypto.mjs';
import { redactText } from '../../src/redaction.mjs';

const { publicKey, privateKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });

test('CSPRNG produces 128-bit keys and different requests receive different keys', () => {
  const a = generateAes128SessionKey();
  const b = generateAes128SessionKey();
  assert.equal(a.length, 16);
  assert.equal(b.length, 16);
  assert.notDeepEqual(a, b);
});

for (const [mode, padding, oaepHash] of [
  [RsaPaddingMode.PKCS1_V1_5, constants.RSA_PKCS1_PADDING, undefined],
  [RsaPaddingMode.OAEP_SHA1, constants.RSA_PKCS1_OAEP_PADDING, 'sha1'],
  [RsaPaddingMode.OAEP_SHA256, constants.RSA_PKCS1_OAEP_PADDING, 'sha256'],
]) {
  test(`RSA mode ${mode} round-trips with independent private-key operation`, () => {
    const key = Buffer.from('00112233445566778899aabbccddeeff', 'hex');
    const encrypted = rsaEncryptSessionKey(key, publicKey, mode);
    const decrypted = privateDecrypt({ key: privateKey, padding, ...(oaepHash ? { oaepHash } : {}) }, encrypted);
    assert.deepEqual(decrypted, key);
  });
}

test('RSA encryption has no default mode', () => {
  assert.throws(() => rsaEncryptSessionKey(Buffer.alloc(16), publicKey), /RSA_PADDING_UNCONFIRMED/);
});

test('timestamp requires and preserves explicit UTC ISO 8601', () => {
  assert.equal(AtTimestampBuilder.fromIso8601Utc('2026-08-28T17:00:01.250Z'), '2026-08-28T17:00:01.250Z');
  assert.throws(() => AtTimestampBuilder.fromIso8601Utc('2026-08-28T18:00:00+01:00'));
});

test('UsernameToken serialization escapes username and never exposes plaintext after redaction', () => {
  const plaintext = 'unique-plain-secret';
  const xml = AtUsernameTokenBuilder.build({
    username: '123456789/1', password: plaintext, publicKey,
    rsaPaddingMode: RsaPaddingMode.OAEP_SHA256,
    created: '2026-08-28T17:00:01.250Z',
    randomSource: () => Buffer.from('00112233445566778899aabbccddeeff', 'hex'),
  });
  assert(!xml.includes(plaintext));
  assert(!redactText(xml).includes('123456789'));
  assert.match(redactText(xml), /\[REDACTED\]/);
});

test('UsernameToken accepts primary NIF without requiring a subuser', () => {
  assert.doesNotThrow(() => AtUsernameTokenBuilder.build({
    username: '123456789', password: 'test-only', publicKey,
    rsaPaddingMode: RsaPaddingMode.OAEP_SHA256,
    created: '2026-08-28T17:00:01.250Z',
    randomSource: () => Buffer.from('00112233445566778899aabbccddeeff', 'hex'),
  }));
});
