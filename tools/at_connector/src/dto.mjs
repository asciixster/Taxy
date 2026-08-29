export class AtAmount {
  constructor(cents, currency = 'EUR') {
    if (!Number.isSafeInteger(cents)) throw new TypeError('AtAmount cents must be a safe integer');
    this.cents = cents; this.currency = currency; Object.freeze(this);
  }
}
export class AtParty {
  constructor({ role, anonymousId = null }) { this.role = role; this.anonymousId = anonymousId; Object.freeze(this); }
}
export class AtTax {
  constructor({ type, region, percentageBasisPoints = null, amount = null }) {
    Object.assign(this, { type, region, percentageBasisPoints, amount }); Object.freeze(this);
  }
}
export class AtDateOnly {
  constructor(value) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(value || '') || Number.isNaN(Date.parse(`${value}T00:00:00Z`)) || new Date(`${value}T00:00:00Z`).toISOString().slice(0, 10) !== value) {
      throw new TypeError('AtDateOnly must use a real YYYY-MM-DD calendar date');
    }
    this.value = value;
    Object.freeze(this);
  }

  toString() { return this.value; }
}

export class AtInvoice {
  constructor({ anonymousInvoiceIndex, date = null, documentType = null, totalCents = null, taxableCents = null, vatCents = null, vatRatesBasisPoints = [], sector = null, classificationStatus = null, pendingStatus = null, source = null, issuerPresent = false, documentReferencePresent = false, invoiceIdentifierPresent = false, fieldPresence = {} }) {
    for (const [field, value] of [['totalCents', totalCents], ['taxableCents', taxableCents], ['vatCents', vatCents]]) {
      if (value != null && !Number.isSafeInteger(value)) throw new TypeError(`${field} must be integer cents`);
    }
    Object.assign(this, {
      anonymousInvoiceIndex,
      date,
      documentType,
      totalCents,
      taxableCents,
      vatCents,
      vatRatesBasisPoints: Object.freeze([...vatRatesBasisPoints]),
      sector,
      classificationStatus,
      pendingStatus,
      source,
      issuerPresent: issuerPresent === true,
      documentReferencePresent: documentReferencePresent === true,
      invoiceIdentifierPresent: invoiceIdentifierPresent === true,
      fieldPresence: Object.freeze({ ...fieldPresence }),
    });
    Object.freeze(this);
  }
}

export class AtInvoicePage {
  constructor({ totalDocuments = null, documentsSent = null, totalPages = null, page = null } = {}) {
    for (const [field, value] of Object.entries({ totalDocuments, documentsSent, totalPages, page })) {
      if (value != null && (!Number.isSafeInteger(value) || value < 0)) throw new TypeError(`${field} must be a non-negative integer`);
    }
    Object.assign(this, { totalDocuments, documentsSent, totalPages, page });
    Object.freeze(this);
  }
}

export class AtInvoiceQueryResult {
  constructor({ operationStatus, description = null, invoices = [], pagination = null, observedFields = [], notAvailableFields = [], unknownElements = [] }) {
    if (!Number.isSafeInteger(operationStatus)) throw new TypeError('operationStatus must be an integer');
    Object.assign(this, {
      operationStatus,
      description,
      invoices: Object.freeze([...invoices]),
      pagination,
      observedFields: Object.freeze([...observedFields]),
      notAvailableFields: Object.freeze([...notAvailableFields]),
      unknownElements: Object.freeze([...unknownElements]),
    });
    Object.freeze(this);
  }
}
