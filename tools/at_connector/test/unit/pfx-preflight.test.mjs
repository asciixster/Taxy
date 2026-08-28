import assert from 'node:assert/strict';
import { existsSync, mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { after, before, test } from 'node:test';
import { PfxPreflightClassification, preflightPkcs12 } from '../../src/pfx-preflight.mjs';

const syntheticPassword = 'synthetic-test-passphrase';
let directory;
let validPfx;
let certificateOnlyPfx;

function findOpenSsl() {
  const candidates = [
    process.env.OPENSSL_BIN,
    'openssl',
    'C:\\Program Files\\Git\\usr\\bin\\openssl.exe',
    'C:\\Program Files\\Git\\mingw64\\bin\\openssl.exe',
  ].filter(Boolean);
  return candidates.find((candidate) => spawnSync(candidate, ['version'], { stdio: 'ignore', windowsHide: true }).status === 0);
}

function runOpenSsl(binary, arguments_) {
  const execution = spawnSync(binary, arguments_, { stdio: 'ignore', windowsHide: true });
  assert.equal(execution.status, 0, `Synthetic OpenSSL fixture generation failed: ${arguments_[0]}`);
}

before(() => {
  const openssl = findOpenSsl();
  assert(openssl, 'OpenSSL is required to generate ephemeral synthetic PKCS#12 test fixtures');
  directory = mkdtempSync(join(tmpdir(), 'taxy-synthetic-pfx-'));
  const key = join(directory, 'synthetic-key.pem');
  const certificate = join(directory, 'synthetic-certificate.pem');
  validPfx = join(directory, 'synthetic-valid.pfx');
  certificateOnlyPfx = join(directory, 'synthetic-certificate-only.pfx');
  runOpenSsl(openssl, ['req', '-x509', '-newkey', 'rsa:2048', '-keyout', key, '-out', certificate, '-days', '1', '-nodes', '-subj', '/CN=Synthetic Taxy Test']);
  runOpenSsl(openssl, ['pkcs12', '-export', '-out', validPfx, '-inkey', key, '-in', certificate, '-passout', `pass:${syntheticPassword}`]);
  runOpenSsl(openssl, ['pkcs12', '-export', '-nokeys', '-out', certificateOnlyPfx, '-in', certificate, '-passout', `pass:${syntheticPassword}`]);
});

after(() => {
  if (directory) rmSync(directory, { recursive: true, force: true });
});

test('missing PFX path fails before reading or networking', () => {
  assert.deepEqual(preflightPkcs12({ pfxPath: join(tmpdir(), 'not-present.pfx'), pfxPassword: syntheticPassword }), {
    pfxFileFound: false, pfxOpened: false, certificatePresent: false, privateKeyPresent: false,
    classification: PfxPreflightClassification.FILE_NOT_FOUND,
  });
});

test('missing PFX password does not attempt an empty passphrase', () => {
  let opens = 0;
  const result = preflightPkcs12({ pfxPath: validPfx, pfxPassword: '' }, { createSecureContext: () => { opens += 1; } });
  assert.equal(result.classification, PfxPreflightClassification.PASSWORD_MISSING);
  assert.equal(result.pfxFileFound, true);
  assert.equal(opens, 0);
});

test('invalid PFX password is classified without exposing the supplied value', () => {
  const result = preflightPkcs12({ pfxPath: validPfx, pfxPassword: 'definitely-invalid-synthetic-passphrase' });
  assert.equal(result.classification, PfxPreflightClassification.PASSWORD_INVALID);
  assert.equal(result.pfxOpened, false);
  const safe = JSON.stringify(result);
  assert(!safe.includes('definitely-invalid'));
  assert(!safe.includes(validPfx));
});

test('valid synthetic PFX proves certificate and private key presence', () => {
  const result = preflightPkcs12({ pfxPath: validPfx, pfxPassword: syntheticPassword });
  assert.deepEqual(result, {
    pfxFileFound: true, pfxOpened: true, certificatePresent: true, privateKeyPresent: true,
    classification: PfxPreflightClassification.READY,
  });
});

test('synthetic certificate without private key fails closed', () => {
  const result = preflightPkcs12({ pfxPath: certificateOnlyPfx, pfxPassword: syntheticPassword });
  assert.deepEqual(result, {
    pfxFileFound: true, pfxOpened: true, certificatePresent: true, privateKeyPresent: false,
    classification: PfxPreflightClassification.PRIVATE_KEY_MISSING,
  });
});

test('unknown parse errors contain only the stable classification', () => {
  const result = preflightPkcs12({ pfxPath: 'synthetic-path', pfxPassword: syntheticPassword }, {
    existsSync: () => true,
    readFileSync: () => Buffer.from('synthetic-not-a-pfx'),
    createSecureContext: () => { throw new Error('ASN.1 failed for /secret/path and CN=Sensitive Subject'); },
  });
  assert.equal(result.classification, PfxPreflightClassification.PARSE_ERROR);
  const safe = JSON.stringify(result);
  assert(!safe.includes('secret/path'));
  assert(!safe.includes('Sensitive Subject'));
  assert(!safe.includes(syntheticPassword));
});

test('synthetic fixtures are ephemeral and no real certificate path is used', () => {
  assert.equal(existsSync(validPfx), true);
  assert(validPfx.startsWith(tmpdir()));
  assert(certificateOnlyPfx.startsWith(tmpdir()));
});
