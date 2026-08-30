import { createHash } from 'node:crypto';
import { buildFactIntWsEnvelope, serializeFactIntWsOperation } from './factintws.mjs';

function sha256(value) {
  return createHash('sha256').update(value).digest('hex');
}

function stableJson(value) {
  if (Array.isArray(value)) return `[${value.map(stableJson).join(',')}]`;
  if (value && typeof value === 'object') {
    return `{${Object.keys(value).sort().map((key) => `${JSON.stringify(key)}:${stableJson(value[key])}`).join(',')}}`;
  }
  return JSON.stringify(value);
}

export function sanitizeFactIntWsRequestForHash(xml) {
  return String(xml)
    .replace(/(<wss:Username>)[\s\S]*?(<\/wss:Username>)/, '$1USER$2')
    .replace(/(<wss:Password\s+Digest=")[^"]*(">)[\s\S]*?(<\/wss:Password>)/,
      '$1DIGEST$2PASSWORD$3')
    .replace(/(<wss:Nonce>)[\s\S]*?(<\/wss:Nonce>)/, '$1NONCE$2')
    .replace(/(<wss:Created>)[\s\S]*?(<\/wss:Created>)/, '$1CREATED$2')
    .replace(/(<app:Nif>)[\s\S]*?(<\/app:Nif>)/, '$1NIF$2');
}

export function buildFactIntWsLiveMetadata({ cipherCertificate, clientCertificateFingerprint,
  endpoint, tlsOptions, contract, xml }) {
  const requiredHashes = [cipherCertificate?.certificateFingerprint,
    cipherCertificate?.publicKeyFingerprint, clientCertificateFingerprint];
  if (requiredHashes.some((value) => !/^[a-f0-9]{64}$/.test(String(value ?? '')))) {
    throw new TypeError('Live metadata requires explicit SHA-256 certificate fingerprints');
  }
  const sanitizedRequest = sanitizeFactIntWsRequestForHash(xml);
  return Object.freeze({
    atCipherCertificateSha256: cipherCertificate.certificateFingerprint,
    atCipherSpkiSha256: cipherCertificate.publicKeyFingerprint,
    atCipherRsaKeySize: cipherCertificate.rsaKeySizeBits,
    atCipherValid: cipherCertificate.currentlyValid,
    clientIdentityCertificateSha256: clientCertificateFingerprint,
    endpoint,
    tlsConfigSha256: sha256(stableJson({ rejectUnauthorized: true, ...tlsOptions })),
    serializerSha256: sha256(`${buildFactIntWsEnvelope.toString()}\n${serializeFactIntWsOperation.toString()}`),
    requestContractSha256: sha256(stableJson(contract)),
    sanitizedRequestSha256: sha256(sanitizedRequest),
    sanitizedRequestByteLength: Buffer.byteLength(sanitizedRequest, 'utf8'),
  });
}
