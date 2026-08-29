function decodeXml(value = '') {
  return value.replaceAll('&lt;', '<').replaceAll('&gt;', '>').replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'").replaceAll('&amp;', '&').trim();
}
function blocks(xml, localName) {
  const escaped = localName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return [...xml.matchAll(new RegExp(`<(?:[\\w.-]+:)?${escaped}(?:\\s[^>]*)?>([\\s\\S]*?)<\\/(?:[\\w.-]+:)?${escaped}\\s*>`, 'gi'))].map((match) => match[1]);
}
function text(xml, localName) {
  const value = blocks(xml, localName)[0];
  return value == null ? null : decodeXml(value.replace(/<[^>]+>/g, ''));
}
function requiredText(xml, localName) {
  const value = text(xml, localName);
  if (value == null || value === '') throw new FactIntWsParsingError(localName, 'non-empty text', 'missing');
  return value;
}
function optionalMoney(xml, localName) {
  const value = text(xml, localName);
  return value == null || value === '' ? null : parseFactIntMoneyCents(value);
}
function optionalInteger(xml, localName) {
  const value = text(xml, localName);
  if (value == null || value === '') return null;
  if (!/^\d+$/.test(value)) throw new FactIntWsParsingError(localName, 'non-negative integer', 'invalid text');
  const parsed = Number(value);
  if (!Number.isSafeInteger(parsed)) throw new FactIntWsParsingError(localName, 'safe integer', 'out of range');
  return parsed;
}

export class FactIntWsParsingError extends Error {
  constructor(field, expectedType, observedShape, { failedIndex = null } = {}) {
    super(`Malformed FactIntWS response at ${field}: expected ${expectedType}`);
    this.name = 'FactIntWsParsingError'; this.code = 'PARSING_ERROR'; this.field = field;
    this.expectedType = expectedType; this.observedShape = observedShape; this.failedIndex = failedIndex;
  }
}

export function parseFactIntMoneyCents(value) {
  const raw = String(value);
  if (!/^-?\d+(?:[.,]\d{1,2})?$/.test(raw)) throw new FactIntWsParsingError('money', 'decimal with at most two fraction digits', 'invalid decimal');
  const normalized = raw.replace(',', '.');
  const negative = normalized.startsWith('-');
  const [wholeRaw, fractionRaw = ''] = normalized.replace('-', '').split('.');
  const cents = (BigInt(wholeRaw) * 100n) + BigInt(fractionRaw.padEnd(2, '0'));
  const signed = negative ? -cents : cents;
  if (signed > BigInt(Number.MAX_SAFE_INTEGER) || signed < BigInt(Number.MIN_SAFE_INTEGER)) throw new FactIntWsParsingError('money', 'safe integer cents', 'out of range');
  return Number(signed);
}

export function parseFactIntDateOnly(value) {
  const raw = String(value);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(raw)) throw new FactIntWsParsingError('DataDocumento', 'YYYY-MM-DD date-only', 'invalid date text');
  const [year, month, day] = raw.split('-').map(Number);
  const date = new Date(Date.UTC(year, month - 1, day));
  if (date.getUTCFullYear() !== year || date.getUTCMonth() !== month - 1 || date.getUTCDate() !== day) throw new FactIntWsParsingError('DataDocumento', 'valid calendar date', 'invalid calendar date');
  return raw;
}

export function opaqueCode(rawCode, known = {}) {
  if (rawCode == null || rawCode === '') return null;
  return Object.freeze(Object.hasOwn(known, rawCode) ? { kind: 'known', code: rawCode, value: known[rawCode] } : { kind: 'unknown', rawCode });
}

export class FactIntInvoiceResponse { constructor(fields) { Object.assign(this, fields); Object.freeze(this); } }
export class FactIntPendingInvoiceResponse extends FactIntInvoiceResponse {
  constructor(fields) { super({ ...fields, pendingClassification: true, wireType: 'FactIntPendingInvoiceResponse' }); }
}
export class FactIntInvoicePageResponse {
  constructor({ operation, result, invoices, index = null, totalPages = null, summary = null }) {
    Object.assign(this, { operation, result, invoices: Object.freeze(invoices), index, totalPages, summary }); Object.freeze(this);
  }
}
export class FactIntSectorResponse extends FactIntInvoicePageResponse {}
export class AtInvoiceDomain { constructor(fields) { Object.assign(this, fields); Object.freeze(this); } }

export function parseFactIntInvoice(xml, { pendingClassification = false } = {}) {
  const fields = { wireType: 'FactIntInvoiceResponse', idDocumento: requiredText(xml, 'IdDocumento'),
    issuerTaxId: text(xml, 'NifEmitente'), issuerName: text(xml, 'NomeEmitente'), documentNumber: text(xml, 'NumeroFatura'),
    documentType: opaqueCode(text(xml, 'TipoDocumento')), atcud: text(xml, 'ATCUD'),
    date: parseFactIntDateOnly(requiredText(xml, 'DataDocumento')),
    totalCents: parseFactIntMoneyCents(requiredText(xml, 'ValorTotal')),
    taxableCents: optionalMoney(xml, 'ValorTributavel'), vatCents: optionalMoney(xml, 'ValorIva'),
    consumerIncentiveCents: optionalMoney(xml, 'ValorIncentivoConsumo'),
    generalExpenseBenefitCents: optionalMoney(xml, 'ValorProvisorioBeneficioDespesasGerais'),
    sectorBenefitCents: optionalMoney(xml, 'ValorProvisorioBeneficioSetor'), sectorCode: text(xml, 'CodSetor'),
    sectorStatus: opaqueCode(text(xml, 'CodSetor')), registrationChannel: opaqueCode(text(xml, 'CanalRegisto')),
    originChannel: opaqueCode(text(xml, 'CanalOrigem')), registrationOrigin: opaqueCode(text(xml, 'OrigemRegisto')),
    recipe: opaqueCode(text(xml, 'Receita'), { S: true, N: false }), professionalActivityFlag: opaqueCode(text(xml, 'FAmbActProfissional'), { S: true, N: false }),
    buyerCanManipulateInvoices: opaqueCode(text(xml, 'AdquirentePodeManipularFaturas'), { S: true, N: false }),
    pendingClassification };
  return pendingClassification ? new FactIntPendingInvoiceResponse(fields) : new FactIntInvoiceResponse(fields);
}

export function factIntInvoiceFieldPresence(invoice) {
  const sensitive = new Set(['issuerTaxId', 'issuerName', 'idDocumento', 'documentNumber', 'atcud']);
  return Object.freeze(Object.fromEntries(Object.entries(invoice).filter(([key]) => !sensitive.has(key)).map(([key, value]) => [key, value != null])));
}

export function toAtInvoiceDomain(invoice, { sectorLabel = null } = {}) {
  return new AtInvoiceDomain({ source: 'FACTINTWS', date: invoice.date, totalCents: invoice.totalCents,
    taxableCents: invoice.taxableCents, vatCents: invoice.vatCents, sectorCode: invoice.sectorCode, sectorLabel,
    classificationStatus: invoice.sectorStatus, professionalActivityFlag: invoice.professionalActivityFlag,
    canBeManipulated: invoice.buyerCanManipulateInvoices, channel: invoice.registrationChannel,
    documentType: invoice.documentType, pendingClassification: invoice.pendingClassification });
}

function parseInvoices(responseBlock, operation) {
  return blocks(responseBlock, 'Fatura').map((block, index) => {
    try { return parseFactIntInvoice(block, { pendingClassification: operation === 'FaturasPorClassificar' }); }
    catch (error) { if (error instanceof FactIntWsParsingError) error.failedIndex = index; throw error; }
  });
}

export function parseFactIntWsResponse(xml, operation) {
  if (typeof xml !== 'string' || !/<(?:[\w.-]+:)?Envelope\b/i.test(xml)) throw new FactIntWsParsingError('Envelope', 'SOAP Envelope', 'missing');
  if (text(xml, 'faultcode') || text(xml, 'faultstring')) return Object.freeze({ operation, fault: Object.freeze({ code: text(xml, 'faultcode'), reason: text(xml, 'faultstring') }) });
  if (text(xml, 'AuthenticationFailed') || text(xml, 'AuthenticationException')) return Object.freeze({ operation, fault: Object.freeze({ code: 'AuthenticationFailed', reason: text(xml, 'message') }) });
  const responseBlock = blocks(xml, `${operation}Response`)[0];
  if (responseBlock == null) throw new FactIntWsParsingError(`${operation}Response`, 'operation response root', 'missing');
  const result = Object.freeze({ estadoOperacao: requiredText(responseBlock, 'EstadoOperacao'), desc: requiredText(responseBlock, 'Desc') });
  const invoices = parseInvoices(responseBlock, operation);
  if (operation === 'EcraInicial') return Object.freeze({ operation, fault: null, result, invoices: Object.freeze(invoices),
    buyerCanManipulateInvoices: opaqueCode(text(responseBlock, 'AdquirentePodeManipularFaturas'), { S: true, N: false }),
    canShowPreviousYear: opaqueCode(text(responseBlock, 'PodeMostrarAnoAnterior'), { S: true, N: false }),
    totals: Object.freeze({ pendingValidation: optionalInteger(responseBlock, 'NumTotalFaturasPorValidar'),
      pendingRevenueAssociation: optionalInteger(responseBlock, 'NumTotalFaturasPorAssociarReceita'), provisionalBenefitCents: optionalMoney(responseBlock, 'ValorTotalBeneficioProvisorio') }),
    sectors: Object.freeze(blocks(responseBlock, 'Setor').map((sector) => Object.freeze({ sectorCode: text(sector, 'CodSetor'),
      provisionalBenefitCents: optionalMoney(sector, 'ValorBeneficioProvisorioPorSetor'), totalExpensesCents: optionalMoney(sector, 'ValorTotalDespesas'),
      totalVatExpensesCents: optionalMoney(sector, 'ValorTotalIvaDespesas') }))) });
  if (operation === 'DadosContribuinte') return Object.freeze({ operation, fault: null, result, invoices: Object.freeze(invoices),
    taxpayer: Object.freeze({ taxId: text(responseBlock, 'Nif'), name: text(responseBlock, 'Nome'), sensitive: true }), taxpayerDataPresent: Boolean(text(responseBlock, 'Nif') || text(responseBlock, 'Nome')) });
  const totalPages = optionalInteger(responseBlock, 'TotalPaginas');
  const index = optionalInteger(responseBlock, 'Indice');
  const summary = operation === 'FaturasPorSetor' ? Object.freeze({ totalExpensesCents: optionalMoney(responseBlock, 'ValorTotalDespesas'),
    provisionalBenefitCents: optionalMoney(responseBlock, 'ValorTotalBeneficioProvisorio') }) : null;
  const fields = { operation, result, invoices, index, totalPages, summary };
  return operation === 'FaturasPorSetor' ? new FactIntSectorResponse(fields) : new FactIntInvoicePageResponse(fields);
}
