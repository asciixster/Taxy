import { constants, createCipheriv, createHash, publicEncrypt, randomBytes, X509Certificate } from 'node:crypto';
import { readFileSync } from 'node:fs';

export class AtCryptoError extends Error {
  constructor(message) {
    super(message);
    this.name = 'AtCryptoError';
  }
}

export const RsaPaddingMode = Object.freeze({
  PKCS1_V1_5: 'pkcs1v15',
  OAEP_SHA1: 'oaepSha1',
  OAEP_SHA256: 'oaepSha256',
});

export function generateAes128SessionKey(randomSource = randomBytes) {
  const key = randomSource(16);
  if (!Buffer.isBuffer(key) || key.length !== 16) throw new AtCryptoError('CSPRNG did not return a 128-bit key');
  return key;
}

export function readAtPublicKey(certificatePath) {
  try {
    const certificate = new X509Certificate(readFileSync(certificatePath));
    const key = certificate.publicKey;
    if (key.asymmetricKeyType !== 'rsa') throw new Error('certificate key is not RSA');
    return key;
  } catch {
    throw new AtCryptoError('AT cipher certificate is invalid or unreadable');
  }
}

export function inspectAtCipherPublicKey(certificatePath) {
  let certificate;
  try { certificate = new X509Certificate(readFileSync(certificatePath)); }
  catch { throw new AtCryptoError('AT cipher certificate is invalid or unreadable'); }
  const key = certificate.publicKey;
  if (key.asymmetricKeyType !== 'rsa') throw new AtCryptoError('AT cipher certificate is invalid or unreadable');
  const spki = key.export({ type: 'spki', format: 'der' });
  const jwk = key.export({ format: 'jwk' });
  const modulus = Buffer.from(jwk.n, 'base64url');
  const details = key.asymmetricKeyDetails ?? {};
  const legacy = certificate.toLegacyObject();
  const keyUsage = certificate.keyUsage ?? legacy.ext_key_usage ?? [];
  const validFrom = new Date(certificate.validFrom);
  const validTo = new Date(certificate.validTo);
  const now = new Date();
  return Object.freeze({ readable: true, keyType: key.asymmetricKeyType,
    privateKeyPresent: false, fingerprintAlgorithm: 'SHA-256',
    certificateFingerprint: certificate.fingerprint256.replaceAll(':', '').toLowerCase(),
    publicKeyFingerprint: createHash('sha256').update(spki).digest('hex'),
    modulusFingerprint: createHash('sha256').update(modulus).digest('hex'),
    rsaKeySizeBits: details.modulusLength ?? legacy.bits ?? null,
    exponent: details.publicExponent?.toString() ?? null,
    issuerSummary: /(?:^|\n)CN=([^\n]+)/.exec(certificate.issuer)?.[1] ?? 'NOT_AVAILABLE',
    validFrom: validFrom.toISOString(), validTo: validTo.toISOString(),
    currentlyValid: now >= validFrom && now <= validTo,
    subjectKeyIdentifier: legacy.subjectKeyIdentifier ?? null,
    keyUsage: Object.freeze([...keyUsage]),
    clientAuthEkuPresent: keyUsage.includes('1.3.6.1.5.5.7.3.2'),
  });
}

function normalizeSha256(value) {
  const normalized = String(value ?? '').replaceAll(':', '').toLowerCase();
  if (!/^[a-f0-9]{64}$/.test(normalized)) {
    throw new AtCryptoError('Expected AT cipher certificate fingerprint is invalid');
  }
  return normalized;
}

export function assertAtCipherCertificateFingerprint(certificatePath, expectedFingerprint) {
  const metadata = inspectAtCipherPublicKey(certificatePath);
  if (metadata.certificateFingerprint !== normalizeSha256(expectedFingerprint)) {
    throw new AtCryptoError('AT cipher certificate fingerprint mismatch');
  }
  return metadata;
}

export function aes128EcbPkcs5Encrypt(plaintext, sessionKey) {
  if (!Buffer.isBuffer(sessionKey) || sessionKey.length !== 16) {
    throw new AtCryptoError('AES session key must contain exactly 128 bits');
  }
  const cipher = createCipheriv('aes-128-ecb', sessionKey, null);
  cipher.setAutoPadding(true);
  return Buffer.concat([cipher.update(Buffer.from(plaintext, 'utf8')), cipher.final()]);
}

export function rsaEncryptSessionKey(sessionKey, publicKey, mode) {
  if (!Object.values(RsaPaddingMode).includes(mode)) {
    throw new AtCryptoError('RSA_PADDING_UNCONFIRMED: no RSA padding mode was selected');
  }
  const options = mode === RsaPaddingMode.PKCS1_V1_5
    ? { key: publicKey, padding: constants.RSA_PKCS1_PADDING }
    : { key: publicKey, padding: constants.RSA_PKCS1_OAEP_PADDING, oaepHash: mode === RsaPaddingMode.OAEP_SHA256 ? 'sha256' : 'sha1' };
  return publicEncrypt(options, sessionKey);
}

export function buildEncryptedCredentials({ password, created, publicKey, sessionKey = generateAes128SessionKey(), rsaPaddingMode }) {
  if (!Object.values(RsaPaddingMode).includes(rsaPaddingMode)) {
    throw new AtCryptoError('RSA_PADDING_UNCONFIRMED: no RSA padding mode was selected');
  }
  const passwordCiphertext = aes128EcbPkcs5Encrypt(password, sessionKey).toString('base64');
  const createdCiphertext = aes128EcbPkcs5Encrypt(created, sessionKey).toString('base64');
  const nonce = rsaEncryptSessionKey(sessionKey, publicKey, rsaPaddingMode).toString('base64');
  return Object.freeze({ password: passwordCiphertext, nonce, created: createdCiphertext });
}
