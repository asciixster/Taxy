import assert from 'node:assert/strict';
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { after, before, test } from 'node:test';
import { auditPkcs12, findOpenSsl, PfxChainClassification } from '../../src/pfx-audit.mjs';

const password = 'synthetic-chain-passphrase';
let directory;
let openssl;
let missingChainPfx;
let completeChainPfx;
let invalidChainPfx;

function run(args) {
  const execution = spawnSync(openssl, args, { stdio: 'ignore', windowsHide: true });
  assert.equal(execution.status, 0, `Synthetic chain generation failed: ${args[0]}`);
}

before(() => {
  openssl = findOpenSsl();
  assert(openssl, 'OpenSSL is required for ephemeral PKCS#12 chain fixtures');
  directory = mkdtempSync(join(tmpdir(), 'taxy-synthetic-chain-'));
  const rootKey = join(directory, 'root.key');
  const rootCertificate = join(directory, 'root.crt');
  const intermediateKey = join(directory, 'intermediate.key');
  const intermediateCsr = join(directory, 'intermediate.csr');
  const intermediateCertificate = join(directory, 'intermediate.crt');
  const clientKey = join(directory, 'client.key');
  const clientCsr = join(directory, 'client.csr');
  const clientCertificate = join(directory, 'client.crt');
  const unrelatedKey = join(directory, 'unrelated.key');
  const unrelatedCertificate = join(directory, 'unrelated.crt');
  const intermediateExtensions = join(directory, 'intermediate.ext');
  const clientExtensions = join(directory, 'client.ext');
  missingChainPfx = join(directory, 'client-key-only-chain.pfx');
  completeChainPfx = join(directory, 'client-with-intermediate.pfx');
  invalidChainPfx = join(directory, 'client-with-wrong-ca.pfx');

  writeFileSync(intermediateExtensions, 'basicConstraints=critical,CA:TRUE,pathlen:0\nkeyUsage=critical,keyCertSign,cRLSign\nsubjectKeyIdentifier=hash\nauthorityKeyIdentifier=keyid,issuer\n');
  writeFileSync(clientExtensions, 'basicConstraints=critical,CA:FALSE\nkeyUsage=critical,digitalSignature,keyEncipherment\nextendedKeyUsage=clientAuth\nsubjectKeyIdentifier=hash\nauthorityKeyIdentifier=keyid,issuer\n');
  run(['req', '-x509', '-newkey', 'rsa:2048', '-nodes', '-keyout', rootKey, '-out', rootCertificate, '-days', '1', '-subj', '/CN=Synthetic Root', '-addext', 'basicConstraints=critical,CA:TRUE', '-addext', 'keyUsage=critical,keyCertSign,cRLSign']);
  run(['req', '-new', '-newkey', 'rsa:2048', '-nodes', '-keyout', intermediateKey, '-out', intermediateCsr, '-subj', '/CN=Synthetic Intermediate']);
  run(['x509', '-req', '-in', intermediateCsr, '-CA', rootCertificate, '-CAkey', rootKey, '-CAcreateserial', '-out', intermediateCertificate, '-days', '1', '-extfile', intermediateExtensions]);
  run(['req', '-new', '-newkey', 'rsa:2048', '-nodes', '-keyout', clientKey, '-out', clientCsr, '-subj', '/CN=Synthetic Client']);
  run(['x509', '-req', '-in', clientCsr, '-CA', intermediateCertificate, '-CAkey', intermediateKey, '-CAcreateserial', '-out', clientCertificate, '-days', '1', '-extfile', clientExtensions]);
  run(['req', '-x509', '-newkey', 'rsa:2048', '-nodes', '-keyout', unrelatedKey, '-out', unrelatedCertificate, '-days', '1', '-subj', '/CN=Synthetic Unrelated CA', '-addext', 'basicConstraints=critical,CA:TRUE', '-addext', 'keyUsage=critical,keyCertSign,cRLSign']);
  run(['pkcs12', '-export', '-out', missingChainPfx, '-inkey', clientKey, '-in', clientCertificate, '-passout', `pass:${password}`]);
  run(['pkcs12', '-export', '-out', completeChainPfx, '-inkey', clientKey, '-in', clientCertificate, '-certfile', intermediateCertificate, '-passout', `pass:${password}`]);
  run(['pkcs12', '-export', '-out', invalidChainPfx, '-inkey', clientKey, '-in', clientCertificate, '-certfile', unrelatedCertificate, '-passout', `pass:${password}`]);
});

after(() => {
  if (directory) rmSync(directory, { recursive: true, force: true });
});

test('PKCS#12 with client certificate and matching key detects missing intermediate', () => {
  const audit = auditPkcs12({ pfxPath: missingChainPfx, pfxPassword: password, opensslPath: openssl });
  assert.equal(audit.certificateCount, 1);
  assert.equal(audit.clientCertificatePresent, true);
  assert.equal(audit.privateKeyPresent, true);
  assert.equal(audit.publicKeyMatch, true);
  assert.equal(audit.intermediateCertificatesPresent, false);
  assert.equal(audit.chainLength, 1);
  assert.equal(audit.chainClassification, PfxChainClassification.INTERMEDIATE_MISSING);
});

test('PKCS#12 with client, key and matching intermediate has a complete chain', () => {
  const audit = auditPkcs12({ pfxPath: completeChainPfx, pfxPassword: password, opensslPath: openssl });
  assert.equal(audit.certificateCount, 2);
  assert.equal(audit.clientCertificatePresent, true);
  assert.equal(audit.privateKeyPresent, true);
  assert.equal(audit.intermediateCertificatesPresent, true);
  assert.equal(audit.intermediateCertificateCount, 1);
  assert.equal(audit.chainLength, 2);
  assert.equal(audit.chainClassification, PfxChainClassification.COMPLETE);
  assert.equal(audit.clientIssuerSummary, 'Synthetic Intermediate');
  assert.equal(audit.clientAuthEku, true);
  assert(audit.keyUsage.includes('digitalSignature'));
});

test('unrelated CA inside PKCS#12 does not make the chain valid', () => {
  const audit = auditPkcs12({ pfxPath: invalidChainPfx, pfxPassword: password, opensslPath: openssl });
  assert.equal(audit.intermediateCertificatesPresent, true);
  assert.equal(audit.chainLength, 1);
  assert.equal(audit.chainClassification, PfxChainClassification.INTERMEDIATE_MISSING);
});

test('audit result redacts certificate bodies, secrets, serials and filesystem paths', () => {
  const safe = JSON.stringify(auditPkcs12({ pfxPath: completeChainPfx, pfxPassword: password, opensslPath: openssl }));
  assert(!safe.includes(password));
  assert(!safe.includes(directory));
  assert(!safe.includes('BEGIN CERTIFICATE'));
  assert(!safe.toLowerCase().includes('serial'));
  assert(!safe.includes('PRIVATE KEY'));
});
