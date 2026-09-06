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

## Endpoints deliberadamente não inferidos

Não foram inventadas rotas para atividade/CAE/CIRS, rendimentos comunicados, Modelo 3, liquidações, pagamentos, dívida ou obrigações. A existência dessas páginas no Portal/ATGo não revela uma API pública. O endereço interno/localhost de um WSDL também não é promovido a endpoint operacional.
