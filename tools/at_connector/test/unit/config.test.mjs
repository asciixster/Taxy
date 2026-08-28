import assert from 'node:assert/strict';
import test from 'node:test';
import { AtConfigurationError, loadConfig } from '../../src/config.mjs';

test('rejects missing PFX path', () => {
  assert.throws(() => loadConfig({ AT_ENV: 'test' }), AtConfigurationError);
});

test('rejects a missing PFX file', () => {
  assert.throws(() => loadConfig({ AT_ENV: 'test', AT_PFX_PATH: 'not-present.pfx', AT_PFX_PASSWORD: 'hidden' }), /does not exist/);
});

test('rejects unknown environments', () => {
  assert.throws(() => loadConfig({ AT_ENV: 'staging' }), /test or production/);
});

test('production execution is fail-closed', () => {
  assert.throws(() => loadConfig({ AT_ENV: 'production' }), /disabled/);
});

test('authenticated configuration requires every credential', () => {
  assert.throws(() => loadConfig({ AT_ENV: 'test', AT_PFX_PATH: import.meta.filename, AT_PFX_PASSWORD: 'hidden' }, { requireAtCredentials: true }), /AT_CIPHER_CERT_PATH/);
});
