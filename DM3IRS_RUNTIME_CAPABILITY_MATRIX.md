# DM3IRS runtime capability matrix

Four separately authorized, read-only, single-shot probes have been executed. All used the legitimate Taxy client identity against the exact production endpoint. Each task stopped after its first request; there was no retry, fallback or write.

| Operation | Read-only | Schema confidence | Taxy auth | Runtime | Static fields/groups | Taxy value | Stability | Production recommendation |
|---|---:|---|---|---|---|---|---|---|
| obterCatalogos | YES | EXACT/HIGH | RUNTIME_CONFIRMED | HTTP 200; SOAP response; status `0`; no SOAP Fault | 1 requested catalog group observed; item count not retained | catalog reconciliation | OFFICIAL_APP_PRIVATE | technically available; product use still requires terms/entitlement review |
| infoUtilizador | YES | EXACT/HIGH | TLS AND OPERATION FRAMING CONFIRMED; BUSINESS ACCEPTANCE NOT CONFIRMED | corrected request: HTTP 200; SOAP response root recognized; no SOAP Fault; business status `130` (`BadIrsYear` / invalid IRS delivery period); no functional payload | 24-field static baseline; 0 runtime fields present/populated | profile prefill | OFFICIAL_APP_PRIVATE | ask the AT which exercise/campaign year is accepted; do not vary fields experimentally |
| infoAgregado | YES | EXACT/HIGH | UNKNOWN | NO_LIVE_PROBE | 89 distinct payload fields; 8 functional groups | household, inputs and official server calculation | OFFICIAL_APP_PRIVATE | highest-value controlled read after entitlement |
| checkEntrega | YES | EXACT/HIGH | RUNTIME_CONFIRMED | HTTP 200; exact SOAP response; status `0`; delivered-declaration field present/nonzero, identifier not retained | status plus optional declaration reference | monitoring and delivery-flow routing | OFFICIAL_APP_PRIVATE | technically available; product use still requires terms/entitlement review |
| obterReceipt | YES | EXACT/HIGH | UNKNOWN | NO_LIVE_PROBE | 16 receipt payload fields | proof/status monitoring | OFFICIAL_APP_PRIVATE | avoid persisting identifiers |
| obterDeclaracao | YES | EXACT/HIGH | UNKNOWN | NO_LIVE_PROBE | PDF payload only | user-visible declaration copy | OFFICIAL_APP_PRIVATE | lower prefill value; privacy-heavy |
| submeterDeclaracao | NO (WRITE) | HIGH | NOT_APPLICABLE | PROHIBITED | submission graph | out of scope | OFFICIAL_APP_PRIVATE | never probe in discovery |

## Counters

- operations catalogued: 7
- operations fully reconstructed: 7 (six exact/high read contracts; write documented without execution)
- read-only confirmed: 6
- write confirmed: 1
- live eligible: 0 (all three separately authorized single-shot probe budgets consumed)
- live requests: 4 total across four tasks
- runtime read capabilities confirmed: 2
- technically available but product-review-required: 2
- write requests: 0

## Key distinction

The runtime probe proves that the Taxy mTLS identity reached the service and that `obterCatalogosMobileRequest` was recognized and accepted with business status `0`. It does not prove that other operations are authorized, that the interface is contractually offered to third parties, or that product use is permitted. Those remain separate gates.

The first `infoUtilizadorAutenticadoMobileRequest` probe separately proved TLS acceptance but used an incomplete operation body and returned an HTTP 500 SOAP Fault. A later, separately authorized corrected probe sent the official call-site context (`ano-fiscal`, then base `nif`) and received HTTP 200 with the exact operation response root, no SOAP Fault, and business status `130`. Subsequent offline AOT tracing established that codes `130` and `131` are handled by the shared `BadIrsYearErrorEffect`; the login flow presents “Período de entrega de IRS não é válido”. This confirms transport and operation framing, but not successful profile retrieval. The APK itself configures `2025`, the same year used in the request, so no deterministic replacement is supported and no further probe is recommended without AT clarification.

A later, separately authorized `checkEntregaDeclMobileRequest` used the same official year `2025` and returned status `0` with a delivered declaration present. This proves that `2025` is accepted by the delivery-check operation. The official app routes that positive state to receipt handling and does not call `infoUtilizador`; this partially explains the earlier `130` as a delivery-flow/state restriction rather than a bad numeric year. Campaign open/closed remains unknown because the response has no period or campaign fields.
