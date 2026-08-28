import assert from 'node:assert/strict';
import test from 'node:test';
import { assertAuthenticatedConsultationEvidence, evidenceFor, EvidenceStatus, historicalEvidenceFor, protocolEvidence } from '../../src/evidence.mjs';
import { AtErrorCode } from '../../src/errors.mjs';

test('evidence registry has one unique record for every required protocol field', () => {
  const fields = protocolEvidence.map((item) => item.field);
  assert.equal(new Set(fields).size, fields.length);
  for (const field of ['endpoint.test.consultation', 'transport', 'clientCertificate', 'usernameFormat', 'usernameToken', 'aesAlgorithm', 'aesKeyLength', 'aesMode', 'aesPadding', 'rsaPadding', 'timestampFormat', 'timestampPrecision', 'passwordEncoding', 'nonceFormat', 'wsdl', 'namespace', 'operation', 'soapAction', 'requestRootElement']) {
    assert(evidenceFor(field), `missing ${field}`);
  }
});

test('officially unresolved fields never carry an inferred value', () => {
  for (const field of ['rsaPadding', 'timestampPrecision', 'passwordEncoding', 'wsdl', 'namespace', 'soapAction']) {
    const evidence = evidenceFor(field);
    assert.equal(evidence.status, EvidenceStatus.UNRESOLVED);
    assert.equal(evidence.value, null);
  }
});

test('authenticated consultation fails closed at RSA evidence gate', () => {
  assert.throws(assertAuthenticatedConsultationEvidence, (error) => error.code === AtErrorCode.RSA_PADDING_UNCONFIRMED);
});

test('primary username capability is historical evidence, not remote authorization evidence', () => {
  assert.equal(historicalEvidenceFor('usernameFormat.primary').status, EvidenceStatus.HISTORICAL_CODE_EVIDENCE);
  assert.match(historicalEvidenceFor('usernameFormat.primary').notes, /authorization.*not inferred/i);
});
