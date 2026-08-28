import assert from 'node:assert/strict';
import { createSecureContext } from 'node:tls';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import { AtSoapClient } from '../../src/client.mjs';
import { loadConfig } from '../../src/config.mjs';
import { readAtPublicKey } from '../../src/crypto.mjs';

const enabled = process.env.AT_LOCAL_INTEGRATION === '1';

test('loads the supplied PKCS#12 entirely in process memory', { skip: !enabled }, () => {
  const config = loadConfig(process.env);
  assert.doesNotThrow(() => createSecureContext({ pfx: readFileSync(config.pfxPath), passphrase: config.pfxPassword }));
});

test('rejects an incorrect PKCS#12 password', { skip: !enabled }, () => {
  const config = loadConfig(process.env);
  assert.throws(() => createSecureContext({ pfx: readFileSync(config.pfxPath), passphrase: `${config.pfxPassword}-wrong` }));
});

test('loads the supplied AT cipher certificate as an RSA public key', { skip: !enabled }, () => {
  const config = loadConfig(process.env, { requireAtCredentials: false });
  assert.equal(readAtPublicKey(config.cipherCertificatePath).asymmetricKeyType, 'rsa');
});

test('establishes mTLS and receives a real response from AT test', { skip: !enabled }, async () => {
  const config = loadConfig(process.env);
  const result = await new AtSoapClient(config).probeConsultation();
  assert.equal(result.transport.tls.authorized, true);
  assert.equal(typeof result.transport.statusCode, 'number');
  assert(result.transport.body.length > 0);
});
