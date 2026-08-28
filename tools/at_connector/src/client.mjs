import { endpointFor } from './endpoints.mjs';
import { parseSoapResponse } from './parser.mjs';
import { safeLog } from './redaction.mjs';
import { connectivityProbeEnvelope } from './soap.mjs';
import { sendMtlsSoap } from './transport.mjs';

export class AtSoapClient {
  constructor(config, { logger = () => {} } = {}) {
    this.config = config;
    this.logger = logger;
  }

  async probeConsultation() {
    const endpoint = endpointFor(this.config.environment, 'invoiceConsultation');
    safeLog(this.logger, 'at.request.started', { endpoint: endpoint.toString(), operation: 'connectivity-probe' });
    const transport = await sendMtlsSoap({
      endpoint,
      pfxPath: this.config.pfxPath,
      pfxPassword: this.config.pfxPassword,
      xml: connectivityProbeEnvelope(),
      soapAction: '',
    });
    const response = parseSoapResponse(transport.body, transport.statusCode);
    safeLog(this.logger, 'at.request.completed', {
      endpoint: endpoint.toString(), httpStatus: transport.statusCode, tls: transport.tls,
      durationMs: transport.durationMs, fault: response.fault, requestId: response.requestId,
    });
    return Object.freeze({ endpoint: endpoint.toString(), transport, response });
  }
}
