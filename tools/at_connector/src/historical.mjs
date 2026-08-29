import { AtTimestampBuilder, validateAtUsername } from './auth.mjs';
import { buildEncryptedCredentials, generateAes128SessionKey, readAtPublicKey, RsaPaddingMode } from './crypto.mjs';
import { endpointFor } from './endpoints.mjs';
import { AtConnectorError, AtErrorCode } from './errors.mjs';
import { assertHistoricalConsultationEvidence, EvidenceStatus, historicalProtocolEvidence } from './evidence.mjs';
import { escapeXml } from './soap.mjs';
import { sendMtlsSoap } from './transport.mjs';
import { AtInvoiceListResponse } from './consultation.mjs';
import { parseSoapResponse } from './parser.mjs';

export const HISTORICAL_NAMESPACE = 'http://factemi.at.min_financas.pt/fatshareInvoices';
export const HistoricalSource = 'HISTORICAL_CODE_EVIDENCE';
export const RUNTIME_CONFIRMABLE_FIELDS = Object.freeze([
  'namespace',
]);

export function validateSubuserUsername(username) {
  return validateAtUsername(username);
}

export function customerTaxIdFromUsername(username, suppliedCustomerTaxId = null) {
  const validated = validateAtUsername(username);
  const derived = validated.split('/')[0];
  if (suppliedCustomerTaxId != null && suppliedCustomerTaxId !== derived) {
    throw new AtConnectorError(AtErrorCode.CUSTOMER_TAX_ID_MISMATCH, 'CustomerTaxID must equal the NIF portion of AT_USERNAME');
  }
  return derived;
}

function dateOnly(value, field) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value || '') || Number.isNaN(Date.parse(`${value}T00:00:00Z`)) || new Date(`${value}T00:00:00Z`).toISOString().slice(0, 10) !== value) {
    throw new Error(`${field} must use YYYY-MM-DD`);
  }
  return value;
}

export function validateHistoricalDateRange(startDate, endDate) {
  const start = dateOnly(startDate, 'startDate');
  const end = dateOnly(endDate, 'endDate');
  const days = (Date.parse(`${end}T00:00:00Z`) - Date.parse(`${start}T00:00:00Z`)) / 86_400_000;
  if (days < 0) throw new Error('endDate must not precede startDate');
  if (days > 7) throw new Error('Historical live harness limits consultation ranges to 7 days');
  return Object.freeze({ startDate: start, endDate: end });
}

export function buildHistoricalEnvelope({ username, password, cipherCertificatePath, cipherPublicKey = null, startDate, endDate, customerTaxId = null, clock = () => new Date(), randomSource }) {
  assertHistoricalConsultationEvidence();
  const dates = validateHistoricalDateRange(startDate, endDate);
  const customer = customerTaxIdFromUsername(username, customerTaxId);
  const createdPlaintext = AtTimestampBuilder.historical(clock);
  const sessionKey = generateAes128SessionKey(randomSource);
  try {
    // Source: HISTORICAL_CODE_EVIDENCE. Not confirmed by official AT documentation.
    const encrypted = buildEncryptedCredentials({
      password,
      created: createdPlaintext,
      publicKey: cipherPublicKey || readAtPublicKey(cipherCertificatePath),
      sessionKey,
      rsaPaddingMode: RsaPaddingMode.PKCS1_V1_5,
    });
    const xml = `<?xml version="1.0" encoding="UTF-8"?>` +
      `<S:Envelope xmlns:S="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wss="http://schemas.xmlsoap.org/ws/2002/12/secext" xmlns:fat="${HISTORICAL_NAMESPACE}">` +
      `<S:Header><wss:Security><wss:UsernameToken>` +
      `<wss:Username>${escapeXml(username)}</wss:Username>` +
      `<wss:Password>${encrypted.password}</wss:Password>` +
      `<wss:Nonce>${encrypted.nonce}</wss:Nonce>` +
      `<wss:Created>${encrypted.created}</wss:Created>` +
      `</wss:UsernameToken></wss:Security></S:Header>` +
      `<S:Body><fat:InvoicesRequest>` +
      `<fat:TaxRegistrationNumber>${customer}</fat:TaxRegistrationNumber>` +
      `<fat:StartDate>${dates.startDate}</fat:StartDate>` +
      `<fat:EndDate>${dates.endDate}</fat:EndDate>` +
      `<fat:Pagination><fat:nPage>1</fat:nPage><fat:nDocsPage>500</fat:nDocsPage></fat:Pagination>` +
      `</fat:InvoicesRequest></S:Body></S:Envelope>`;
    return Object.freeze({ xml, createdPlaintext, customerTaxId: customer, source: HistoricalSource, soapAction: null });
  } finally {
    sessionKey.fill(0);
  }
}

export function sanitizedHistoricalEnvelope() {
  return `<?xml version="1.0" encoding="UTF-8"?>\n` +
    `<S:Envelope xmlns:S="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wss="http://schemas.xmlsoap.org/ws/2002/12/secext" xmlns:fat="${HISTORICAL_NAMESPACE}">\n` +
    `  <S:Header><wss:Security><wss:UsernameToken>` +
    `<wss:Username>[REDACTED]</wss:Username><wss:Password>[REDACTED]</wss:Password>` +
    `<wss:Nonce>[REDACTED]</wss:Nonce><wss:Created>[REDACTED]</wss:Created>` +
    `</wss:UsernameToken></wss:Security></S:Header>\n` +
    `  <S:Body><fat:InvoicesRequest><fat:TaxRegistrationNumber>[REDACTED_NIF]</fat:TaxRegistrationNumber>` +
    `<fat:StartDate>[YYYY-MM-DD]</fat:StartDate><fat:EndDate>[YYYY-MM-DD]</fat:EndDate>` +
    `<fat:Pagination><fat:nPage>1</fat:nPage><fat:nDocsPage>500</fat:nDocsPage></fat:Pagination>` +
    `</fat:InvoicesRequest></S:Body>\n</S:Envelope>`;
}

export class HistoricalAtConsultationClient {
  #requestsSent = 0;

  constructor(config, { transport = sendMtlsSoap, envelopeBuilder = buildHistoricalEnvelope, onNetworkRequest = null } = {}) {
    this.config = config; this.transport = transport; this.envelopeBuilder = envelopeBuilder; this.onNetworkRequest = onNetworkRequest;
  }

  async fetchOnce({ startDate, endDate, customerTaxId = null }) {
    if (this.#requestsSent >= 1) throw new AtConnectorError(AtErrorCode.RATE_LIMIT_EXCEEDED, 'Only one live AT request is allowed per process');
    if (this.config.environment !== 'test') throw new AtConnectorError(AtErrorCode.PRODUCTION_BLOCKED, 'Production is disabled');
    this.#requestsSent += 1;
    const request = this.envelopeBuilder({
      username: this.config.username,
      password: this.config.password,
      cipherCertificatePath: this.config.cipherCertificatePath,
      startDate,
      endDate,
      customerTaxId,
    });
    const transport = await this.transport({
      endpoint: endpointFor('test', 'invoiceConsultation'),
      pfxPath: this.config.pfxPath,
      pfxPassword: this.config.pfxPassword,
      xml: request.xml,
      soapAction: undefined,
      connectTimeoutMs: 15_000,
      totalTimeoutMs: 60_000,
      onRequestStart: this.onNetworkRequest,
    });
    const soap = parseSoapResponse(transport.body, transport.statusCode);
    const result = soap.fault ? null : AtInvoiceListResponse.fromXml(transport.body);
    const confirmed = transport.statusCode >= 200 && transport.statusCode < 300 && Number.isFinite(result?.operationStatus);
    return Object.freeze({
      transport, soap, result,
      evidenceStatus: confirmed ? EvidenceStatus.RUNTIME_BEHAVIOR_CONFIRMED : EvidenceStatus.HISTORICAL_CODE_EVIDENCE,
      runtimeConfirmedFields: confirmed ? RUNTIME_CONFIRMABLE_FIELDS : Object.freeze([]),
    });
  }
}
