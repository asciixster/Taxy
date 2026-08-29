import assert from 'node:assert/strict';
import test from 'node:test';
import { FactIntWsClient, FactIntWsRepository, FactIntWsResultClassification,
  classifyFactIntWsParsedResult } from '../../src/factintws_client.mjs';
import { FactIntInvoicePageResponse, FactIntPendingInvoiceResponse, FactIntSectorResponse,
  FactIntWsParsingError, factIntInvoiceFieldPresence, opaqueCode, parseFactIntDateOnly,
  parseFactIntInvoice, parseFactIntMoneyCents, parseFactIntWsResponse, toAtInvoiceDomain } from '../../src/factintws_parser.mjs';
import { FACTINTWS_ENDPOINT_8443, FACTINTWS_NAMESPACE, FactIntWsOperation,
  factIntWsInvoiceOperationEvidence, serializeFactIntWsOperation } from '../../src/factintws.mjs';

const channel = { system: 'A', version: 'Android SDK: synthetic' };
const credentials = { encryptedDigest: 'digest', encryptedPassword: 'password', encryptedNonce: 'nonce', created: '2026-08-29T12:34:56.789Z' };
const invoice = (extra = '') => `<Fatura><IdDocumento>SYNTHETIC-ID</IdDocumento><DataDocumento>2026-01-02</DataDocumento><ValorTotal>23.45</ValorTotal>${extra}</Fatura>`;
const response = (operation, body, state = '200') => `<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"><env:Body><${operation}Response>${body}<WSResult><EstadoOperacao>${state}</EstadoOperacao><Desc>Synthetic</Desc></WSResult></${operation}Response></env:Body></env:Envelope>`;

test('invoice operation evidence records exact official-app SOAPActions', () => {
  assert.equal(factIntWsInvoiceOperationEvidence.FaturasPorClassificar.soapAction, `${FACTINTWS_NAMESPACE}/FaturasPorClassificar`);
  assert.equal(factIntWsInvoiceOperationEvidence.FaturasPorSetor.soapAction, `${FACTINTWS_NAMESPACE}/FaturasPorSetor`);
});
test('pending request rejects invalid year before transport', () => assert.throws(() => serializeFactIntWsOperation('FaturasPorClassificar', { nif: '000000000', year: 'x', channel }), /Ano/));
test('sector request rejects unknown shaped sector code', () => assert.throws(() => serializeFactIntWsOperation('FaturasPorSetor', { nif: '000000000', year: '2026', sector: '5', index: 0, channel }), /CodSetor/));
test('sector request rejects negative pagination index', () => assert.throws(() => serializeFactIntWsOperation('FaturasPorSetor', { nif: '000000000', year: '2026', sector: 'C05', index: -1, channel }), /Indice/));
test('money parser supports comma decimals', () => assert.equal(parseFactIntMoneyCents('23,45'), 2345));
test('money parser supports exact requested vectors', () => assert.deepEqual(['0.00', '0.01', '1.00', '23.45', '1000.99'].map(parseFactIntMoneyCents), [0, 1, 100, 2345, 100099]));
test('money parser rejects exponent notation', () => assert.throws(() => parseFactIntMoneyCents('1e2'), FactIntWsParsingError));
test('money parser rejects three decimal places', () => assert.throws(() => parseFactIntMoneyCents('1.001'), FactIntWsParsingError));
test('date-only parser preserves date without timezone conversion', () => assert.equal(parseFactIntDateOnly('2026-02-28'), '2026-02-28'));
test('date-only parser rejects impossible calendar date', () => assert.throws(() => parseFactIntDateOnly('2026-02-30'), FactIntWsParsingError));
test('date-only parser rejects timestamps', () => assert.throws(() => parseFactIntDateOnly('2026-01-02T00:00:00Z'), FactIntWsParsingError));
test('unknown status preserves raw code', () => assert.deepEqual(opaqueCode('NEW_CODE'), { kind: 'unknown', rawCode: 'NEW_CODE' }));
test('known status uses explicit mapping only', () => assert.deepEqual(opaqueCode('S', { S: true }), { kind: 'known', code: 'S', value: true }));
test('pending wire model is distinct and marks pending classification', () => {
  const parsed = parseFactIntInvoice(invoice(), { pendingClassification: true });
  assert(parsed instanceof FactIntPendingInvoiceResponse); assert.equal(parsed.pendingClassification, true);
});
test('field presence excludes direct identifiers', () => {
  const presence = factIntInvoiceFieldPresence(parseFactIntInvoice(invoice('<NifEmitente>000000000</NifEmitente>')));
  assert.equal('issuerTaxId' in presence, false); assert.equal('idDocumento' in presence, false); assert.equal(presence.totalCents, true);
});
test('domain model excludes issuer and document identifiers', () => {
  const domain = toAtInvoiceDomain(parseFactIntInvoice(invoice('<NifEmitente>000000000</NifEmitente><NomeEmitente>Synthetic</NomeEmitente>')));
  assert.equal('issuerTaxId' in domain, false); assert.equal('issuerName' in domain, false); assert.equal('idDocumento' in domain, false);
});
test('pending response returns typed page and exact invoice count', () => {
  const parsed = parseFactIntWsResponse(response('FaturasPorClassificar', `<ListaFaturasPorClassificar>${invoice()}${invoice()}</ListaFaturasPorClassificar>`), 'FaturasPorClassificar');
  assert(parsed instanceof FactIntInvoicePageResponse); assert.equal(parsed.invoices.length, 2);
});
test('sector response returns typed sector page and pagination metadata', () => {
  const parsed = parseFactIntWsResponse(response('FaturasPorSetor', `<ListaFaturasPorSetor>${invoice()}</ListaFaturasPorSetor><Indice>0</Indice><TotalPaginas>3</TotalPaginas>`), 'FaturasPorSetor');
  assert(parsed instanceof FactIntSectorResponse); assert.equal(parsed.totalPages, 3); assert.equal(parsed.index, 0);
});
test('malformed second invoice reports failed index instead of dropping it', () => {
  const xml = response('FaturasPorSetor', `<ListaFaturasPorSetor>${invoice()}<Fatura><IdDocumento>SYNTHETIC-2</IdDocumento><DataDocumento>bad</DataDocumento><ValorTotal>1.00</ValorTotal></Fatura></ListaFaturasPorSetor>`);
  assert.throws(() => parseFactIntWsResponse(xml, 'FaturasPorSetor'), (error) => error.code === 'PARSING_ERROR' && error.failedIndex === 1);
});
test('empty result classification remains success', () => assert.equal(classifyFactIntWsParsedResult({ fault: null, result: {}, invoices: [] }), FactIntWsResultClassification.SUCCESS_EMPTY_RESULT));
test('non-empty result classification is success non-empty', () => assert.equal(classifyFactIntWsParsedResult({ fault: null, result: {}, invoices: [{}] }), FactIntWsResultClassification.SUCCESS_NON_EMPTY_RESULT));
test('authentication and authorization faults remain distinct', () => {
  assert.equal(classifyFactIntWsParsedResult({ fault: { reason: 'invalid password' } }), FactIntWsResultClassification.AUTH_ERROR);
  assert.equal(classifyFactIntWsParsedResult({ fault: { reason: 'access forbidden' } }), FactIntWsResultClassification.AUTHORIZATION_ERROR);
});
test('client serializes and parses without exposing XML to repository callers', async () => {
  let seen;
  const client = new FactIntWsClient({ endpoint: FACTINTWS_ENDPOINT_8443, transport: async (request) => { seen = request; return { httpStatus: 200, body: response('FaturasPorClassificar', '<ListaFaturasPorClassificar/>') }; } });
  const repository = new FactIntWsRepository(client);
  const result = await repository.pendingInvoices({ username: '000000000', credentials, input: { nif: '000000000', year: '2026', channel } });
  assert.equal(seen.contract.headers.SOAPAction, `${FACTINTWS_NAMESPACE}/FaturasPorClassificar`);
  assert.equal(result.classification, FactIntWsResultClassification.SUCCESS_EMPTY_RESULT); assert.deepEqual(result.domainInvoices, []);
});
test('repository maps sector invoices to common domain', async () => {
  const client = new FactIntWsClient({ transport: async () => ({ httpStatus: 200, body: response('FaturasPorSetor', `<ListaFaturasPorSetor>${invoice('<CodSetor>C05</CodSetor>')}</ListaFaturasPorSetor>`) }) });
  const repository = new FactIntWsRepository(client);
  const result = await repository.invoicesBySector({ username: '000000000', credentials, input: { nif: '000000000', year: '2026', sector: 'C05', index: 0, channel }, sectorLabel: 'Synthetic sector' });
  assert.equal(result.domainInvoices[0].source, 'FACTINTWS'); assert.equal(result.domainInvoices[0].sectorCode, 'C05');
});
test('write operations remain absent from repository API', () => {
  const repository = new FactIntWsRepository(new FactIntWsClient({ transport: async () => null }));
  assert.equal(repository.classifyInvoices, undefined); assert.equal(repository.registerInvoice, undefined);
});
test('live harness is explicit opt-in and does not paginate automatically', async () => {
  const source = await import('node:fs').then(({ readFileSync }) => readFileSync(new URL('../../bin/factintws-invoices-live.mjs', import.meta.url), 'utf8'));
  assert(source.includes("AT_LIVE_TEST !== '1'")); assert.equal(source.includes('page 2'), false); assert.equal(source.includes('retry'), false);
  assert(source.includes("index: '0'"));
});
