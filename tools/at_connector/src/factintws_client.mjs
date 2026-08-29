import { buildFactIntWsEnvelope, FACTINTWS_ENDPOINT_8443, factIntWsHttpContract,
  FactIntWsOperation } from './factintws.mjs';
import { parseFactIntWsResponse, toAtInvoiceDomain } from './factintws_parser.mjs';

export const FactIntWsResultClassification = Object.freeze({
  TLS_ERROR: 'TLS_ERROR', SOAP_PROTOCOL_ERROR: 'SOAP_PROTOCOL_ERROR', AUTH_ERROR: 'AUTH_ERROR',
  AUTHORIZATION_ERROR: 'AUTHORIZATION_ERROR', BUSINESS_ERROR: 'BUSINESS_ERROR',
  PARSING_ERROR: 'PARSING_ERROR', NTP_TIME_UNAVAILABLE: 'NTP_TIME_UNAVAILABLE',
  UNKNOWN_RESPONSE: 'UNKNOWN_RESPONSE', SUCCESS_EMPTY_RESULT: 'SUCCESS_EMPTY_RESULT',
  SUCCESS_NON_EMPTY_RESULT: 'SUCCESS_NON_EMPTY_RESULT',
});

export function classifyFactIntWsParsedResult(parsed) {
  if (parsed.fault) {
    const fault = `${parsed.fault.code ?? ''} ${parsed.fault.reason ?? ''}`;
    if (/auth|credential|password|username|utilizador/i.test(fault)) return FactIntWsResultClassification.AUTH_ERROR;
    if (/authoriz|permiss|forbidden|acesso/i.test(fault)) return FactIntWsResultClassification.AUTHORIZATION_ERROR;
    return FactIntWsResultClassification.SOAP_PROTOCOL_ERROR;
  }
  if (!parsed.result) return FactIntWsResultClassification.UNKNOWN_RESPONSE;
  return parsed.invoices?.length ? FactIntWsResultClassification.SUCCESS_NON_EMPTY_RESULT
    : FactIntWsResultClassification.SUCCESS_EMPTY_RESULT;
}

export class FactIntWsClient {
  constructor({ transport, endpoint = FACTINTWS_ENDPOINT_8443 }) {
    if (typeof transport !== 'function') throw new TypeError('FactIntWsClient requires a transport function');
    this.transport = transport; this.endpoint = endpoint;
  }
  async execute({ operation, username, credentials, input }) {
    const contract = factIntWsHttpContract(operation, this.endpoint);
    const xml = buildFactIntWsEnvelope({ username, credentials, operation, input });
    const response = await this.transport({ contract, xml });
    const parsed = parseFactIntWsResponse(response.body, operation);
    return Object.freeze({ ...response, parsed, classification: classifyFactIntWsParsedResult(parsed) });
  }
}

export class FactIntWsRepository {
  constructor(client) { if (!(client instanceof FactIntWsClient)) throw new TypeError('FactIntWsRepository requires FactIntWsClient'); this.client = client; }
  async pendingInvoices(context) {
    const result = await this.client.execute({ ...context, operation: FactIntWsOperation.PENDING });
    return Object.freeze({ ...result, domainInvoices: Object.freeze((result.parsed.invoices ?? []).map((invoice) => toAtInvoiceDomain(invoice))) });
  }
  async invoicesBySector(context) {
    const result = await this.client.execute({ ...context, operation: FactIntWsOperation.BY_SECTOR });
    return Object.freeze({ ...result, domainInvoices: Object.freeze((result.parsed.invoices ?? []).map((invoice) => toAtInvoiceDomain(invoice, { sectorLabel: context.sectorLabel ?? null }))) });
  }
  async initialScreen(context) { return this.client.execute({ ...context, operation: FactIntWsOperation.ECRAINICIAL }); }
}
