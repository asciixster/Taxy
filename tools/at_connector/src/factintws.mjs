import { createCipheriv, createHash, constants, publicEncrypt } from 'node:crypto';
import { AtConnectorError, AtErrorCode } from './errors.mjs';
import { escapeXml } from './soap.mjs';

export const FactIntWsEvidenceStatus = Object.freeze({
  OFFICIAL_APP: 'CONFIRMED_FROM_OFFICIAL_APP', RUNTIME: 'RUNTIME_CONFIRMED',
  INFERENCE: 'INFERRED', UNKNOWN: 'UNKNOWN',
  HISTORICAL: 'CONFIRMED_FROM_OFFICIAL_APP',
});
export const FACTINTWS_ENDPOINT_443 = 'https://servicos.portaldasfinancas.gov.pt:443/mobile/a4/factintws/ws';
export const FACTINTWS_ENDPOINT_8443 = 'https://servicos.portaldasfinancas.gov.pt:8443/mobile/a4/factintws/ws';
export const FACTINTWS_NAMESPACE = 'http://factemi.at.min_financas.pt/factintws';
export const FACTINTWS_SOAP_NAMESPACE = 'http://schemas.xmlsoap.org/soap/envelope/';
export const FACTINTWS_WSSE_NAMESPACE = 'http://schemas.xmlsoap.org/ws/2002/12/secext';
export const FACTINTWS_AUTH_NAMESPACE = 'http://at.pt/wsp/auth';
export const FACTINTWS_ACTOR = 'http://at.pt/actor/SPA';
export const FACTINTWS_OPERATION = 'EcraInicial';
export const FACTINTWS_PLANNED_CLIENT_IDENTITY = 'TesteWebservices.pfx';
const officialApp = FactIntWsEvidenceStatus.OFFICIAL_APP;

export const factIntWsOperations = Object.freeze({
  EcraInicial: Object.freeze({ readOnly: true, fields: Object.freeze(['Nif', 'Ano', 'CanalOrigem']) }),
  DadosContribuinte: Object.freeze({ readOnly: true, fields: Object.freeze(['Nif', 'CanalOrigem']) }),
  FaturasPorClassificar: Object.freeze({ readOnly: true, fields: Object.freeze(['Nif', 'Ano', 'CanalOrigem']) }),
  FaturasPorSetor: Object.freeze({ readOnly: true, fields: Object.freeze(['NifAdquirente', 'CodSetor', 'Ano', 'Indice', 'CanalOrigem']) }),
  ClassificarFatura: Object.freeze({ readOnly: false, fields: Object.freeze(['OrigemRegisto', 'NifAdquirente', 'ListaFaturasPorValidar', 'CanalRegisto']) }),
  RegistarFaturaQRCode: Object.freeze({ readOnly: false, fields: Object.freeze(['PedidoRegistarFaturaQRCode', 'CanalRegisto']) }),
  EliminarFaturaQRCode: Object.freeze({ readOnly: false, fields: Object.freeze(['OrigemRegisto', 'ListaFaturasEliminar', 'CanalRegisto']) }),
  AssociarReceita: Object.freeze({ readOnly: false, fields: Object.freeze(['ListaReceita', 'CanalRegisto']) }),
});

export const factIntWsProtocolEvidence = Object.freeze({
  endpoint443: Object.freeze({ value: FACTINTWS_ENDPOINT_443, status: officialApp }),
  endpoint8443: Object.freeze({ value: FACTINTWS_ENDPOINT_8443, status: officialApp }),
  soapVersion: Object.freeze({ value: '1.1', status: officialApp }),
  serviceNamespace: Object.freeze({ value: FACTINTWS_NAMESPACE, status: officialApp }),
  wsSecurityNamespace: Object.freeze({ value: FACTINTWS_WSSE_NAMESPACE, status: officialApp }),
  authNamespace: Object.freeze({ value: FACTINTWS_AUTH_NAMESPACE, status: officialApp }),
  actor: Object.freeze({ value: FACTINTWS_ACTOR, status: officialApp }),
  authVersion: Object.freeze({ value: '2', status: officialApp }),
  usernameTokenFields: Object.freeze({ value: Object.freeze(['Username', 'Password', 'Nonce', 'Created']), status: officialApp }),
  passwordDigestFormula: Object.freeze({ value: 'AES-128-ECB-PKCS7(SHA1(aesKeyBytes || createdUtf8 || passwordUtf8))', status: officialApp }),
  passwordDigestInputOrder: Object.freeze({ value: Object.freeze(['aesKeyBytes', 'createdUtf8', 'passwordUtf8']), status: officialApp }),
  passwordDigestEncoding: Object.freeze({ value: 'base64(AES ciphertext)', status: officialApp }),
  nonceByteLength: Object.freeze({ value: 16, status: officialApp }),
  nonceGeneration: Object.freeze({ value: 'AES-128 key generator, fresh per request', status: officialApp }),
  nonceXmlEncoding: Object.freeze({ value: 'base64(RSAES-PKCS1-v1_5(publicKey, aesKeyBytes))', status: officialApp }),
  createdTimezone: Object.freeze({ value: 'UTC from NTP response', status: officialApp }),
  createdPrecision: Object.freeze({ value: 'milliseconds', status: officialApp }),
  createdFormat: Object.freeze({ value: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", status: officialApp }),
  operationName: Object.freeze({ value: FACTINTWS_OPERATION, status: officialApp }),
  operationRootElement: Object.freeze({ value: 'app:EcraInicialRequest', status: officialApp }),
  operationRequiredBody: Object.freeze({ value: Object.freeze(['app:Nif', 'app:Ano', 'app:CanalOrigem']), status: officialApp }),
  soapAction: Object.freeze({ value: `${FACTINTWS_NAMESPACE}/EcraInicial`, status: officialApp }),
  contentType: Object.freeze({ value: 'text/xml;charset=utf-8', status: officialApp }),
  certificatePinning: Object.freeze({ value: 'TrustKit SHA-256 pin-set, enforced for the service hostname', status: officialApp }),
});

const criticalFields = Object.freeze([
  'passwordDigestFormula', 'passwordDigestInputOrder', 'passwordDigestEncoding',
  'nonceByteLength', 'nonceGeneration', 'nonceXmlEncoding', 'createdTimezone',
  'createdPrecision', 'createdFormat', 'operationRootElement',
  'operationRequiredBody', 'soapAction', 'contentType',
]);

export function assessFactIntWsReadiness(evidence = factIntWsProtocolEvidence) {
  const accepted = [FactIntWsEvidenceStatus.OFFICIAL_APP, FactIntWsEvidenceStatus.RUNTIME];
  const missing = criticalFields.filter((field) => !accepted.includes(evidence[field]?.status));
  return Object.freeze({ ready: missing.length === 0, missing: Object.freeze(missing),
    classification: missing.length ? AtErrorCode.FACTINTWS_OPERATION_SCHEMA_UNKNOWN : 'READY' });
}

function aesEncrypt(key, bytes) {
  if (!Buffer.isBuffer(key) || key.length !== 16) throw new TypeError('FactIntWS AES key must contain exactly 16 bytes');
  const cipher = createCipheriv('aes-128-ecb', key, null);
  cipher.setAutoPadding(true);
  return Buffer.concat([cipher.update(bytes), cipher.final()]);
}

export function factIntWsDigestBytes({ aesKey, created, password }) {
  return createHash('sha1').update(Buffer.concat([
    Buffer.from(aesKey), Buffer.from(created, 'utf8'), Buffer.from(password, 'utf8'),
  ])).digest();
}

export function buildFactIntWsSecurityMaterial({ aesKey, created, password, rsaPublicKey }) {
  const key = Buffer.from(aesKey);
  return Object.freeze({
    encryptedPassword: aesEncrypt(key, Buffer.from(password, 'utf8')).toString('base64'),
    encryptedDigest: aesEncrypt(key, factIntWsDigestBytes({ aesKey: key, created, password })).toString('base64'),
    encryptedNonce: publicEncrypt({ key: rsaPublicKey, padding: constants.RSA_PKCS1_PADDING }, key).toString('base64'),
    created,
  });
}

function channelXml(channel) {
  if (!channel?.system || !channel?.version) throw new TypeError('CanalOrigem requires system and version');
  return `<app:CanalOrigem><app:Sistema>${escapeXml(channel.system)}</app:Sistema><app:Versao>${escapeXml(channel.version)}</app:Versao></app:CanalOrigem>`;
}

export function serializeFactIntWsOperation(operation, input = {}) {
  let children;
  switch (operation) {
    case 'EcraInicial':
      children = `<app:Nif>${escapeXml(input.nif)}</app:Nif><app:Ano>${escapeXml(input.year)}</app:Ano>${channelXml(input.channel)}`; break;
    case 'DadosContribuinte':
      children = `<app:Nif>${escapeXml(input.nif)}</app:Nif>${channelXml(input.channel)}`; break;
    case 'FaturasPorClassificar':
      children = `<app:Nif>${escapeXml(input.nif)}</app:Nif><app:Ano>${escapeXml(input.year)}</app:Ano>${channelXml(input.channel)}`; break;
    case 'FaturasPorSetor':
      children = `<app:NifAdquirente>${escapeXml(input.nif)}</app:NifAdquirente><app:CodSetor>${escapeXml(input.sector ?? '')}</app:CodSetor><app:Ano>${escapeXml(input.year)}</app:Ano><app:Indice>${escapeXml(input.index ?? '0')}</app:Indice>${channelXml(input.channel)}`; break;
    default: throw new TypeError(`Unsupported read-only FactIntWS operation: ${operation}`);
  }
  return `<app:${operation}Request xmlns:app="${FACTINTWS_NAMESPACE}"> ${children} </app:${operation}Request>`;
}

export function buildFactIntWsEnvelope({ username, credentials, operation = FACTINTWS_OPERATION, input }) {
  if (!assessFactIntWsReadiness().ready) throw new AtConnectorError(AtErrorCode.FACTINTWS_OPERATION_SCHEMA_UNKNOWN, 'FactIntWS protocol gate is not ready');
  const body = serializeFactIntWsOperation(operation, input);
  return `<?xml version="1.0" encoding="utf-8" standalone="no"?>\n` +
    `<S:Envelope xmlns:S="${FACTINTWS_SOAP_NAMESPACE}"><S:Header>` +
    `<wss:Security xmlns:at="${FACTINTWS_AUTH_NAMESPACE}" xmlns:wss="${FACTINTWS_WSSE_NAMESPACE}" S:Actor="${FACTINTWS_ACTOR}" at:Version="2">` +
    `<wss:UsernameToken><wss:Username>${escapeXml(username)}</wss:Username>` +
    `<wss:Password Digest="${escapeXml(credentials.encryptedDigest)}">${escapeXml(credentials.encryptedPassword)}</wss:Password>` +
    `<wss:Nonce>${escapeXml(credentials.encryptedNonce)}</wss:Nonce><wss:Created>${escapeXml(credentials.created)}</wss:Created>` +
    `</wss:UsernameToken></wss:Security></S:Header><S:Body>${body}</S:Body></S:Envelope>`;
}

export function factIntWsHttpContract(operation = FACTINTWS_OPERATION) {
  return Object.freeze({ method: 'POST', endpoint: FACTINTWS_ENDPOINT_443,
    headers: Object.freeze({ 'User-Agent': 'ksoap2-android/2.6.0+', SOAPAction: `${FACTINTWS_NAMESPACE}/${operation}`,
      'Content-Type': 'text/xml;charset=utf-8', 'Accept-Encoding': 'gzip' }), timeoutMs: 120000 });
}

export function sanitizedFactIntWsResearchEnvelope() {
  return buildFactIntWsEnvelope({ username: '[REDACTED_USERNAME]',
    credentials: { encryptedDigest: '[REDACTED]', encryptedPassword: '[REDACTED]', encryptedNonce: '[REDACTED]', created: '[REDACTED]' },
    input: { nif: '[REDACTED_IDENTIFIER]', year: '[YEAR]', channel: { system: '[SYSTEM]', version: '[VERSION]' } } });
}

export async function runFactIntWsFeasibility() {
  const readiness = assessFactIntWsReadiness();
  return Object.freeze({ endpoint: FACTINTWS_ENDPOINT_443, operation: FACTINTWS_OPERATION,
    ready: readiness.ready, networkRequests: 0,
    classification: readiness.ready ? 'READY_FOR_SEPARATELY_APPROVED_SINGLE_LIVE_TEST' : readiness.classification,
    missing: readiness.missing });
}
