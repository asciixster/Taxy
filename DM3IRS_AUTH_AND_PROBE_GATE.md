# DM3IRS auth comparison and probe gate

Detailed authentication analysis is in `DM3IRS_AUTH_ANALYSIS.md`.

| Operation | Read-only | Schema exact/high | Deterministic | No side effect | Legitimate Taxy auth known | Eligible |
|---|---:|---:|---:|---:|---:|---:|
| obterCatalogos | YES | YES | YES | YES | YES (runtime) | CONSUMED: one successful production probe; do not repeat automatically |
| infoUtilizador | YES | YES | YES | YES | NO | NO |
| infoAgregado | YES | YES | YES | YES | NO | NO |
| checkEntrega | YES | YES | YES | YES | NO | NO |
| obterReceipt | YES | YES | YES | YES | NO | NO |
| obterDeclaracao | YES | YES | YES | YES | NO | NO |
| submeterDeclaracao | WRITE | YES | YES | NO | NOT_APPLICABLE | NEVER |

The shared AT public request-encryption key does not prove client entitlement. The official app's bundled private identity was neither accessed nor used. Since the Taxy identity is only runtime-proven for FactIntWS, a DM3IRS request would be an authorization experiment rather than a properly gated read.

Result after the explicitly authorized 2026-09-08 probe: live requests 1; write requests 0. The production service accepted the Taxy mTLS identity and recognized `obterCatalogosMobileRequest` with HTTP 200, a valid SOAP response and status `0`. Other operations remain untested and product use still requires explicit AT terms/entitlement review.
