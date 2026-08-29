import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import { AUDITED_INVOICE_FIELDS, AtInvoiceListResponse, InvoicesRequest, parseInvoiceDateOnly, parseMoneyToCents } from '../../src/consultation.mjs';
import { AtErrorCode } from '../../src/errors.mjs';
import { redact } from '../../src/redaction.mjs';

const oneInvoiceXml = readFileSync(new URL('../fixtures/sanitized/invoice-response-one-synthetic.xml', import.meta.url), 'utf8');

test('InvoicesRequest models only the officially documented minimum fields', () => {
  const request = new InvoicesRequest({ customerTaxId: '123456789', startDate: '2025-01-01', endDate: '2025-01-31', pagination: { page: 1, documentsPerPage: 300 } });
  assert.deepEqual(request.toSanitizedJSON(), {
    requestRoot: 'InvoicesRequest', party: 'customer:[REDACTED_NIF]', startDate: '2025-01-01', endDate: '2025-01-31', pagination: { page: 1, documentsPerPage: 300 },
  });
});

test('InvoicesRequest requires exactly one party and documented pagination limits', () => {
  assert.throws(() => new InvoicesRequest({ startDate: '2025-01-01', endDate: '2025-01-31' }), /Exactly one/);
  assert.throws(() => new InvoicesRequest({ customerTaxId: '123456789', startDate: '2025-01-01', endDate: '2025-01-31', pagination: { page: 1, documentsPerPage: 5001 } }), /1\.\.5000/);
});

test('XML serialization fails closed without an official namespace', () => {
  const request = new InvoicesRequest({ taxRegistrationNumber: '123456789', startDate: '2025-01-01', endDate: '2025-01-31' });
  assert.throws(() => request.toXml(null), (error) => error.code === AtErrorCode.SOAP_CONTRACT_UNRESOLVED);
});

test('InvoicesResponse parser maps documented status and pagination fields', () => {
  const response = AtInvoiceListResponse.fromXml('<InvoicesResponse><PaginationTotal><totalDocs>0</totalDocs><totalDocsSent>0</totalDocsSent><totalPages>0</totalPages><nPage>1</nPage></PaginationTotal><estadoExecucao><EstadoOperacao>200</EstadoOperacao><Desc>Operação efetuada com sucesso.</Desc></estadoExecucao></InvoicesResponse>');
  assert.equal(response.operationStatus, 200);
  assert.equal(response.description, 'Operação efetuada com sucesso.');
  assert.deepEqual({ ...response.pagination }, { totalDocuments: 0, documentsSent: 0, totalPages: 0, page: 1 });
});

test('InvoicesResponse rejects unrecognizable payloads', () => {
  assert.throws(() => AtInvoiceListResponse.fromXml('<unknown/>'), (error) => error.code === AtErrorCode.INVALID_RESPONSE);
});

test('InvoicesResponse parses invoice fields into memory without logging them', () => {
  const response = AtInvoiceListResponse.fromXml('<InvoicesResponse><Invoice><InvoiceNo>FT 1</InvoiceNo><InvoiceDate>2025-01-02</InvoiceDate><InvoiceType>FT</InvoiceType><TaxRegistrationNumber>123456789</TaxRegistrationNumber><CustomerTaxID>987654321</CustomerTaxID><ATCUD>ABC-1</ATCUD><TaxPayable>23.00</TaxPayable><NetTotal>100.00</NetTotal><GrossTotal>123.00</GrossTotal></Invoice><EstadoOperacao>200</EstadoOperacao><Desc>OK</Desc></InvoicesResponse>');
  assert.equal(response.invoices[0].date, '2025-01-02');
  assert.equal(response.invoices[0].totalCents, 12300);
  assert.equal(response.invoices[0].taxableCents, 10000);
  assert.equal(response.invoices[0].vatCents, 2300);
  assert.equal(response.invoices[0].issuerPresent, true);
  assert.equal(response.invoices[0].documentReferencePresent, true);
  assert.equal('taxRegistrationNumber' in response.invoices[0], false);
  assert.equal('invoiceNo' in response.invoices[0], false);
});

test('money parsing is exact integer cents for required boundary examples', () => {
  assert.deepEqual(['0.00', '0.01', '1.00', '23.45', '1000.99'].map((value) => parseMoneyToCents(value)), [0, 1, 100, 2345, 100099]);
  assert.equal(parseMoneyToCents('23,45'), 2345);
  assert.throws(() => parseMoneyToCents('1.001'), (error) => error.code === AtErrorCode.INVALID_RESPONSE);
});

test('invoice dates stay date-only and reject invalid calendar dates', () => {
  assert.equal(parseInvoiceDateOnly('2025-02-03'), '2025-02-03');
  assert.throws(() => parseInvoiceDateOnly('2025-02-30'), (error) => error.code === AtErrorCode.INVALID_RESPONSE);
  assert.throws(() => parseInvoiceDateOnly('2025-02-03T00:00:00Z'), (error) => error.code === AtErrorCode.INVALID_RESPONSE);
});

test('sanitized fixture parses one typed invoice with field-presence audit', () => {
  const response = AtInvoiceListResponse.fromXml(oneInvoiceXml);
  assert.equal(response.invoices.length, 1);
  assert.equal(response.invoices[0].anonymousInvoiceIndex, 1);
  assert.equal(response.invoices[0].totalCents, 102444);
  assert.equal(response.invoices[0].taxableCents, 100099);
  assert.equal(response.invoices[0].vatCents, 2345);
  assert.deepEqual(response.invoices[0].vatRatesBasisPoints, [2300]);
  assert.deepEqual({ ...response.pagination }, { totalDocuments: 1, documentsSent: 1, totalPages: 1, page: 1 });
  assert.deepEqual(response.notAvailableFields, []);
  assert.deepEqual(response.unknownElements, ['FutureField']);
});

test('multiple invoices are never silently collapsed', () => {
  const invoiceBlock = oneInvoiceXml.match(/<Invoice>[\s\S]*?<\/Invoice>/)[0];
  const multiple = oneInvoiceXml.replace('<totalDocs>1</totalDocs>', '<totalDocs>2</totalDocs>')
    .replace('<totalDocsSent>1</totalDocsSent>', '<totalDocsSent>2</totalDocsSent>')
    .replace('</Invoice>', `</Invoice>${invoiceBlock}`);
  const response = AtInvoiceListResponse.fromXml(multiple);
  assert.equal(response.invoices.length, 2);
  assert.deepEqual(response.invoices.map((invoice) => invoice.anonymousInvoiceIndex), [1, 2]);
});

test('optional fields can be absent and are reported as NOT_AVAILABLE', () => {
  const response = AtInvoiceListResponse.fromXml('<InvoicesResponse><Invoice><InvoiceDate>2025-01-02</InvoiceDate><GrossTotal>1.00</GrossTotal></Invoice><EstadoOperacao>200</EstadoOperacao></InvoicesResponse>');
  assert.equal(response.invoices[0].vatCents, null);
  assert(response.notAvailableFields.includes('vat'));
  assert(response.notAvailableFields.includes('issuer'));
});

test('unexpected enum values remain explicit instead of disappearing', () => {
  const xml = '<InvoicesResponse><Invoice><InvoiceDate>2025-01-02</InvoiceDate><GrossTotal>1.00</GrossTotal><ClassificationStatus>UNRECOGNIZED_RUNTIME_VALUE</ClassificationStatus></Invoice><EstadoOperacao>200</EstadoOperacao></InvoicesResponse>';
  const response = AtInvoiceListResponse.fromXml(xml);
  assert.equal(response.invoices[0].classificationStatus, 'UNRECOGNIZED_RUNTIME_VALUE');
  assert.equal(response.invoices[0].fieldPresence.classificationStatus, true);
});

test('malformed invoice and declared count mismatches fail closed', () => {
  assert.throws(() => AtInvoiceListResponse.fromXml('<InvoicesResponse><Invoice><Unknown>x</Unknown></Invoice><EstadoOperacao>200</EstadoOperacao></InvoicesResponse>'), (error) => error.code === AtErrorCode.INVALID_RESPONSE && error.details.anonymousInvoiceIndex === 1);
  assert.throws(() => AtInvoiceListResponse.fromXml('<InvoicesResponse><totalDocsSent>1</totalDocsSent><EstadoOperacao>200</EstadoOperacao></InvoicesResponse>'), (error) => error.code === AtErrorCode.INVALID_RESPONSE);
});

test('typed invoice output and redaction expose no fiscal identifiers', () => {
  const response = AtInvoiceListResponse.fromXml(oneInvoiceXml);
  const safe = JSON.stringify(redact(response));
  assert(!safe.includes('ANON_ISSUER'));
  assert(!safe.includes('ANON_DOCUMENT'));
  assert(!safe.includes('ANON_INVOICE'));
  assert.equal(response.invoices[0].issuerPresent, true);
  assert.deepEqual(AUDITED_INVOICE_FIELDS, ['date', 'issuer', 'documentType', 'documentReference', 'total', 'taxable', 'vat', 'vatRate', 'sector', 'classificationStatus', 'pendingStatus', 'invoiceIdentifier', 'source']);
});
