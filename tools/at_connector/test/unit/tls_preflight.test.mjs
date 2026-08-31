import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import {
  inspectPfxReadiness, PfxPreflightClassification, resolveOpenSslPath,
  sanitizeTlsDiagnostic, tlsFailureDiagnostic,
} from '../../src/tls_preflight.mjs';

const openssl = resolveOpenSslPath();

function run(args, cwd) {
  execFileSync(openssl, args, { cwd, stdio: 'ignore', windowsHide: true });
}

function syntheticPfx({ includeChain = true, includeRoot = true, clientAuth = true } = {}) {
  const dir = mkdtempSync(join(tmpdir(), 'taxy-pfx-test-'));
  run(['req', '-x509', '-newkey', 'rsa:2048', '-nodes', '-keyout', 'root.key', '-out', 'root.crt', '-days', '2', '-subj', '/CN=Synthetic Root',
    '-addext', 'basicConstraints=critical,CA:TRUE', '-addext', 'keyUsage=critical,keyCertSign,cRLSign'], dir);
  run(['req', '-newkey', 'rsa:2048', '-nodes', '-keyout', 'intermediate.key', '-out', 'intermediate.csr', '-subj', '/CN=Synthetic Intermediate'], dir);
  writeFileSync(join(dir, 'ca.ext'), 'basicConstraints=critical,CA:TRUE\nkeyUsage=critical,keyCertSign,cRLSign\nsubjectKeyIdentifier=hash\nauthorityKeyIdentifier=keyid,issuer\n');
  run(['x509', '-req', '-in', 'intermediate.csr', '-CA', 'root.crt', '-CAkey', 'root.key', '-CAcreateserial', '-out', 'intermediate.crt', '-days', '2', '-extfile', 'ca.ext'], dir);
  run(['req', '-newkey', 'rsa:2048', '-nodes', '-keyout', 'client.key', '-out', 'client.csr', '-subj', '/CN=Synthetic Client'], dir);
  writeFileSync(join(dir, 'client.ext'), `basicConstraints=critical,CA:FALSE\nkeyUsage=critical,digitalSignature,keyEncipherment\n${clientAuth ? 'extendedKeyUsage=clientAuth\n' : ''}subjectKeyIdentifier=hash\nauthorityKeyIdentifier=keyid,issuer\n`);
  run(['x509', '-req', '-in', 'client.csr', '-CA', 'intermediate.crt', '-CAkey', 'intermediate.key', '-CAcreateserial', '-out', 'client.crt', '-days', '2', '-extfile', 'client.ext'], dir);
  const args = ['pkcs12', '-export', '-out', 'client.pfx', '-inkey', 'client.key', '-in', 'client.crt', '-passout', 'pass:synthetic-password'];
  if (includeChain) {
    const root = includeRoot ? `\n${readFileSync(join(dir, 'root.crt'), 'utf8')}` : '';
    writeFileSync(join(dir, 'chain.pem'), `${readFileSync(join(dir, 'intermediate.crt'), 'utf8')}${root}`);
    args.push('-certfile', 'chain.pem');
  }
  run(args, dir);
  return { dir, pfxPath: join(dir, 'client.pfx'), password: 'synthetic-password' };
}

test('full synthetic client chain is locally ready for TLS client auth', { skip: !openssl }, () => {
  const fixture = syntheticPfx();
  try {
    const result = inspectPfxReadiness({ ...fixture, pfxPassword: fixture.password, opensslPath: openssl });
    assert.equal(result.classification, PfxPreflightClassification.READY);
    assert.equal(result.pfxOpened, true);
    assert.equal(result.privateKeyPresent, true);
    assert.equal(result.certificateCount, 3);
    assert.equal(result.intermediatePresent, true);
    assert.equal(result.chainClassification, 'CHAIN_VALID');
    assert.equal(result.ekuClientAuth, true);
    assert.equal(result.caValidation, 'VALID');
  } finally { rmSync(fixture.dir, { recursive: true, force: true }); }
});

test('client chain with leaf and intermediate is ready without bundling the root', { skip: !openssl }, () => {
  const fixture = syntheticPfx({ includeRoot: false });
  try {
    const result = inspectPfxReadiness({ ...fixture, pfxPassword: fixture.password, opensslPath: openssl });
    assert.equal(result.classification, PfxPreflightClassification.READY);
    assert.equal(result.certificateCount, 2);
    assert.equal(result.chainClassification, 'CHAIN_VALID');
    assert.equal(result.ekuClientAuth, true);
  } finally { rmSync(fixture.dir, { recursive: true, force: true }); }
});

test('missing intermediate is detected and fails closed', { skip: !openssl }, () => {
  const fixture = syntheticPfx({ includeChain: false });
  try {
    const result = inspectPfxReadiness({ ...fixture, pfxPassword: fixture.password, opensslPath: openssl });
    assert.notEqual(result.classification, PfxPreflightClassification.READY);
    assert.equal(result.certificateCount, 1);
    assert.equal(result.intermediatePresent, false);
    assert.equal(result.chainClassification, 'CHAIN_INTERMEDIATE_MISSING');
  } finally { rmSync(fixture.dir, { recursive: true, force: true }); }
});

test('certificate without explicit clientAuth EKU fails closed', { skip: !openssl }, () => {
  const fixture = syntheticPfx({ clientAuth: false });
  try {
    const result = inspectPfxReadiness({ ...fixture, pfxPassword: fixture.password, opensslPath: openssl });
    assert.equal(result.ekuClientAuth, false);
    assert.notEqual(result.classification, PfxPreflightClassification.READY);
  } finally { rmSync(fixture.dir, { recursive: true, force: true }); }
});

test('invalid password is classified without exposing it', { skip: !openssl }, () => {
  const fixture = syntheticPfx();
  try {
    const result = inspectPfxReadiness({ pfxPath: fixture.pfxPath, pfxPassword: 'wrong-secret', opensslPath: openssl });
    assert.equal(result.classification, PfxPreflightClassification.PASSWORD_INVALID);
    assert(!JSON.stringify(result).includes('wrong-secret'));
  } finally { rmSync(fixture.dir, { recursive: true, force: true }); }
});

test('TLS diagnostics expose stage and code while redacting sensitive material', () => {
  const error = Object.assign(new Error('NIF 123456789 password=top-secret bad record mac'), { code: 'ERR_SSL_BAD_RECORD_MAC' });
  const result = tlsFailureDiagnostic(error, 'tls-handshake');
  assert.equal(result.tlsErrorCode, 'ERR_SSL_BAD_RECORD_MAC');
  assert.equal(result.tlsStage, 'tls-handshake');
  assert(!result.tlsErrorReasonSanitized.includes('123456789'));
  assert(!result.tlsErrorReasonSanitized.includes('top-secret'));
  assert.match(result.tlsErrorReasonSanitized, /REDACTED/);
  assert(!sanitizeTlsDiagnostic('-----BEGIN PRIVATE KEY----- secret -----END PRIVATE KEY-----').includes('secret'));
});
