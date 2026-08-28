export const AtEnvironment = Object.freeze({ TEST: 'test', PRODUCTION: 'production' });

const ENDPOINTS = Object.freeze({
  test: Object.freeze({
    invoiceSubmission: 'https://servicos.portaldasfinancas.gov.pt:723/fatcorews/ws',
    invoiceConsultation: 'https://servicos.portaldasfinancas.gov.pt:725/fatshare/ws/fatshareFaturas',
  }),
  production: Object.freeze({
    invoiceSubmission: 'https://servicos.portaldasfinancas.gov.pt:423/fatcorews/ws',
    invoiceConsultation: 'https://servicos.portaldasfinancas.gov.pt:425/fatshare/ws/fatshareFaturas',
  }),
});

export function endpointFor(environment, service = 'invoiceConsultation') {
  const group = ENDPOINTS[environment];
  if (!group) throw new Error(`Unsupported AT environment: ${environment}`);
  if (!group[service]) throw new Error(`Unsupported AT service: ${service}`);
  return new URL(group[service]);
}

export const AtEndpointMetadata = Object.freeze({
  invoiceSubmission: Object.freeze({
    namespace: 'http://factemi.at.min_financas.pt/documents',
    soapAction: '',
    wsdl: 'https://info.portaldasfinancas.gov.pt/pt/apoio_ao_contribuinte/Outras_entidades/Suporte_tecnologico/Webservice/e_Fatura/Documents/Fatcorews.wsdl',
  }),
  invoiceConsultation: Object.freeze({
    namespace: null,
    soapAction: null,
    wsdl: null,
    status: 'NEEDS_VERIFICATION',
    reason: 'The official October 2025 manual documents InvoicesRequest but states that the consultation WSDL will be published later.',
  }),
});
