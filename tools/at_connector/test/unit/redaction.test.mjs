import assert from 'node:assert/strict';
import test from 'node:test';
import { redact, redactText, safeLog } from '../../src/redaction.mjs';

test('redacts credential-shaped fields recursively', () => {
  const result = redact({ username: '123456789/1', password: 'plain', nested: { pfxPassword: 'pfx-secret' } });
  assert.equal(result.password, '[REDACTED]');
  assert.equal(result.nested.pfxPassword, '[REDACTED]');
  assert.equal(result.username, '[REDACTED_NIF]/1');
});

test('redacts SOAP Password and Nonce values', () => {
  const xml = '<wss:Password>ciphertext</wss:Password><wss:Nonce>nonce</wss:Nonce>';
  const safe = redactText(xml);
  assert(!safe.includes('ciphertext'));
  assert(!safe.includes('>nonce<'));
});

test('safe logs contain neither plaintext nor encrypted credential fields', () => {
  const lines = [];
  safeLog((line) => lines.push(line), 'test', { password: 'plain', nonce: 'cipher', status: 500 });
  assert(!lines[0].includes('plain'));
  assert(!lines[0].includes('cipher'));
  assert(lines[0].includes('500'));
});
