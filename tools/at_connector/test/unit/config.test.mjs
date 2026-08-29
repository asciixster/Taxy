import assert from 'node:assert/strict';
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import { AtConfigurationError, loadConfig, loadEnvLocalFallback } from '../../src/config.mjs';

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

test('.env.local fallback fills only missing process variables and never overwrites them', () => {
  const directory = mkdtempSync(join(tmpdir(), 'taxy-env-'));
  const path = join(directory, '.env.local');
  try {
    writeFileSync(path, 'AT_USERNAME=111111111\nAT_PASSWORD=local-secret\n', 'utf8');
    const loaded = loadEnvLocalFallback({ AT_USERNAME: '222222222' }, path);
    assert.equal(loaded.found, true);
    assert.equal(loaded.env.AT_USERNAME, '222222222');
    assert.equal(loaded.env.AT_PASSWORD, 'local-secret');
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
});

test('authenticated config rejects an empty PKCS#12 passphrase', () => {
  assert.throws(() => loadConfig({
    AT_ENV: 'test', AT_CLIENT_PFX_PATH: import.meta.filename, AT_CLIENT_PFX_PASSWORD: '',
    AT_CIPHER_CERT_PATH: import.meta.filename, AT_USERNAME: '123456789', AT_PASSWORD: 'secret',
  }, { requireAtCredentials: true }), /AT_CLIENT_PFX_PASSWORD/);
});
