import { AtConnectorError, AtErrorCode } from './errors.mjs';
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

function decodeXml(value = '') {
  return value.replaceAll('&lt;', '<').replaceAll('&gt;', '>').replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'").replaceAll('&amp;', '&').trim();
}

function invoiceBlocks(xml) {
  return [...xml.matchAll(/<(?:[\w.-]+:)?Invoice(?:\s[^>]*)?>([\s\S]*?)<\/(?:[\w.-]+:)?Invoice\s*>/gi)]
    .map((match) => match[1]);
}

function invoiceField(xml, name) {
  const value = tag(xml, name);
  return value == null ? null : decodeXml(value);
}

export class AtInvoiceListResponse {
  constructor({ operationStatus, description, invoices = [], pagination = null }) {
    Object.assign(this, { operationStatus, description, invoices, pagination }); Object.freeze(this);
  }

  static fromXml(xml) {
    const statusText = tag(xml, 'EstadoOperacao');
    if (statusText == null) throw new AtConnectorError(AtErrorCode.INVALID_RESPONSE, 'InvoicesResponse has no EstadoOperacao');
    return new AtInvoiceListResponse({
      operationStatus: Number(statusText),
      description: tag(xml, 'Desc'),
      invoices: invoiceBlocks(xml).map((invoice) => Object.freeze({
        invoiceNo: invoiceField(invoice, 'InvoiceNo'),
        invoiceDate: invoiceField(invoice, 'InvoiceDate'),
        invoiceType: invoiceField(invoice, 'InvoiceType'),
        taxRegistrationNumber: invoiceField(invoice, 'TaxRegistrationNumber'),
        customerTaxId: invoiceField(invoice, 'CustomerTaxID'),
        atcud: invoiceField(invoice, 'ATCUD'),
        taxPayable: invoiceField(invoice, 'TaxPayable'),
        netTotal: invoiceField(invoice, 'NetTotal'),
        grossTotal: invoiceField(invoice, 'GrossTotal'),
      })),
      pagination: tag(xml, 'totalDocs') == null ? null : {
        totalDocuments: Number(tag(xml, 'totalDocs')),
        documentsSent: Number(tag(xml, 'totalDocsSent')),
        totalPages: Number(tag(xml, 'totalPages')),
        page: Number(tag(xml, 'nPage')),
      },
    });
  }
}
