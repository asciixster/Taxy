# DM3IRS runtime capability matrix

Two separately authorized, read-only, single-shot probes have been executed on 2026-09-08. Both used the legitimate Taxy client identity against the exact production endpoint. Each task stopped after its first request; there was no retry, fallback or write.

| Operation | Read-only | Schema confidence | Taxy auth | Runtime | Static fields/groups | Taxy value | Stability | Production recommendation |
|---|---:|---|---|---|---|---|---|---|
| obterCatalogos | YES | EXACT/HIGH | RUNTIME_CONFIRMED | HTTP 200; SOAP response; status `0`; no SOAP Fault | 1 requested catalog group observed; item count not retained | catalog reconciliation | OFFICIAL_APP_PRIVATE | technically available; product use still requires terms/entitlement review |
| infoUtilizador | YES | EXACT/HIGH | TLS CONFIRMED; SERVICE/OPERATION UNKNOWN | HTTP 500; SOAP Fault; sanitized `REQUEST_ERROR`; no functional payload | 24-field static baseline; 0 runtime fields observable because the request was rejected | profile prefill | OFFICIAL_APP_PRIVATE | correct the deterministic request contract offline before any separately authorized future probe |
| infoAgregado | YES | EXACT/HIGH | UNKNOWN | NO_LIVE_PROBE | 89 distinct payload fields; 8 functional groups | household, inputs and official server calculation | OFFICIAL_APP_PRIVATE | highest-value controlled read after entitlement |
| checkEntrega | YES | EXACT/HIGH | UNKNOWN | NO_LIVE_PROBE | status plus optional declaration reference | monitoring | OFFICIAL_APP_PRIVATE | safe only after entitlement |
| obterReceipt | YES | EXACT/HIGH | UNKNOWN | NO_LIVE_PROBE | 16 receipt payload fields | proof/status monitoring | OFFICIAL_APP_PRIVATE | avoid persisting identifiers |
| obterDeclaracao | YES | EXACT/HIGH | UNKNOWN | NO_LIVE_PROBE | PDF payload only | user-visible declaration copy | OFFICIAL_APP_PRIVATE | lower prefill value; privacy-heavy |
| submeterDeclaracao | NO (WRITE) | HIGH | NOT_APPLICABLE | PROHIBITED | submission graph | out of scope | OFFICIAL_APP_PRIVATE | never probe in discovery |

## Counters

- operations catalogued: 7
- operations fully reconstructed: 7 (six exact/high read contracts; write documented without execution)
- read-only confirmed: 6
- write confirmed: 1
- live eligible: 0 (both separately authorized single-shot probe budgets consumed)
- live requests: 2 total across the two tasks
- runtime read capabilities confirmed: 1
- technically available but product-review-required: 1
- write requests: 0

## Key distinction

The runtime probe proves that the Taxy mTLS identity reached the service and that `obterCatalogosMobileRequest` was recognized and accepted with business status `0`. It does not prove that other operations are authorized, that the interface is contractually offered to third parties, or that product use is permitted. Those remain separate gates.

The `infoUtilizadorAutenticadoMobileRequest` probe separately proves TLS acceptance of the same legitimate Taxy identity. Its HTTP 500 SOAP Fault was sanitized as `REQUEST_ERROR`; because no operation response root or business status was returned, service- and operation-level authorization remain `UNKNOWN`. No retry is permitted under this task's budget.
