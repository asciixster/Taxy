import { AtConnectorError, AtErrorCode } from './errors.mjs';

export const FactIntWsEvidenceStatus = Object.freeze({
  HISTORICAL: 'HISTORICAL_CODE_EVIDENCE_FROM_OFFICIAL_APP',
  RUNTIME: 'RUNTIME_BEHAVIOR_CONFIRMED',
  INFERENCE: 'INFERENCE',
  UNKNOWN: 'UNKNOWN',
});

export const FACTINTWS_ENDPOINT_443 = 'https://servicos.portaldasfinancas.gov.pt:443/mobile/a4/factintws/ws';
export const FACTINTWS_ENDPOINT_8443 = 'https://servicos.portaldasfinancas.gov.pt:8443/mobile/a4/factintws/ws';
export const FACTINTWS_NAMESPACE = 'http://factemi.at.min_financas.pt/factintws';
export const FACTINTWS_WSSE_NAMESPACE = 'http://schemas.xmlsoap.org/ws/2002/12/secext';
export const FACTINTWS_AUTH_NAMESPACE = 'http://at.pt/wsp/auth';
export const FACTINTWS_ACTOR = 'http://at.pt/actor/SPA';
export const FACTINTWS_OPERATION = 'ecraInicialF';
export const FACTINTWS_PLANNED_CLIENT_IDENTITY = 'TesteWebservices.pfx';

const historical = FactIntWsEvidenceStatus.HISTORICAL;
const unknown = FactIntWsEvidenceStatus.UNKNOWN;

export const factIntWsProtocolEvidence = Object.freeze({
  endpoint443: Object.freeze({ value: FACTINTWS_ENDPOINT_443, status: historical }),
  endpoint8443: Object.freeze({ value: FACTINTWS_ENDPOINT_8443, status: historical }),
  soapVersion: Object.freeze({ value: '1.1', status: historical }),
  serviceNamespace: Object.freeze({ value: FACTINTWS_NAMESPACE, status: historical }),
  wsSecurityNamespace: Object.freeze({ value: FACTINTWS_WSSE_NAMESPACE, status: historical }),
  authNamespace: Object.freeze({ value: FACTINTWS_AUTH_NAMESPACE, status: historical }),
  actor: Object.freeze({ value: FACTINTWS_ACTOR, status: historical }),
  usernameTokenFields: Object.freeze({ value: Object.freeze(['Username', 'Password', 'Nonce', 'Created']), status: historical }),
  passwordDigestFormula: Object.freeze({ value: null, status: unknown }),
  passwordDigestInputOrder: Object.freeze({ value: null, status: unknown }),
  passwordDigestEncoding: Object.freeze({ value: null, status: unknown }),
  nonceByteLength: Object.freeze({ value: null, status: unknown }),
  nonceGeneration: Object.freeze({ value: null, status: unknown }),
  nonceXmlEncoding: Object.freeze({ value: null, status: unknown }),
  createdTimezone: Object.freeze({ value: null, status: unknown }),
  createdPrecision: Object.freeze({ value: null, status: unknown }),
  createdFormat: Object.freeze({ value: null, status: unknown }),
  operationName: Object.freeze({ value: FACTINTWS_OPERATION, status: historical }),
  operationRootElement: Object.freeze({ value: null, status: unknown }),
  operationRequiredBody: Object.freeze({ value: null, status: unknown }),
});

const criticalFields = Object.freeze([
  'passwordDigestFormula', 'passwordDigestInputOrder', 'passwordDigestEncoding',
  'nonceByteLength', 'nonceGeneration', 'nonceXmlEncoding',
  'createdTimezone', 'createdPrecision', 'createdFormat',
  'operationRootElement', 'operationRequiredBody',
]);

export function assessFactIntWsReadiness(evidence = factIntWsProtocolEvidence) {
  const missing = criticalFields.filter((field) => evidence[field]?.status !== FactIntWsEvidenceStatus.RUNTIME
    && evidence[field]?.status !== FactIntWsEvidenceStatus.HISTORICAL);
  const digestMissing = missing.some((field) => field.startsWith('passwordDigest'));
  return Object.freeze({
    ready: missing.length === 0,
    missing: Object.freeze(missing),
    classification: digestMissing
      ? AtErrorCode.FACTINTWS_DIGEST_NOT_READY
      : (missing.length ? AtErrorCode.FACTINTWS_OPERATION_SCHEMA_UNKNOWN : 'READY'),
  });
}

export function sanitizedFactIntWsResearchEnvelope() {
  return `<?xml version="1.0" encoding="UTF-8"?>\n` +
    `<S:Envelope xmlns:S="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wss="${FACTINTWS_WSSE_NAMESPACE}" xmlns:at="${FACTINTWS_AUTH_NAMESPACE}" xmlns:app="${FACTINTWS_NAMESPACE}">\n` +
    `  <S:Header>\n` +
    `    <wss:Security S:actor="${FACTINTWS_ACTOR}">\n` +
    `      <wss:UsernameToken>\n` +
    `        <wss:Username>[REDACTED_USERNAME]</wss:Username>\n` +
    `        <wss:Password Digest="[UNKNOWN_DIGEST_ATTRIBUTE]">[REDACTED]</wss:Password>\n` +
    `        <wss:Nonce>[REDACTED]</wss:Nonce>\n` +
    `        <wss:Created>[REDACTED]</wss:Created>\n` +
    `      </wss:UsernameToken>\n` +
    `    </wss:Security>\n` +
    `  </S:Header>\n` +
    `  <S:Body>\n` +
    `    <app:[UNKNOWN_ECRAINICIALF_ROOT]>[UNKNOWN_REQUIRED_BODY]</app:[UNKNOWN_ECRAINICIALF_ROOT]>\n` +
    `  </S:Body>\n` +
    `</S:Envelope>`;
}

export function buildFactIntWsEnvelope() {
  const readiness = assessFactIntWsReadiness();
  if (!readiness.ready) {
    throw new AtConnectorError(readiness.classification, 'FactIntWS request is blocked until critical historical protocol fields are reconstructed');
  }
  throw new AtConnectorError(AtErrorCode.SOAP_CONTRACT_UNRESOLVED, 'FactIntWS live envelope builder is intentionally unavailable');
}

export async function runFactIntWsFeasibility({ transport = null } = {}) {
  const readiness = assessFactIntWsReadiness();
  if (!readiness.ready) {
    return Object.freeze({
      endpoint: FACTINTWS_ENDPOINT_443,
      operation: FACTINTWS_OPERATION,
      ready: false,
      networkRequests: 0,
      classification: readiness.classification,
      missing: readiness.missing,
    });
  }
  if (typeof transport !== 'function') throw new TypeError('A transport is required only after protocol readiness');
  throw new AtConnectorError(AtErrorCode.LIVE_TEST_DISABLED, 'FactIntWS live execution requires a separately reviewed opt-in harness');
}
