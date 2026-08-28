import assert from 'node:assert/strict';
import test from 'node:test';
import { AtInvoiceListResponse, InvoicesRequest } from '../../src/consultation.mjs';
import { AtErrorCode } from '../../src/errors.mjs';

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
  assert.deepEqual(response.pagination, { totalDocuments: 0, documentsSent: 0, totalPages: 0, page: 1 });
});

test('InvoicesResponse rejects unrecognizable payloads', () => {
  assert.throws(() => AtInvoiceListResponse.fromXml('<unknown/>'), (error) => error.code === AtErrorCode.INVALID_RESPONSE);
});

test('InvoicesResponse parses invoice fields into memory without logging them', () => {
  const response = AtInvoiceListResponse.fromXml('<InvoicesResponse><Invoice><InvoiceNo>FT 1</InvoiceNo><InvoiceDate>2025-01-02</InvoiceDate><InvoiceType>FT</InvoiceType><TaxRegistrationNumber>123456789</TaxRegistrationNumber><CustomerTaxID>987654321</CustomerTaxID><ATCUD>ABC-1</ATCUD><TaxPayable>23.00</TaxPayable><NetTotal>100.00</NetTotal><GrossTotal>123.00</GrossTotal></Invoice><EstadoOperacao>200</EstadoOperacao><Desc>OK</Desc></InvoicesResponse>');
  assert.deepEqual(response.invoices[0], {
    invoiceNo: 'FT 1', invoiceDate: '2025-01-02', invoiceType: 'FT', taxRegistrationNumber: '123456789',
    customerTaxId: '987654321', atcud: 'ABC-1', taxPayable: '23.00', netTotal: '100.00', grossTotal: '123.00',
  });
});
