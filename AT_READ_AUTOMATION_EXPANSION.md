# AT read automation expansion — runtime evidence

Date: 2026-09-20. All probes used the taxpayer's legitimate Portal credentials,
performed read-only navigation, persisted no response payload or PII, and made
zero AT write requests.

## Runtime-confirmed capabilities

| Capability | Official surface | Result | Product value |
|---|---|---|---|
| IRS structured prefill | `irs.portaldasfinancas.gov.pt/app/prePreencher` | 2025 and 2024 accepted; A/C annex data normalized; explicit confirmation required | VERY HIGH |
| IRS declaration history | `irs.portaldasfinancas.gov.pt/app/consulta` + `POST /app/consulta/pesquisa` | year selector exposes 2015–2025; records observed for 2021, 2022 and 2023 | HIGH |
| Integrated activity profile | `sitfiscal.portaldasfinancas.gov.pt/integrada/presentation` | table exposes Type, Code, Description and Start Date; CAE, CIRS, VAT periodicity/regime and IRS accounting regime labels present | VERY HIGH |
| Tax situation summary | `GET /geral/dividas`, `GET /geral/coimas` | JSON 200; counts available; no active items for the tested account | HIGH |
| Fiscal agenda | `GET /geral/dashboard/agendaFiscal` | JSON 200; empty for the tested account | HIGH |
| Portal notices/messages | `GET /geral/dashboard/avisos`, `/mensagens` | JSON 200; sanitized schemas confirmed | MEDIUM |
| Payments and payment plans | Portal payments and installment-plan read screens | parser/auth 200; empty for the tested account | HIGH |
| Withholding declarations | Portal delivered-withholdings list | year 2025 query 200; empty for the tested account | MEDIUM |
| IUC consultation | `sitfiscal.../iuc/consultarIUC/consultarIUC` | query 200; no vehicles for the tested account | MEDIUM |
| Issued green-receipt consultation | Portal search to the official receipt consultation | route/auth reached; zero records for the tested account | VERY HIGH for Category B |
| e-Fatura personal deductions | `json/obterDocumentosIRSAdquirente.action` | 2026: 400 rows, six mapped sectors, exact provisional benefit available | VERY HIGH |

The tested 2026 e-Fatura sectors were `C01`, `C03`, `C05`, `C06`, `C09` and
`C99`. Amounts were intentionally not recorded in this evidence document.

## Important boundaries

- The current IRS campaign only offers structured prefill for 2025 and 2024.
  Older years are available through declaration history, not through the same
  prefill contract.
- `POST /app/consulta/pesquisa` is an authenticated official Portal JSON flow,
  but it is not a published third-party API. Treat it as `PORTAL_WEB_FRAGILE`.
- e-Fatura invoice-list endpoint `obterDocumentosAdquirente.action` can return
  HTTP 429 independently of the personal-deductions endpoint. The product must
  preserve partial availability and never show zero for unavailable invoice
  counters.
- Inventory consultation did not pass the e-Fatura session-transfer gate in
  this run. It remains unconfirmed and is not a release capability.
- The attempt to reopen a 2023 declaration detail was not deterministic in a
  later session. Historical listing is confirmed; detail extraction remains
  beta/internal until stabilized.

## Product sequence

1. Ship e-Fatura partial overview: official benefit and sector totals remain
   usable while the individual invoice list is rate limited.
2. Add reviewed activity-profile import: CAE/CIRS, start date, VAT context and
   simplified/organized regime as confirmation candidates.
3. Add IRS history timeline for 2015–2025 using metadata only; retrieve a
   declaration document only on explicit user action.
4. Add monitoring from fiscal agenda, debts/coimas and payment-plan summaries.
5. Add issued-receipt totals only after the consultation route is validated on
   an account with records and exact field ownership.

No capability above may silently overwrite current-year `TaxFact` values.

## Normalized Taxy API status

The backend now exposes three one-shot, no-store, read-only routes. Credentials
are forwarded only to the isolated worker and are not returned to the client.

| Taxy endpoint | Runtime result | Normalized output |
|---|---|---|
| `POST /v1/at/profile` | HTTP 200 | four activity rows observed: CAE primary, CIRS secondary and two CAE secondary rows; code/description present; confirmation required |
| `POST /v1/at/fiscal-overview` | HTTP 200 | debt/fine counts and debt total availability; no active items on the tested account |
| `POST /v1/at/irs/history` | HTTP 502 in the first public smoke | Portal year control was not deterministically available in that session; endpoint remains beta and is not wired into the app |

The e-Fatura session endpoint was also revalidated after the partial-availability
fix: HTTP 201, six sectors and official provisional benefit available; logout
HTTP 200. Invoice-level access can still be rate limited independently.

Backend commits: `faac32c` (e-Fatura partial availability) and `c38d7b6`
(normalized AT read endpoints). AT writes remained zero.
