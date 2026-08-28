export class AtAmount {
  constructor(cents, currency = 'EUR') { this.cents = cents; this.currency = currency; Object.freeze(this); }
}
export class AtParty {
  constructor({ role, anonymousId = null }) { this.role = role; this.anonymousId = anonymousId; Object.freeze(this); }
}
export class AtTax {
  constructor({ type, region, percentageBasisPoints = null, amount = null }) {
    Object.assign(this, { type, region, percentageBasisPoints, amount }); Object.freeze(this);
  }
}
export class AtInvoice {
  constructor({ anonymousId, issueDate, type, netTotal, taxPayable, grossTotal }) {
    Object.assign(this, { anonymousId, issueDate, type, netTotal, taxPayable, grossTotal }); Object.freeze(this);
  }
}
