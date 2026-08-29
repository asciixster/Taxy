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
  const optionalMoney = (name) => { const value = text(xml, name); return value == null ? null : parseFactIntMoneyCents(value); };
  return Object.freeze({ wireType: 'FactIntInvoiceResponse', idDocumento: requiredText(xml, 'IdDocumento'),
    issuerTaxId: text(xml, 'NifEmitente'), issuerName: text(xml, 'NomeEmitente'), documentNumber: text(xml, 'NumeroFatura'),
    atcud: text(xml, 'ATCUD'), date, totalCents: parseFactIntMoneyCents(requiredText(xml, 'ValorTotal')),
    vatCents: optionalMoney('ValorIva'), sectorCode: text(xml, 'CodSetor'), registrationChannel: text(xml, 'CanalRegisto'),
    registrationOrigin: text(xml, 'OrigemRegisto'), professionalActivityFlag: text(xml, 'FAmbActProfissional') });
}
export function toAtInvoiceDomain(invoice) {
  return Object.freeze({ source: 'FACTINTWS', date: invoice.date, totalCents: invoice.totalCents,
    vatCents: invoice.vatCents, sectorCode: invoice.sectorCode, sourceReferencePresent: Boolean(invoice.idDocumento) });
}
export function parseFactIntWsResponse(xml, operation) {
  if (typeof xml !== 'string' || !/<(?:[\w.-]+:)?Envelope\b/i.test(xml)) throw new TypeError('Malformed FactIntWS SOAP envelope');
  if (text(xml, 'faultcode') || text(xml, 'faultstring')) return Object.freeze({ operation, fault: Object.freeze({ code: text(xml, 'faultcode'), reason: text(xml, 'faultstring') }) });
  const responseBlock = blocks(xml, `${operation}Response`)[0];
  if (responseBlock == null) throw new TypeError(`Malformed FactIntWS response: missing ${operation}Response`);
  const result = Object.freeze({ estadoOperacao: requiredText(responseBlock, 'EstadoOperacao'), desc: requiredText(responseBlock, 'Desc') });
  const invoices = blocks(responseBlock, 'Fatura').map(parseFactIntInvoice);
  const common = { operation, fault: null, result, invoices: Object.freeze(invoices) };
  if (operation === 'EcraInicial') return Object.freeze({ ...common, totals: Object.freeze({
    pendingValidation: text(responseBlock, 'NumTotalFaturasPorValidar'),
    pendingRevenueAssociation: text(responseBlock, 'NumTotalFaturasPorAssociarReceita'),
    provisionalBenefitCents: text(responseBlock, 'ValorTotalBeneficioProvisorio') == null ? null : parseFactIntMoneyCents(text(responseBlock, 'ValorTotalBeneficioProvisorio')) }) });
  if (operation === 'DadosContribuinte') return Object.freeze({ ...common, taxpayerDataPresent: Boolean(text(responseBlock, 'Nif') || text(responseBlock, 'Nome')) });
  return Object.freeze(common);
}
