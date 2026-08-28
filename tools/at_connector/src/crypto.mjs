import { constants, createCipheriv, publicEncrypt, randomBytes, X509Certificate } from 'node:crypto';
import { readFileSync } from 'node:fs';

export class AtCryptoError extends Error {
  constructor(message) {
    super(message);
    this.name = 'AtCryptoError';
  }
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

export function aes128EcbPkcs5Encrypt(plaintext, sessionKey) {
  if (!Buffer.isBuffer(sessionKey) || sessionKey.length !== 16) {
    throw new AtCryptoError('AES session key must contain exactly 128 bits');
  }
  const cipher = createCipheriv('aes-128-ecb', sessionKey, null);
  cipher.setAutoPadding(true);
  return Buffer.concat([cipher.update(Buffer.from(plaintext, 'utf8')), cipher.final()]);
}

export function buildEncryptedCredentials({ password, created, publicKey, sessionKey = randomBytes(16), rsaPadding }) {
  if (rsaPadding !== 'RSA_PKCS1_PADDING_CONFIRMED') {
    throw new AtCryptoError('Authenticated requests are fail-closed: the official e-Fatura manual does not specify RSA padding');
  }
  const passwordCiphertext = aes128EcbPkcs5Encrypt(password, sessionKey).toString('base64');
  const createdCiphertext = aes128EcbPkcs5Encrypt(created, sessionKey).toString('base64');
  const nonce = publicEncrypt({ key: publicKey, padding: constants.RSA_PKCS1_PADDING }, sessionKey).toString('base64');
  return Object.freeze({ password: passwordCiphertext, nonce, created: createdCiphertext });
}
