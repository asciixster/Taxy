import assert from 'node:assert/strict';
import test from 'node:test';
import { AtConnectorError, AtErrorCode } from '../../src/errors.mjs';

test('error taxonomy exposes every stable connector code', () => {
  assert.deepEqual(Object.values(AtErrorCode), [
    'TLS_ERROR', 'CLIENT_CERT_REJECTED', 'RSA_PADDING_UNCONFIRMED', 'WSDL_UNRESOLVED',
    'SOAP_CONTRACT_UNRESOLVED', 'AUTH_CONFIGURATION_MISSING', 'AUTH_REJECTED',
    'SUBUSER_PERMISSION_DENIED', 'SOAP_FAULT', 'INVALID_RESPONSE', 'PRODUCTION_BLOCKED',
  ]);
});

test('structured errors serialize without their cause or secret stack', () => {
  const error = new AtConnectorError(AtErrorCode.AUTH_REJECTED, 'Authentication rejected', { cause: new Error('secret-bearing-low-level-message') });
  const serialized = JSON.stringify(error);
  assert(!serialized.includes('secret-bearing-low-level-message'));
  assert(serialized.includes('AUTH_REJECTED'));
});
