# DM3IRS runtime capability matrix

One explicitly authorized, read-only, single-shot probe was executed on 2026-09-08. It used the legitimate Taxy client identity against the exact production endpoint and stopped immediately after the first positive signal. No retry, fallback, second operation or write was attempted.

| Operation | Read-only | Schema confidence | Taxy auth | Runtime | Static fields/groups | Taxy value | Stability | Production recommendation |
|---|---:|---|---|---|---|---|---|---|
| obterCatalogos | YES | EXACT/HIGH | RUNTIME_CONFIRMED | HTTP 200; SOAP response; status `0`; no SOAP Fault | 1 requested catalog group observed; item count not retained | catalog reconciliation | OFFICIAL_APP_PRIVATE | technically available; product use still requires terms/entitlement review |
| infoUtilizador | YES | EXACT/HIGH | UNKNOWN | NO_LIVE_PROBE | 24 payload fields across nested models | profile prefill | OFFICIAL_APP_PRIVATE | entitlement plus legal/product review |
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
- live eligible: 1 (single-shot authorization probe consumed)
- live requests: 1
- runtime read capabilities confirmed: 1
- technically available but product-review-required: 1
- write requests: 0

## Key distinction

The runtime probe proves that the Taxy mTLS identity reached the service and that `obterCatalogosMobileRequest` was recognized and accepted with business status `0`. It does not prove that other operations are authorized, that the interface is contractually offered to third parties, or that product use is permitted. Those remain separate gates.
