import { createHash } from 'node:crypto';
import { existsSync } from 'node:fs';
import { spawnSync } from 'node:child_process';

export const PfxChainClassification = Object.freeze({
  COMPLETE: 'CHAIN_COMPLETE',
  INTERMEDIATE_MISSING: 'CHAIN_INTERMEDIATE_MISSING',
  UNKNOWN: 'CHAIN_UNKNOWN',
});

export function findOpenSsl() {
  const candidates = [
    process.env.OPENSSL_BIN,
    'openssl',
    'C:\\Program Files\\Git\\usr\\bin\\openssl.exe',
    'C:\\Program Files\\Git\\mingw64\\bin\\openssl.exe',
  ].filter(Boolean);
  return candidates.find((candidate) => spawnSync(candidate, ['version'], { stdio: 'ignore', windowsHide: true }).status === 0) || null;
}

function run(binary, args, { input = null, password = null } = {}) {
  const env = { ...process.env };
  if (password != null) env.TAXY_PFX_AUDIT_PASSWORD = password;
  const execution = spawnSync(binary, args, { input, env, encoding: null, windowsHide: true, maxBuffer: 2 * 1024 * 1024 });
  delete env.TAXY_PFX_AUDIT_PASSWORD;
  if (execution.status !== 0) {
    const error = new Error('Local PKCS#12 audit command failed');
    error.code = 'PFX_AUDIT_ERROR';
    throw error;
  }
  return execution.stdout;
}

function blocks(buffer, typePattern) {
  const text = buffer.toString('utf8');
  return [...text.matchAll(new RegExp(`-----BEGIN (${typePattern})-----[\\s\\S]*?-----END \\1-----`, 'g'))].map((match) => Buffer.from(match[0]));
}

function commonName(distinguishedName) {
  const match = distinguishedName?.match(/(?:^|[,/])\s*CN\s*=\s*([^,/]+)/i);
  if (!match) return 'NOT_AVAILABLE';
  return match[1].trim().replace(/\b\d{9}\b/g, '[REDACTED]').slice(0, 80);
}

function metadata(binary, certificate) {
  const output = run(binary, ['x509', '-noout', '-subject', '-issuer', '-ext', 'extendedKeyUsage,keyUsage,basicConstraints'], { input: certificate }).toString('utf8');
  const subject = output.match(/^subject\s*=\s*(.*)$/mi)?.[1] || '';
  const issuer = output.match(/^issuer\s*=\s*(.*)$/mi)?.[1] || '';
  const publicKey = run(binary, ['x509', '-pubkey', '-noout'], { input: certificate });
  const digest = createHash('sha256').update(publicKey).digest('hex');
  publicKey.fill(0);
  const keyUsage = [];
  if (/Digital Signature/i.test(output)) keyUsage.push('digitalSignature');
  if (/Key Encipherment/i.test(output)) keyUsage.push('keyEncipherment');
  if (/Certificate Sign/i.test(output)) keyUsage.push('keyCertSign');
  if (/CRL Sign/i.test(output)) keyUsage.push('cRLSign');
  return Object.freeze({
    subjectSummary: commonName(subject),
    issuerSummary: commonName(issuer),
    isCa: /CA\s*:\s*TRUE/i.test(output),
    clientAuthEku: /TLS Web Client Authentication|clientAuth/i.test(output),
    keyUsage: Object.freeze(keyUsage),
    publicKeyDigest: digest,
  });
}

export function auditPkcs12({ pfxPath, pfxPassword, opensslPath = findOpenSsl() }) {
  if (!pfxPath || !existsSync(pfxPath) || !pfxPassword || !opensslPath) {
    const error = new Error('Local PKCS#12 audit prerequisites are incomplete');
    error.code = 'PFX_AUDIT_CONFIGURATION_MISSING';
    throw error;
  }
  const certificatesOutput = run(opensslPath, ['pkcs12', '-in', pfxPath, '-nokeys', '-passin', 'env:TAXY_PFX_AUDIT_PASSWORD'], { password: pfxPassword });
  const privateKeysOutput = run(opensslPath, ['pkcs12', '-in', pfxPath, '-nocerts', '-nodes', '-passin', 'env:TAXY_PFX_AUDIT_PASSWORD'], { password: pfxPassword });
  const certificates = blocks(certificatesOutput, 'CERTIFICATE');
  const privateKeys = blocks(privateKeysOutput, '(?:ENCRYPTED )?PRIVATE KEY');
  certificatesOutput.fill(0);
  privateKeysOutput.fill(0);
  try {
    const certificateMetadata = certificates.map((certificate) => metadata(opensslPath, certificate));
    const client = certificateMetadata.find((certificate) => certificate.clientAuthEku && !certificate.isCa)
      || certificateMetadata.find((certificate) => !certificate.isCa)
      || null;
    const intermediates = certificateMetadata.filter((certificate) => certificate !== client && certificate.isCa);
    let privateKeyDigest = null;
    if (privateKeys[0]) {
      const publicKey = run(opensslPath, ['pkey', '-pubout'], { input: privateKeys[0] });
      privateKeyDigest = createHash('sha256').update(publicKey).digest('hex');
      publicKey.fill(0);
    }
    const matchingIntermediate = client && intermediates.find((certificate) => certificate.subjectSummary === client.issuerSummary);
    const selfIssued = client && client.subjectSummary === client.issuerSummary;
    const chainClassification = !client
      ? PfxChainClassification.UNKNOWN
      : (selfIssued || matchingIntermediate ? PfxChainClassification.COMPLETE : PfxChainClassification.INTERMEDIATE_MISSING);
    return Object.freeze({
      certificateCount: certificates.length,
      clientCertificatePresent: Boolean(client),
      privateKeyPresent: privateKeys.length > 0,
      intermediateCertificatesPresent: intermediates.length > 0,
      intermediateCertificateCount: intermediates.length,
      chainLength: client ? 1 + (matchingIntermediate ? 1 : 0) : 0,
      chainClassification,
      clientIssuerSummary: client?.issuerSummary || 'NOT_AVAILABLE',
      intermediateSubjectSummaries: Object.freeze(intermediates.map((certificate) => certificate.subjectSummary)),
      clientAuthEku: client?.clientAuthEku === true,
      keyUsage: client?.keyUsage || Object.freeze([]),
      publicKeyMatch: Boolean(client && privateKeyDigest && client.publicKeyDigest === privateKeyDigest),
    });
  } finally {
    for (const value of [...certificates, ...privateKeys]) value.fill(0);
  }
}
