import { AtConnectorError, AtErrorCode } from './errors.mjs';

export const EvidenceStatus = Object.freeze({
  OFFICIAL_DOCUMENTATION: 'OFFICIAL_DOCUMENTATION',
  HISTORICAL_CODE_EVIDENCE: 'HISTORICAL_CODE_EVIDENCE',
  RUNTIME_BEHAVIOR_CONFIRMED: 'RUNTIME_BEHAVIOR_CONFIRMED',
  UNKNOWN: 'UNKNOWN',
  // Backward-compatible aliases for the 0.7.1 API.
  CONFIRMED_OFFICIAL: 'OFFICIAL_DOCUMENTATION',
  INFERRED_NOT_ALLOWED: 'INFERRED_NOT_ALLOWED',
  UNRESOLVED: 'UNKNOWN',
});

export class AtProtocolEvidence {
  constructor({ field, value, sourceUrl, sourceTitle, documentVersion, section, verifiedAt, status, notes = null }) {
    Object.assign(this, { field, value, sourceUrl, sourceTitle, documentVersion, section, verifiedAt, status, notes });
    Object.freeze(this);
  }
}

const GENERIC_MANUAL = 'https://info.portaldasfinancas.gov.pt/pt/apoio_ao_contribuinte/Outras_entidades/Suporte_tecnologico/Webservice/e_Fatura/Documents/Comunicacao_dos_elementos_dos_documentos_de_faturacao_aspetos_gerais.pdf';
const SPECIFIC_MANUAL = 'https://info.portaldasfinancas.gov.pt/pt/apoio_ao_contribuinte/Outras_entidades/Suporte_tecnologico/Webservice/e_Fatura/Documents/Comunicacao_dos_elementos_dos_documentos_de_faturacao.pdf';
const FAQ = 'https://info.portaldasfinancas.gov.pt/pt/faturas/Pages/faqs-00996.aspx';
const VERIFIED_AT = '2026-08-28';

function official(field, value, sourceUrl, sourceTitle, documentVersion, section, notes = null) {
  return new AtProtocolEvidence({ field, value, sourceUrl, sourceTitle, documentVersion, section, verifiedAt: VERIFIED_AT, status: EvidenceStatus.OFFICIAL_DOCUMENTATION, notes });
}
function unresolved(field, notes, { sourceUrl = SPECIFIC_MANUAL, sourceTitle = 'AT e-Fatura — Aspetos Específicos', documentVersion = '3.0 (October 2025)', section = '2.1.10.3 / generic manual 3.6' } = {}) {
  return new AtProtocolEvidence({ field, value: null, sourceUrl, sourceTitle, documentVersion, section, verifiedAt: VERIFIED_AT, status: EvidenceStatus.UNKNOWN, notes });
}

const GENERIC_SOURCE = { sourceUrl: GENERIC_MANUAL, sourceTitle: 'AT e-Fatura — Aspetos Genéricos', documentVersion: 'April 2026 publication' };

export const protocolEvidence = Object.freeze([
  official('endpoint.test.consultation', 'https://servicos.portaldasfinancas.gov.pt:725/fatshare/ws/fatshareFaturas', GENERIC_MANUAL, 'AT e-Fatura — Aspetos Genéricos', 'April 2026 publication', '2.1.2 and 3.8'),
  official('transport', 'HTTPS with client certificate', GENERIC_MANUAL, 'AT e-Fatura — Aspetos Genéricos', 'April 2026 publication', '2.1.2 and 2.3'),
  official('soapVersion', 'SOAP 1.1', SPECIFIC_MANUAL, 'AT e-Fatura — Aspetos Específicos', '3.0 (October 2025)', '2.1.10.3', 'Official example declares the SOAP 1.1 envelope URI.'),
  official('clientCertificate', 'AT-issued/test SSL client certificate', GENERIC_MANUAL, 'AT e-Fatura — Aspetos Genéricos', 'April 2026 publication', '2.1.1–2.1.2'),
  official('usernameFormat', 'NIF/UserId', GENERIC_MANUAL, 'AT e-Fatura — Aspetos Genéricos', 'April 2026 publication', '2.2.1 H.1'),
  official('usernameToken', 'WS-Security UsernameToken with Username, Password, Nonce and Created', GENERIC_MANUAL, 'AT e-Fatura — Aspetos Genéricos', 'April 2026 publication', '2.2.1.1'),
  official('aesAlgorithm', 'AES', GENERIC_MANUAL, 'AT e-Fatura — Aspetos Genéricos', 'April 2026 publication', '2.2.1 H.2–H.4'),
  official('aesKeyLength', '128 bits', GENERIC_MANUAL, 'AT e-Fatura — Aspetos Genéricos', 'April 2026 publication', '2.2.1 H.3'),
  official('aesMode', 'ECB', GENERIC_MANUAL, 'AT e-Fatura — Aspetos Genéricos', 'April 2026 publication', '2.2.1 H.2/H.4'),
  official('aesPadding', 'PKCS5Padding', GENERIC_MANUAL, 'AT e-Fatura — Aspetos Genéricos', 'April 2026 publication', '2.2.1 H.2/H.4'),
  unresolved('rsaPadding', 'The official manual says only RSA; it does not identify PKCS#1 v1.5, OAEP or an OAEP hash.', { ...GENERIC_SOURCE, section: '2.2.1 H.3' }),
  official('timestampFormat', 'UTC ISO 8601', GENERIC_MANUAL, 'AT e-Fatura — Aspetos Genéricos', 'April 2026 publication', '2.2.1 H.4', 'Example includes fractional seconds; exact required fractional precision is not stated.'),
  unresolved('timestampPrecision', 'UTC ISO 8601 is confirmed, but required fractional-second precision is not stated.', { ...GENERIC_SOURCE, section: '2.2.1 H.4' }),
  unresolved('passwordEncoding', 'AES ciphertext then Base64 is confirmed; the header password plaintext character encoding is not expressly identified.', { ...GENERIC_SOURCE, section: '2.2.1 H.2' }),
  official('nonceFormat', 'random 128-bit AES key encrypted with AT RSA public key, then Base64', GENERIC_MANUAL, 'AT e-Fatura — Aspetos Genéricos', 'April 2026 publication', '2.2.1 H.3'),
  unresolved('wsdl', 'The generic manual explicitly says the FATSHARE-INVOICES WSDL will be made available later. A single safe ?wsdl probe returned SOAP fault, not definitions.'),
  unresolved('namespace', 'The official request example uses prefix fat without an xmlns:fat declaration.'),
  official('operation', 'InvoicesRequest / InvoicesResponse', SPECIFIC_MANUAL, 'AT e-Fatura — Aspetos Específicos', '3.0 (October 2025)', '2.1.10.1–2.1.10.2'),
  unresolved('soapAction', 'No consultation WSDL/binding or official SOAPAction was published.'),
  official('requestRootElement', 'InvoicesRequest', SPECIFIC_MANUAL, 'AT e-Fatura — Aspetos Específicos', '3.0 (October 2025)', '2.1.10.1 and 2.1.10.3'),
  official('subuserPermission', 'WFA — Comunicação de dados de faturas', FAQ, 'AT e-Fatura FAQ', 'live page checked 2026-08-28', 'FAQ 4996', 'The FAQ says this profile is limited to e-Fatura operations; it does not explicitly distinguish consultation from submission.'),
]);

export function evidenceFor(field) {
  return protocolEvidence.find((item) => item.field === field) || null;
}

export function assertAuthenticatedConsultationEvidence() {
  const critical = ['rsaPadding', 'passwordEncoding', 'timestampPrecision', 'wsdl', 'namespace', 'operation', 'soapAction', 'requestRootElement'];
  const unresolved = critical.map(evidenceFor).filter((item) => !item || item.status !== EvidenceStatus.OFFICIAL_DOCUMENTATION);
  if (unresolved.some((item) => item?.field === 'rsaPadding')) {
    throw new AtConnectorError(AtErrorCode.RSA_PADDING_UNCONFIRMED, 'Authenticated request blocked: official RSA padding is unconfirmed', { details: unresolved.map((item) => item?.field) });
  }
  if (unresolved.length) {
    throw new AtConnectorError(AtErrorCode.SOAP_CONTRACT_UNRESOLVED, 'Authenticated request blocked: official SOAP contract is incomplete', { details: unresolved.map((item) => item?.field) });
  }
  return true;
}

export const historicalProtocolEvidence = Object.freeze([
  new AtProtocolEvidence({ field: 'usernameFormat.primary', value: '9-digit taxpayer NIF', sourceUrl: null, sourceTitle: 'Historical authentication behavior supplied to Taxy 0.7.2', documentVersion: 'historical', section: 'UsernameToken Username', verifiedAt: VERIFIED_AT, status: EvidenceStatus.HISTORICAL_CODE_EVIDENCE, notes: 'Remote authorization for a primary user is not inferred and remains subject to the AT response.' }),
  new AtProtocolEvidence({ field: 'usernameFormat.subuser', value: 'NIF/UserId', sourceUrl: GENERIC_MANUAL, sourceTitle: 'AT e-Fatura — Aspetos Genéricos and historical implementation', documentVersion: 'historical', section: 'UsernameToken Username', verifiedAt: VERIFIED_AT, status: EvidenceStatus.HISTORICAL_CODE_EVIDENCE }),
  new AtProtocolEvidence({ field: 'namespace', value: 'http://factemi.at.min_financas.pt/fatshareInvoices', sourceUrl: null, sourceTitle: 'Controlled AT sandbox response', documentVersion: '0.7.2 experiment', section: 'InvoicesRequest namespace', verifiedAt: VERIFIED_AT, status: EvidenceStatus.RUNTIME_BEHAVIOR_CONFIRMED, notes: 'HTTP 200, no SOAP fault, parsed EstadoOperacao 486 and empty invoice list.' }),
  new AtProtocolEvidence({ field: 'soapAction', value: 'absent', sourceUrl: null, sourceTitle: 'Historical SOAP implementation supplied to Taxy 0.7.2', documentVersion: 'historical', section: 'HTTP headers', verifiedAt: VERIFIED_AT, status: EvidenceStatus.HISTORICAL_CODE_EVIDENCE }),
  new AtProtocolEvidence({ field: 'rsaPadding', value: 'RSAES-PKCS1-v1_5', sourceUrl: null, sourceTitle: 'Historical SOAP implementation supplied to Taxy 0.7.2', documentVersion: 'historical', section: 'Nonce construction', verifiedAt: VERIFIED_AT, status: EvidenceStatus.HISTORICAL_CODE_EVIDENCE }),
  new AtProtocolEvidence({ field: 'passwordEncoding', value: 'UTF-8 bytes (historical runtime behavior; not officially confirmed)', sourceUrl: null, sourceTitle: 'Historical SOAP implementation supplied to Taxy 0.7.2', documentVersion: 'historical', section: 'Password cipher', verifiedAt: VERIFIED_AT, status: EvidenceStatus.HISTORICAL_CODE_EVIDENCE }),
  new AtProtocolEvidence({ field: 'timestampPrecision', value: 'YYYY-MM-DDTHH:mm:ss.000Z', sourceUrl: null, sourceTitle: 'Historical SOAP implementation supplied to Taxy 0.7.2', documentVersion: 'historical', section: 'Created', verifiedAt: VERIFIED_AT, status: EvidenceStatus.HISTORICAL_CODE_EVIDENCE }),
  new AtProtocolEvidence({ field: 'nonceConstruction', value: 'Base64(RSA-PKCS1-v1_5(AES-128 session key))', sourceUrl: null, sourceTitle: 'Historical SOAP implementation supplied to Taxy 0.7.2', documentVersion: 'historical', section: 'UsernameToken Nonce', verifiedAt: VERIFIED_AT, status: EvidenceStatus.HISTORICAL_CODE_EVIDENCE }),
  new AtProtocolEvidence({ field: 'pagination.documentsPerPage', value: 500, sourceUrl: null, sourceTitle: 'Historical SOAP implementation supplied to Taxy 0.7.2', documentVersion: 'historical', section: 'InvoicesRequest Pagination', verifiedAt: VERIFIED_AT, status: EvidenceStatus.HISTORICAL_CODE_EVIDENCE }),
]);

export function historicalEvidenceFor(field) {
  return historicalProtocolEvidence.find((item) => item.field === field) || evidenceFor(field);
}

export function assertHistoricalConsultationEvidence() {
  const required = ['endpoint.test.consultation', 'soapVersion', 'usernameFormat', 'aesAlgorithm', 'aesKeyLength', 'aesMode', 'aesPadding', 'operation', 'requestRootElement', 'namespace', 'soapAction', 'rsaPadding', 'passwordEncoding', 'timestampPrecision', 'nonceConstruction', 'pagination.documentsPerPage'];
  const missing = required.filter((field) => {
    const item = historicalEvidenceFor(field);
    return !item || ![EvidenceStatus.OFFICIAL_DOCUMENTATION, EvidenceStatus.HISTORICAL_CODE_EVIDENCE, EvidenceStatus.RUNTIME_BEHAVIOR_CONFIRMED].includes(item.status);
  });
  if (missing.length) throw new AtConnectorError(AtErrorCode.SOAP_CONTRACT_UNRESOLVED, 'Historical SOAP protocol evidence is incomplete', { details: missing });
  return true;
}
