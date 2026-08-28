import assert from 'node:assert/strict';
import test from 'node:test';
import { redact, redactText, safeLog } from '../../src/redaction.mjs';

test('redacts credential-shaped fields recursively', () => {
  const result = redact({ username: '123456789/1', password: 'plain', nested: { pfxPassword: 'pfx-secret' } });
  assert.equal(result.password, '[REDACTED]');
  assert.equal(result.nested.pfxPassword, '[REDACTED]');
  assert.equal(result.username, '[REDACTED]');
});

test('redacts SOAP Password and Nonce values', () => {
  const xml = '<wss:Password>ciphertext</wss:Password><wss:Nonce>nonce</wss:Nonce>';
  const safe = redactText(xml);
  assert(!safe.includes('ciphertext'));
  assert(!safe.includes('>nonce<'));
});

test('redacts primary usernames, subusers and document-shaped identifiers', () => {
  const value = redactText('user 123456789 sub 123456789/12 document FT-123456');
  assert(!value.includes('123456789'));
  assert(!value.includes('FT-123456'));
});

test('safe logs contain neither plaintext nor encrypted credential fields', () => {
  const lines = [];
  safeLog((line) => lines.push(line), 'test', { password: 'plain', nonce: 'cipher', status: 500 });
  assert(!lines[0].includes('plain'));
  assert(!lines[0].includes('cipher'));
  assert(lines[0].includes('500'));
});
