# Catálogo de endpoints e operações

A fonte estruturada é `at_read_discovery/catalog.json`: **16 endpoints/deployments**, **29 operações**, das quais 9 `READ_ONLY`, 17 `WRITE`, 2 `MIXED` e 1 `UNKNOWN`.

| Família | Endpoint/deployment | Ambiente | Protocolo/auth | Operações | Classificação/status |
|---|---|---|---|---|---|
| e-Fatura fatshare | portas `725` teste / `425` produção, `/fatshare/ws/fatshareFaturas` | test/prod | HTTPS SOAP 1.1, mTLS + WS-Security | `Invoices` | READ_ONLY; SCHEMA_CONFIRMED; auth de população prod UNKNOWN |
| e-Fatura fatcore | portas `723` teste / `423` produção, `/fatcorews/ws` | test/prod | HTTPS SOAP 1.1, mTLS + WS-Security | registar, alterar, eliminar | WRITE; não executar |
| FactIntWS | portas `443` e `8443`, `/mobile/a4/factintws/ws` | contexto mobile | HTTPS SOAP 1.1, app mTLS + WS-Security | 4 reads + 4 writes | mixed; `:8443` read dispatch runtime, população Taxy divergente |
| Séries/ATCUD | deployment não publicável pelo endereço embebido | documented | SOAP | registar, finalizar, consultar, anular | `consultarSeries` READ_ONLY/AUTH_UNKNOWN; restantes WRITE |
| Arrendamento | `/sicau/ws/arrendamento/` | prod | SOAP | registar dados, obter recibo, emitir recibo | WRITE/UNKNOWN; não probe |
| Transporte | `/sgdtws/documentosTransporte/` | prod | SOAP | envio | WRITE |
| IES | `/iesws/SubmeterDeclaracaoIESService/` | prod | SOAP | submeter, validar | WRITE/MIXED; não lê declaração vigente |
| IRC | `/dm22ircws/SubmeterDeclaracaoIRCService/` | prod | SOAP | submeter, validar | WRITE/MIXED; não lê liquidação |
| IVA periódica | deployment no WSDL, não promovido | documented | SOAP | submissão | WRITE |
| Obrigações acessórias | WSDL oficial em ZIP | documented | SOAP | comunicação | WRITE |
| VIES | Comissão Europeia `checkVatService` | prod | SOAP/REST público | validar VAT number | READ_ONLY; SCHEMA_CONFIRMED |
| Portal e-Fatura | `consultarDocumentosAdquirente.action` | prod | HTTPS HTML + sessão Portal | abrir consulta | READ_ONLY; RUNTIME_READ_CONFIRMED; fragile |
| Portal e-Fatura JSON | `json/obterDocumentosAdquirente.action` | prod | HTTPS JSON + sessão/contexto | obter documentos adquiridos | READ_ONLY; RUNTIME_READ_CONFIRMED; fragile |
| Portal e-Fatura deductions JSON | `json/obterDocumentosIRSAdquirente.action` | prod | HTTPS JSON + Portal session | personal deduction rows and sector benefit totals | READ_ONLY; RUNTIME_READ_CONFIRMED; fragile |
| IRS prefill | `irs.portaldasfinancas.gov.pt/app/prePreencher` | prod | HTTPS HTML/JSON + Portal session | structured declaration prefill for 2024–2025 | READ_ONLY; RUNTIME_READ_CONFIRMED; fragile |
| IRS history | `irs.portaldasfinancas.gov.pt/app/consulta`, `POST /app/consulta/pesquisa` | prod | HTTPS HTML/JSON + Portal session | list submitted declarations for 2015–2025 | READ_ONLY; RUNTIME_READ_CONFIRMED; fragile |
| Integrated tax profile | `sitfiscal.portaldasfinancas.gov.pt/integrada/presentation` | prod | HTTPS HTML + Portal session | activity codes/start date and tax regimes | READ_ONLY; RUNTIME_READ_CONFIRMED; fragile |
| Fiscal dashboard | `GET /geral/dashboard/agendaFiscal`, `/avisos`, `/mensagens`, `/servicosFrequentes`, `/geral/dividas`, `/geral/coimas` | prod | HTTPS JSON + Portal session | obligations, notices, debt/fine aggregates | READ_ONLY; RUNTIME_READ_CONFIRMED; fragile |

## Endpoints deliberately not inferred

No route is promoted solely because a feature exists in ATGo or another
official app. Liquidation details and an activity-profile JSON contract remain
unconfirmed. The runtime-confirmed Portal routes above are authenticated web
flows, not claimed as public or stable third-party APIs.
