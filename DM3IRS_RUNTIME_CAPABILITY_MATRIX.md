# DM3IRS runtime capability matrix

No operation was invoked. `NO_LIVE_PROBE` means the authorization gate prevented a request; it is not an upstream rejection.

| Operation | Read-only | Schema confidence | Taxy auth | Runtime | Static fields/groups | Taxy value | Stability | Production recommendation |
|---|---:|---|---|---|---|---|---|---|
| obterCatalogos | YES | EXACT/HIGH | UNKNOWN | NO_LIVE_PROBE | 4 catalog types | catalog reconciliation | OFFICIAL_APP_PRIVATE | obtain explicit entitlement/contract first |
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
- live eligible: 0
- live requests: 0
- runtime read capabilities confirmed: 0
- technically available but product-review-required: 0 (no runtime proof)
- write requests: 0

## Key distinction

The APK proves what the official client can request and consume. It does not prove that the Taxy identity is authorized, that the interface is offered to third parties, or that product use is permitted. Those remain separate gates.
