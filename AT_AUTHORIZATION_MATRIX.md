# Matriz de autorização

Autorização nunca é transitiva entre endpoint, operação ou população.

| Endpoint/operação | Identidade | mTLS | WS-Security/sessão | Authorized | Evidência runtime |
|---|---|---:|---|---|---|
| FactIntWS `:8443` / `EcraInicial` | Taxy client identity | YES | YES | YES para dispatch; NO/UNKNOWN para população equivalente à app oficial | TLS 1.3, HTTP 200, SOAP, Estado 200 |
| FactIntWS / `FaturasPorClassificar` | Taxy client identity | YES | YES | YES para dispatch | HTTP 200, Estado 204 vazio |
| FactIntWS / `FaturasPorSetor(C05,0)` | Taxy client identity | YES | YES | YES para dispatch | HTTP 200, Estado 204 vazio |
| FactIntWS / `DadosContribuinte` | Taxy client identity | transport-ready | contract known | UNKNOWN (não houve live probe seguro nesta discovery) | offline/parser only per readiness matrix |
| fatshare test / `Invoices` | Taxy-controlled test path | YES | request accepted | PARTIAL: typed empty response, intended user population UNKNOWN | HTTP 200, Estado 486 vazio histórico |
| fatshare prod / `Invoices` | Taxy backend identity | UNKNOWN for this operation | schema known | UNKNOWN | none |
| Portal acquired-documents | user Portal credentials | n/a | Portal session | YES for authenticated user's received invoices | real pending count and normalized invoice list |
| `api.taxy.pt` mobile facade | opaque Taxy session | HTTPS | bearer | YES, user-bound | Android public-beta smoke |
| Series / `consultarSeries` | Taxy identities | unknown | contract known | UNKNOWN | none |
| VIES / `checkVat` | none/basic public | n/a | none | YES for supplied VAT-number validation | public contract; no probe needed |
| ATGo profile/analytics | official app context | app-owned | private context | NOT_AUTHORIZED for Taxy | capability public, API/auth not published |
| Personal IRS/assessment/payment pages | user Portal session | n/a | Portal session | UNKNOWN for automation | no controlled mapping/probe |

## Matrix completeness

Completa para todos os endpoints catalogados: **YES**. “UNKNOWN” é resultado, não lacuna omitida. Nenhum certificado oficial-app foi usado. Esta discovery executou 0 business probes porque as novas oportunidades não passaram simultaneamente schema + explicit read semantics + legitimate auth.
