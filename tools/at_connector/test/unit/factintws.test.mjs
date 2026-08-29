import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import { AtErrorCode } from '../../src/errors.mjs';
import {
  assessFactIntWsReadiness, buildFactIntWsEnvelope, FACTINTWS_ACTOR,
  FACTINTWS_AUTH_NAMESPACE, FACTINTWS_ENDPOINT_443, FACTINTWS_ENDPOINT_8443,
  FACTINTWS_NAMESPACE, FACTINTWS_OPERATION, FACTINTWS_PLANNED_CLIENT_IDENTITY,
  FACTINTWS_WSSE_NAMESPACE, factIntWsProtocolEvidence, FactIntWsEvidenceStatus,
  runFactIntWsFeasibility, sanitizedFactIntWsResearchEnvelope,
} from '../../src/factintws.mjs';
import { redact } from '../../src/redaction.mjs';

test('FactIntWS structural constants remain historical evidence, never runtime evidence', () => {
  assert.equal(FACTINTWS_ENDPOINT_443, 'https://servicos.portaldasfinancas.gov.pt:443/mobile/a4/factintws/ws');
  assert.equal(FACTINTWS_ENDPOINT_8443, 'https://servicos.portaldasfinancas.gov.pt:8443/mobile/a4/factintws/ws');
  assert.equal(FACTINTWS_NAMESPACE, 'http://factemi.at.min_financas.pt/factintws');
  assert.equal(FACTINTWS_WSSE_NAMESPACE, 'http://schemas.xmlsoap.org/ws/2002/12/secext');
  assert.equal(FACTINTWS_AUTH_NAMESPACE, 'http://at.pt/wsp/auth');
  assert.equal(FACTINTWS_ACTOR, 'http://at.pt/actor/SPA');
  assert.equal(FACTINTWS_OPERATION, 'ecraInicialF');
  for (const field of ['endpoint443', 'soapVersion', 'serviceNamespace', 'wsSecurityNamespace', 'authNamespace', 'actor', 'usernameTokenFields', 'operationName']) {
    assert.equal(factIntWsProtocolEvidence[field].status, FactIntWsEvidenceStatus.HISTORICAL);
  }
});

test('digest, nonce, Created and operation schema stay explicitly unknown', () => {
  for (const field of [
    'passwordDigestFormula', 'passwordDigestInputOrder', 'passwordDigestEncoding',
    'nonceByteLength', 'nonceGeneration', 'nonceXmlEncoding',
    'createdTimezone', 'createdPrecision', 'createdFormat',
    'operationRootElement', 'operationRequiredBody',
  ]) {
    assert.equal(factIntWsProtocolEvidence[field].status, FactIntWsEvidenceStatus.UNKNOWN);
    assert.equal(factIntWsProtocolEvidence[field].value, null);
  }
});

test('readiness fails closed before any transport call', async () => {
  let calls = 0;
  const result = await runFactIntWsFeasibility({ transport: async () => { calls += 1; } });
  assert.equal(result.ready, false);
  assert.equal(result.networkRequests, 0);
  assert.equal(result.classification, AtErrorCode.FACTINTWS_DIGEST_NOT_READY);
  assert.equal(calls, 0);
  assert.equal(assessFactIntWsReadiness().ready, false);
  assert.throws(buildFactIntWsEnvelope, (error) => error.code === AtErrorCode.FACTINTWS_DIGEST_NOT_READY);
});

test('sanitized research envelope records known structure without inventing live values or schema', () => {
  const xml = sanitizedFactIntWsResearchEnvelope();
  assert(xml.includes(`xmlns:wss="${FACTINTWS_WSSE_NAMESPACE}"`));
  assert(xml.includes(`xmlns:at="${FACTINTWS_AUTH_NAMESPACE}"`));
  assert(xml.includes(`xmlns:app="${FACTINTWS_NAMESPACE}"`));
  assert(xml.includes(`S:actor="${FACTINTWS_ACTOR}"`));
  for (const field of ['UsernameToken', 'Username', 'Password', 'Nonce', 'Created']) assert(xml.includes(field));
  assert(xml.includes('[UNKNOWN_ECRAINICIALF_ROOT]'));
  assert(xml.includes('[UNKNOWN_REQUIRED_BODY]'));
  assert(!/\b\d{9}\b/.test(xml));
});

test('FactIntWS research never references or permits official-app identity material', () => {
  assert.equal(FACTINTWS_PLANNED_CLIENT_IDENTITY, 'TesteWebservices.pfx');
  const source = readFileSync(new URL('../../src/factintws.mjs', import.meta.url), 'utf8');
  assert.equal(/official[-_ ]app.*\.(?:pfx|p12|pem|key)/i.test(source), false);
  assert.equal(/PKCS#?8/i.test(source), false);
});

test('FactIntWS credential derivatives are redacted structurally', () => {
  const safe = redact({ username: '123456789', passwordDigest: 'digest-value', nonce: 'nonce-value', created: 'timestamp-value' });
  assert.equal(safe.username, '[REDACTED_IDENTIFIER]');
  assert.equal(safe.passwordDigest, '[REDACTED]');
  assert.equal(safe.nonce, '[REDACTED]');
  assert.equal(safe.created, '[REDACTED]');
});
