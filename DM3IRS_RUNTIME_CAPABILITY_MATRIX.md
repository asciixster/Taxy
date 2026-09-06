# DM3IRS runtime capability matrix

No operation was invoked. “Blocked” below means the safety gate prevented a request; it is not an upstream rejection.

| Operation | Read-only | Schema confidence | Auth result | Runtime result | Fields present | Taxy value | Stability | Production recommendation |
|---|---|---|---|---|---|---|---|---|
| obterCatalogos | candidate | root only | NOT_TESTED / entitlement unknown | NO_LIVE_PROBE | n/a | activity/income catalog reconciliation | OFFICIAL_APP_PRIVATE | acquire contract and review entitlement |
| infoUtilizador | candidate | root only | NOT_TESTED / entitlement unknown | NO_LIVE_PROBE | n/a | profile prefill | OFFICIAL_APP_PRIVATE | acquire contract and review entitlement |
| infoAgregado | candidate | root only | NOT_TESTED / entitlement unknown | NO_LIVE_PROBE | n/a | family prefill | OFFICIAL_APP_PRIVATE | acquire contract and review entitlement |
| checkEntrega | side effect unproven | root only | NOT_TESTED / entitlement unknown | NO_LIVE_PROBE | n/a | delivery monitoring | OFFICIAL_APP_PRIVATE | do not call until semantics proven |
| obterReceipt | candidate | root only | NOT_TESTED / entitlement unknown | NO_LIVE_PROBE | n/a | proof availability | OFFICIAL_APP_PRIVATE | acquire contract; privacy review for binary data |
| obterDeclaracao | candidate | root only | NOT_TESTED / entitlement unknown | NO_LIVE_PROBE | n/a | highest: prefill/history/Category B validation | OFFICIAL_APP_PRIVATE | contract + entitlement + product/legal review |

## Status counters

- operations catalogued: 7
- operations fully reconstructed: 0
- read candidates: 6
- read-only confirmed: 0
- live eligible: 0
- business live requests: 0
- runtime read capabilities confirmed: 0
- runtime technically available but product-review-required: 0
- write requests: 0

## Potential outcomes (not current capabilities)

| Impact class | Conditional outcome |
|---|---|
| A — eliminates questions | user/household facts if exact fields and entitlement are proven |
| B — improves estimate | declaration inputs, withholding and contribution fields if returned with year semantics |
| C — validation/golden case | only official calculation outputs; public filing XSD inputs are not golden outputs |
| D — monitoring | delivery-state and receipt-availability transitions |
| E — low value | catalogs already available in stable public XSD/form sources unless mobile adds authoritative version metadata |
