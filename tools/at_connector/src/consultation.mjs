import { AtConnectorError, AtErrorCode } from './errors.mjs';
import { AtDateOnly, AtInvoice, AtInvoicePage, AtInvoiceQueryResult } from './dto.mjs';
import { escapeXml } from './soap.mjs';

function dateOnly(value, field) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value) || Number.isNaN(Date.parse(`${value}T00:00:00Z`))) {
    throw new Error(`${field} must use YYYY-MM-DD`);
  }
  return value;
}

export class InvoicesRequest {
  constructor({ taxRegistrationNumber = null, customerTaxId = null, startDate, endDate, pagination = null }) {
    if (Boolean(taxRegistrationNumber) === Boolean(customerTaxId)) throw new Error('Exactly one issuer or customer NIF is required');
    for (const [field, value] of [['taxRegistrationNumber', taxRegistrationNumber], ['customerTaxId', customerTaxId]]) {
      if (value != null && !/^\d{9}$/.test(value)) throw new Error(`${field} must contain 9 digits`);
    }
    if (pagination && (!Number.isInteger(pagination.page) || pagination.page < 1 || !Number.isInteger(pagination.documentsPerPage) || pagination.documentsPerPage < 1 || pagination.documentsPerPage > 5000)) {
      throw new Error('Pagination must use page >= 1 and 1..5000 documents');
    }
    Object.assign(this, { taxRegistrationNumber, customerTaxId, startDate: dateOnly(startDate, 'startDate'), endDate: dateOnly(endDate, 'endDate'), pagination });
    Object.freeze(this);
  }

  toSanitizedJSON() {
    return {
      requestRoot: 'InvoicesRequest',
      party: this.taxRegistrationNumber ? 'issuer:[REDACTED_NIF]' : 'customer:[REDACTED_NIF]',
      startDate: this.startDate,
      endDate: this.endDate,
      pagination: this.pagination,
    };
  }

  toXml(namespace) {
    if (!namespace) throw new AtConnectorError(AtErrorCode.SOAP_CONTRACT_UNRESOLVED, 'Cannot serialize InvoicesRequest without an officially confirmed namespace');
    const nifElement = this.taxRegistrationNumber
      ? `<fat:TaxRegistrationNumber>${escapeXml(this.taxRegistrationNumber)}</fat:TaxRegistrationNumber>`
      : `<fat:CustomerTaxID>${escapeXml(this.customerTaxId)}</fat:CustomerTaxID>`;
    const pagination = this.pagination ? `<fat:Pagination><fat:nPage>${this.pagination.page}</fat:nPage><fat:nDocsPage>${this.pagination.documentsPerPage}</fat:nDocsPage></fat:Pagination>` : '';
    return `<fat:InvoicesRequest xmlns:fat="${escapeXml(namespace)}">${nifElement}<fat:StartDate>${this.startDate}</fat:StartDate><fat:EndDate>${this.endDate}</fat:EndDate>${pagination}</fat:InvoicesRequest>`;
  }
}

function tag(xml, name) {
  const match = xml.match(new RegExp(`<(?:[\\w.-]+:)?${name}(?:\\s[^>]*)?>([\\s\\S]*?)<\\/(?:[\\w.-]+:)?${name}>`, 'i'));
  return match ? match[1].replace(/<[^>]+>/g, '').trim() : null;
}

function tags(xml, names) {
  const found = [];
  for (const name of names) {
    const expression = new RegExp(`<(?:[\\w.-]+:)?${name}(?:\\s[^>]*)?>([\\s\\S]*?)<\\/(?:[\\w.-]+:)?${name}\\s*>`, 'gi');
    for (const match of xml.matchAll(expression)) found.push(decodeXml(match[1].replace(/<[^>]+>/g, '')));
  }
  return found;
}

function decodeXml(value = '') {
  return value.replaceAll('&lt;', '<').replaceAll('&gt;', '>').replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'").replaceAll('&amp;', '&').trim();
}

function invoiceBlocks(xml) {
  return [...xml.matchAll(/<(?:[\w.-]+:)?(?:Invoice|InvoiceData|Fatura)(?:\s[^>]*)?>([\s\S]*?)<\/(?:[\w.-]+:)?(?:Invoice|InvoiceData|Fatura)\s*>/gi)]
    .map((match) => match[1]);
}

function invoiceField(xml, name) {
  const value = tag(xml, name);
  return value == null ? null : decodeXml(value);
}

function firstInvoiceField(xml, names) {
  for (const name of names) {
    const value = invoiceField(xml, name);
    if (value != null && value !== '') return value;
  }
  return null;
}

function invalidInvoiceField(field, expectedType, anonymousInvoiceIndex) {
  return new AtConnectorError(AtErrorCode.INVALID_RESPONSE, `Invoice ${anonymousInvoiceIndex} has an invalid ${field}`, {
    details: { field, expectedType, anonymousInvoiceIndex },
  });
}

export function parseMoneyToCents(value, field = 'money', anonymousInvoiceIndex = 1) {
  if (value == null || value === '') return null;
  const normalized = String(value).trim().replace(',', '.');
  const match = normalized.match(/^([+-]?)(\d+)(?:\.(\d{1,2}))?$/);
  if (!match) throw invalidInvoiceField(field, 'decimal with at most two fraction digits', anonymousInvoiceIndex);
  const sign = match[1] === '-' ? -1 : 1;
  const cents = sign * (Number(match[2]) * 100 + Number((match[3] || '').padEnd(2, '0')));
  if (!Number.isSafeInteger(cents)) throw invalidInvoiceField(field, 'safe integer cents', anonymousInvoiceIndex);
  return cents;
}

export function parseInvoiceDateOnly(value, anonymousInvoiceIndex = 1) {
  if (value == null || value === '') return null;
  try { return new AtDateOnly(value).value; } catch { throw invalidInvoiceField('date', 'YYYY-MM-DD date-only', anonymousInvoiceIndex); }
}

function parseOptionalNonNegativeInteger(value, field) {
  if (value == null) return null;
  if (!/^\d+$/.test(value)) throw new AtConnectorError(AtErrorCode.INVALID_RESPONSE, `${field} must be a non-negative integer`, { details: { field, expectedType: 'non-negative integer' } });
  const parsed = Number(value);
  if (!Number.isSafeInteger(parsed)) throw new AtConnectorError(AtErrorCode.INVALID_RESPONSE, `${field} is outside the safe integer range`, { details: { field, expectedType: 'safe integer' } });
  return parsed;
}

const FIELD_ALIASES = Object.freeze({
  date: ['InvoiceDate', 'IssueDate', 'DataEmissao'],
  issuer: ['TaxRegistrationNumber', 'SupplierTaxID', 'IssuerTaxID', 'NIFEmitente'],
  documentType: ['InvoiceType', 'DocumentType', 'TipoDocumento', 'TipoDoc'],
  documentReference: ['InvoiceNo', 'DocumentReference', 'NumeroDocumento', 'NumDoc'],
  total: ['GrossTotal', 'TotalAmount', 'ValorTotal'],
  taxable: ['NetTotal', 'TaxableAmount', 'ValorTributavel', 'BaseTributavel'],
  vat: ['TaxPayable', 'VATAmount', 'ValorIVA'],
  vatRate: ['TaxPercentage', 'TaxRate', 'VATRate', 'TaxaIVA'],
  sector: ['Sector', 'SectorCode', 'Setor', 'CodSetor'],
  classificationStatus: ['ClassificationStatus', 'StatusClassificacao', 'EstadoClassificacao'],
  pendingStatus: ['PendingStatus', 'Pending', 'Pendente'],
  invoiceIdentifier: ['InvoiceId', 'InvoiceID', 'IdFatura'],
  source: ['Source', 'Origem'],
});

const KNOWN_INVOICE_ELEMENTS = new Set(Object.values(FIELD_ALIASES).flat().map((name) => name.toLowerCase()));

function localElementNames(xml) {
  return [...xml.matchAll(/<(?!\/|\?|!)(?:[\w.-]+:)?([A-Za-z_][\w.-]*)(?:\s[^>]*)?>/g)].map((match) => match[1]);
}

function parseInvoice(xml, index) {
  const raw = Object.fromEntries(Object.entries(FIELD_ALIASES).map(([field, aliases]) => [field, firstInvoiceField(xml, aliases)]));
  const fieldPresence = Object.fromEntries(Object.entries(raw).map(([field, value]) => [field, value != null]));
  if (!fieldPresence.date && !fieldPresence.total && !fieldPresence.documentReference && !fieldPresence.invoiceIdentifier) {
    throw invalidInvoiceField('invoice', 'recognizable invoice fields', index);
  }
  const vatRatesBasisPoints = tags(xml, FIELD_ALIASES.vatRate).map((value) => parseMoneyToCents(value, 'vatRate', index));
  return new AtInvoice({
    anonymousInvoiceIndex: index,
    date: parseInvoiceDateOnly(raw.date, index),
    documentType: raw.documentType,
    totalCents: parseMoneyToCents(raw.total, 'total', index),
    taxableCents: parseMoneyToCents(raw.taxable, 'taxable', index),
    vatCents: parseMoneyToCents(raw.vat, 'vat', index),
    vatRatesBasisPoints,
    sector: raw.sector,
    classificationStatus: raw.classificationStatus,
    pendingStatus: raw.pendingStatus,
    source: raw.source,
    issuerPresent: fieldPresence.issuer,
    documentReferencePresent: fieldPresence.documentReference,
    invoiceIdentifierPresent: fieldPresence.invoiceIdentifier,
    fieldPresence,
  });
}

export const AUDITED_INVOICE_FIELDS = Object.freeze(Object.keys(FIELD_ALIASES));

export class AtInvoiceListResponse extends AtInvoiceQueryResult {
  static fromXml(xml) {
    const statusText = tag(xml, 'EstadoOperacao');
    if (statusText == null) throw new AtConnectorError(AtErrorCode.INVALID_RESPONSE, 'InvoicesResponse has no EstadoOperacao');
    if (!/^\d+$/.test(statusText)) throw new AtConnectorError(AtErrorCode.INVALID_RESPONSE, 'EstadoOperacao must be an integer');
    const blocks = invoiceBlocks(xml);
    const invoices = blocks.map((invoice, index) => parseInvoice(invoice, index + 1));
    const totalDocuments = parseOptionalNonNegativeInteger(tag(xml, 'totalDocs'), 'totalDocs');
    const documentsSent = parseOptionalNonNegativeInteger(tag(xml, 'totalDocsSent'), 'totalDocsSent');
    const totalPages = parseOptionalNonNegativeInteger(tag(xml, 'totalPages'), 'totalPages');
    const page = parseOptionalNonNegativeInteger(tag(xml, 'nPage'), 'nPage');
    if (documentsSent != null && documentsSent !== invoices.length) {
      throw new AtConnectorError(AtErrorCode.INVALID_RESPONSE, 'Parsed invoice count does not match totalDocsSent', {
        details: { field: 'totalDocsSent', expectedType: 'must equal parsed invoice count', parsedInvoiceCount: invoices.length },
      });
    }
    const observedFields = AUDITED_INVOICE_FIELDS.filter((field) => invoices.some((invoice) => invoice.fieldPresence[field]));
    const unknownElements = [...new Set(blocks.flatMap(localElementNames).filter((name) => !KNOWN_INVOICE_ELEMENTS.has(name.toLowerCase())))].sort();
    return new AtInvoiceListResponse({
      operationStatus: Number(statusText),
      description: tag(xml, 'Desc'),
      invoices,
      pagination: [totalDocuments, documentsSent, totalPages, page].every((value) => value == null) ? null : new AtInvoicePage({ totalDocuments, documentsSent, totalPages, page }),
      observedFields,
      notAvailableFields: AUDITED_INVOICE_FIELDS.filter((field) => !observedFields.includes(field)),
      unknownElements,
    });
  }
}
