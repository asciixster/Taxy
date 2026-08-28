export const AtErrorCode = Object.freeze({
  TLS_ERROR: 'TLS_ERROR',
  CLIENT_CERT_REJECTED: 'CLIENT_CERT_REJECTED',
  RSA_PADDING_UNCONFIRMED: 'RSA_PADDING_UNCONFIRMED',
  WSDL_UNRESOLVED: 'WSDL_UNRESOLVED',
  SOAP_CONTRACT_UNRESOLVED: 'SOAP_CONTRACT_UNRESOLVED',
  AUTH_CONFIGURATION_MISSING: 'AUTH_CONFIGURATION_MISSING',
  AUTH_REJECTED: 'AUTH_REJECTED',
  SUBUSER_PERMISSION_DENIED: 'SUBUSER_PERMISSION_DENIED',
  SOAP_FAULT: 'SOAP_FAULT',
  INVALID_RESPONSE: 'INVALID_RESPONSE',
  PRODUCTION_BLOCKED: 'PRODUCTION_BLOCKED',
  INVALID_SUBUSER_FORMAT: 'INVALID_SUBUSER_FORMAT',
  CUSTOMER_TAX_ID_MISMATCH: 'CUSTOMER_TAX_ID_MISMATCH',
  LIVE_TEST_DISABLED: 'LIVE_TEST_DISABLED',
  RATE_LIMIT_EXCEEDED: 'RATE_LIMIT_EXCEEDED',
});

export class AtConnectorError extends Error {
  constructor(code, message, { cause = null, details = null } = {}) {
    super(message, cause ? { cause } : undefined);
    this.name = 'AtConnectorError';
    this.code = code;
    this.details = details;
  }

  toJSON() {
    return { name: this.name, code: this.code, message: this.message, details: this.details };
  }
}
