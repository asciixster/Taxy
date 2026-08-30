import assert from 'node:assert/strict';
import test from 'node:test';
import { buildFactIntWsEnvelope, FACTINTWS_ENDPOINT_8443,
  factIntWsHttpContract, factIntWsTlsOptions } from '../../src/factintws.mjs';
import { buildFactIntWsLiveMetadata,
  sanitizeFactIntWsRequestForHash } from '../../src/factintws_live_metadata.mjs';

const hashA = 'a'.repeat(64);
const hashB = 'b'.repeat(64);
const xml = ({ username = '111111111', nif = '111111111', password = 'secret-a',
  digest = 'digest-a', nonce = 'nonce-a', created = '2026-08-30T12:00:00.000Z' } = {}) =>
  buildFactIntWsEnvelope({ username,
    credentials: { encryptedPassword: password, encryptedDigest: digest,
      encryptedNonce: nonce, created },
    input: { nif, year: '2026',
      channel: { system: 'A', version: 'Android SDK: 35 (15)' } } });

test('live metadata contains every mandatory reproducibility fingerprint before transport', () => {
  const body = xml();
  const base = factIntWsHttpContract('EcraInicial', FACTINTWS_ENDPOINT_8443);
  const contract = { ...base, headers: { ...base.headers,
    'Content-Length': Buffer.byteLength(body, 'utf8') } };
  const metadata = buildFactIntWsLiveMetadata({
    cipherCertificate: { certificateFingerprint: hashA,
      publicKeyFingerprint: hashB, rsaKeySizeBits: 4096, currentlyValid: true },
    clientCertificateFingerprint: 'c'.repeat(64), endpoint: FACTINTWS_ENDPOINT_8443,
    tlsOptions: factIntWsTlsOptions(), contract, xml: body,
  });
  for (const key of ['atCipherCertificateSha256', 'atCipherSpkiSha256',
    'clientIdentityCertificateSha256', 'tlsConfigSha256', 'serializerSha256',
    'requestContractSha256', 'sanitizedRequestSha256']) {
    assert.match(metadata[key], /^[a-f0-9]{64}$/);
  }
  assert.equal(metadata.endpoint, FACTINTWS_ENDPOINT_8443);
  assert.equal(metadata.atCipherRsaKeySize, 4096);
  assert.equal(metadata.atCipherValid, true);
});

test('sanitized request hash is stable across real credential material', () => {
  const first = sanitizeFactIntWsRequestForHash(xml());
  const second = sanitizeFactIntWsRequestForHash(xml({ username: '222222222',
    nif: '222222222', password: 'secret-b', digest: 'digest-b', nonce: 'nonce-b',
    created: '2026-08-30T12:00:01.000Z' }));
  assert.equal(first, second);
  for (const secret of ['111111111', '222222222', 'secret-a', 'secret-b',
    'digest-a', 'digest-b', 'nonce-a', 'nonce-b']) {
    assert.equal(first.includes(secret), false);
  }
});

test('missing certificate fingerprints block live metadata generation', () => {
  assert.throws(() => buildFactIntWsLiveMetadata({ cipherCertificate: {},
    clientCertificateFingerprint: null, endpoint: FACTINTWS_ENDPOINT_8443,
    tlsOptions: {}, contract: {}, xml: xml() }), /explicit SHA-256/);
});
