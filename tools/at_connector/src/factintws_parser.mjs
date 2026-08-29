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
  if (value == null) throw new TypeError(`Malformed FactIntWS response: missing ${localName}`);
  return value;
}
function optionalMoney(xml, localName) {
  const value = text(xml, localName);
  return value == null ? null : parseFactIntMoneyCents(value);
}
function optionalInteger(xml, localName) {
  const value = text(xml, localName);
  if (value == null) return null;
  if (!/^\d+$/.test(value)) throw new TypeError(`Malformed FactIntWS response: invalid ${localName}`);
  return Number(value);
}
export function parseFactIntMoneyCents(value) {
  if (!/^-?\d+(?:[.,]\d{1,2})?$/.test(String(value))) throw new TypeError('Invalid FactIntWS monetary value');
  const normalized = String(value).replace(',', '.');
  const negative = normalized.startsWith('-');
  const [wholeRaw, fractionRaw = ''] = normalized.replace('-', '').split('.');
  const cents = (BigInt(wholeRaw) * 100n) + BigInt(fractionRaw.padEnd(2, '0'));
  const signed = negative ? -cents : cents;
  if (signed > BigInt(Number.MAX_SAFE_INTEGER) || signed < BigInt(Number.MIN_SAFE_INTEGER)) throw new RangeError('FactIntWS monetary value exceeds safe cents range');
  return Number(signed);
}
export function parseFactIntInvoice(xml) {
  const date = requiredText(xml, 'DataDocumento');
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) throw new TypeError('Malformed FactIntWS response: invalid DataDocumento');
  return Object.freeze({ wireType: 'FactIntInvoiceResponse', idDocumento: requiredText(xml, 'IdDocumento'),
    issuerTaxId: text(xml, 'NifEmitente'), issuerName: text(xml, 'NomeEmitente'), documentNumber: text(xml, 'NumeroFatura'),
    documentType: text(xml, 'TipoDocumento'), atcud: text(xml, 'ATCUD'), date,
    totalCents: parseFactIntMoneyCents(requiredText(xml, 'ValorTotal')),
    vatCents: optionalMoney(xml, 'ValorIva'), consumerIncentiveCents: optionalMoney(xml, 'ValorIncentivoConsumo'),
    generalExpenseBenefitCents: optionalMoney(xml, 'ValorProvisorioBeneficioDespesasGerais'),
    sectorBenefitCents: optionalMoney(xml, 'ValorProvisorioBeneficioSetor'), sectorCode: text(xml, 'CodSetor'),
    registrationChannel: text(xml, 'CanalRegisto'), originChannel: text(xml, 'CanalOrigem'),
    registrationOrigin: text(xml, 'OrigemRegisto'), recipe: text(xml, 'Receita'),
    professionalActivityFlag: text(xml, 'FAmbActProfissional'),
    buyerCanManipulateInvoices: text(xml, 'AdquirentePodeManipularFaturas') });
}
export function toAtInvoiceDomain(invoice) {
  return Object.freeze({ source: 'FACTINTWS', date: invoice.date, totalCents: invoice.totalCents,
    vatCents: invoice.vatCents, sectorCode: invoice.sectorCode, sourceReferencePresent: Boolean(invoice.idDocumento) });
}
export function parseFactIntWsResponse(xml, operation) {
  if (typeof xml !== 'string' || !/<(?:[\w.-]+:)?Envelope\b/i.test(xml)) throw new TypeError('Malformed FactIntWS SOAP envelope');
  if (text(xml, 'faultcode') || text(xml, 'faultstring')) return Object.freeze({ operation, fault: Object.freeze({ code: text(xml, 'faultcode'), reason: text(xml, 'faultstring') }) });
  if (text(xml, 'AuthenticationFailed') || text(xml, 'AuthenticationException')) {
    return Object.freeze({ operation, fault: Object.freeze({ code: 'AuthenticationFailed', reason: text(xml, 'message') }) });
  }
  const responseBlock = blocks(xml, `${operation}Response`)[0];
  if (responseBlock == null) throw new TypeError(`Malformed FactIntWS response: missing ${operation}Response`);
  const result = Object.freeze({ estadoOperacao: requiredText(responseBlock, 'EstadoOperacao'), desc: requiredText(responseBlock, 'Desc') });
  const invoices = blocks(responseBlock, 'Fatura').map(parseFactIntInvoice);
  const common = { operation, fault: null, result, invoices: Object.freeze(invoices) };
  if (operation === 'EcraInicial') return Object.freeze({ ...common,
    buyerCanManipulateInvoices: text(responseBlock, 'AdquirentePodeManipularFaturas'),
    canShowPreviousYear: text(responseBlock, 'PodeMostrarAnoAnterior'),
    totals: Object.freeze({ pendingValidation: optionalInteger(responseBlock, 'NumTotalFaturasPorValidar'),
      pendingRevenueAssociation: optionalInteger(responseBlock, 'NumTotalFaturasPorAssociarReceita'),
      provisionalBenefitCents: optionalMoney(responseBlock, 'ValorTotalBeneficioProvisorio') }),
    sectors: Object.freeze(blocks(responseBlock, 'Setor').map((sector) => Object.freeze({ sectorCode: text(sector, 'CodSetor'),
      provisionalBenefitCents: optionalMoney(sector, 'ValorBeneficioProvisorioPorSetor'),
      totalExpensesCents: optionalMoney(sector, 'ValorTotalDespesas'), totalVatExpensesCents: optionalMoney(sector, 'ValorTotalIvaDespesas') }))) });
  if (operation === 'DadosContribuinte') return Object.freeze({ ...common,
    taxpayer: Object.freeze({ taxId: text(responseBlock, 'Nif'), name: text(responseBlock, 'Nome'), sensitive: true }),
    taxpayerDataPresent: Boolean(text(responseBlock, 'Nif') || text(responseBlock, 'Nome')) });
  if (operation === 'FaturasPorSetor') return Object.freeze({ ...common, summary: Object.freeze({
    totalExpensesCents: optionalMoney(responseBlock, 'ValorTotalDespesas'),
    provisionalBenefitCents: optionalMoney(responseBlock, 'ValorTotalBeneficioProvisorio') }) });
  return Object.freeze(common);
}
