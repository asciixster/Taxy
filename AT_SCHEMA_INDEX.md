# Índice WSDL/XSD e contratos

Foram localizados **10 artefactos/famílias WSDL/XSD relevantes**; sete WSDL foram enumerados diretamente nesta investigação. O download de documentação não é um business probe.

| Contrato | Namespace/operations | Request/response | SOAPAction/paginação/faults | Estado |
|---|---|---|---|---|
| `fatshareInvoices.wsdl` | `http://factemi.at.min_financas.pt/fatshareInvoices`; `Invoices` | `InvoicesRequest` → `InvoicesResponse` | SOAP 1.1; request escolhe emitente ou adquirente, datas e paginação; códigos `EstadoOperacao`/`Desc` | SCHEMA_CONFIRMED |
| `Fatcorews.wsdl` | `http://factemi.at.min_financas.pt/documents` | registo/alteração/eliminação e responses | SOAPAction vazio no contrato histórico | SCHEMA_CONFIRMED, WRITE |
| `Comunicacao_Series.wsdl` | `http://at.gov.pt/`; `registarSerie`, `finalizarSerie`, `consultarSeries`, `anularSerie` | tipos embedded | endereço embebido não é deployment público fiável | SCHEMA_CONFIRMED |
| `arrendamento6.wsdl` | `https://servicos.portaldasfinancas.gov.pt/arrendamento/definitions` | `registarDadosContrato`, `obterRecibo`, `emitirRecibo` | endpoint `/sicau/ws/arrendamento/` | SCHEMA_CONFIRMED; `obterRecibo` UNKNOWN side effect |
| `documentosTransporte.wsdl` | contrato transporte | `envioDocumentoTransporte` | SOAP | SCHEMA_CONFIRMED, WRITE |
| `wsSubmeterDeclaracaoIES.WSDL` | serviço IES | `submeterDeclaracao`, `validarDeclaracao` | SOAP | SCHEMA_CONFIRMED, WRITE/MIXED |
| `wsSubmeterDeclaracaoIRC.wsdl` | serviço IRC | `submeterDeclaracao`, `validarDeclaracao` | SOAP | SCHEMA_CONFIRMED, WRITE/MIXED |
| `DeclaracaoPeriodicaIVAWebService.wsdl` | IVA | submissão periódica | SOAP | LOCATED, WRITE |
| `oaatws.zip` | obrigações acessórias | comunicação de modelos declarativos | WSDL empacotado | LOCATED, WRITE |
| VIES `checkVatService.wsdl` | UE VIES | `checkVat` e variantes publicadas | faults de indisponibilidade nacional/global, input inválido e throttling | LOCATED, READ_ONLY |

## Fatshare: elementos úteis

- Request: exatamente um de `TaxRegistrationNumber` (emitente) ou `CustomerTaxID` (adquirente), `StartDate`, `EndDate`, `Pagination/nPage/nDocsPage`.
- Paginação: implementação/referência existente limita `nDocsPage` a 1..5000.
- Response observada/modelada: `EstadoOperacao`, `Desc`, `InvoiceNo`, `InvoiceDate`, `InvoiceType`, `TaxRegistrationNumber`, `CustomerTaxID`, `ATCUD`, `TaxPayable`, `NetTotal`, `GrossTotal`, e totais de paginação.
- Privacy: NIFs e identificadores documentais não pertencem ao modelo móvel normalizado.

## FactIntWS: contrato não público

Namespace `http://factemi.at.min_financas.pt/factintws`; SOAPAction `namespace/Operation`. Reads: `EcraInicial`, `DadosContribuinte`, `FaturasPorClassificar`, `FaturasPorSetor`. O contrato provém de evidência de app oficial e runtime controlado, não de WSDL público; estabilidade `MOBILE_PRIVATE_CONTEXT`.
