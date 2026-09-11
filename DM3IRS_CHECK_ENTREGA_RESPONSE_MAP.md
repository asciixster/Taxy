# DM3IRS `checkEntrega` response map

Date: 2026-09-09

Operation: `checkEntregaDeclMobileRequest`

Endpoint: `https://servicos.portaldasfinancas.gov.pt:411/ws/dm3irsMobileService/`

## Static contract

| Property | Confirmed value | Evidence |
|---|---|---|
| SOAP version | 1.1 | APK request builder/common transport |
| SOAPAction | `tns:checkEntregaDeclMobileRequest` | APK request builder |
| request root | `checkEntregaDeclMobileRequest` | APK call-site |
| request namespace | `https://servicos.portaldasfinancas.gov.pt/dm3irsmobile/schemas` | APK common envelope/builder |
| ordered request fields | `ano-fiscal`, `nif` | `DeclarationService.fetchDeliveredIRSDeclaration` and `DeclarationRequestBuilder.addBody` |
| year semantics | selected IRS exercise/declaration year | `AppDataService.exerciseYearForRequests`; APK production value `2025` |
| NIF semantics | base taxpayer NIF | login call-site; full login/subuser identity remains in WS-Security |
| response root | `checkEntregaDeclMobileResponse` | generated response path and runtime confirmation |
| shared response status | `statusType/codigo`, optional server message | common `ApiService` parser |
| operation payload | optional integer `declaracao` | `DeliveredDeclaration.fromResponse` |

`REQUEST_SCHEMA_EXACT = YES`, `RESPONSE_SCHEMA_EXACT = YES`, and `SOAP_ACTION_EXACT = YES`.

## Side-effect audit

The call-site builds a two-field query, performs the common SOAP request, parses an optional declaration identifier, and derives a local boolean from whether that identifier is nonzero. It does not invoke submission, create a Modelo 3 graph, create a draft, reserve an identifier, or persist a server mutation. The consumer only chooses a local navigation branch: declaration found leads toward receipt/status retrieval; declaration absent leads toward `infoUtilizador`.

Result: `READ_ONLY = YES`. Normal upstream access logging is possible but is not a functional tax-state side effect.

## Complete response field map

| Field | Type | Required | Meaning | Runtime handling |
|---|---|---:|---|---|
| `statusType/codigo` | integer | shared required status | operation result code | retained only as sanitized code |
| `statusType/mensagem` | string | optional | server diagnostic | not persisted |
| `declaracao` | integer | optional | taxpayer-specific delivered declaration identifier | value not persisted; only presence/nonzero boolean observed |

No response parser/model fields exist for current year, available year, delivery-period start/end, campaign status, or an explicit allowed/disallowed flag.

## Status handling

| Code | Meaning | Source | Confidence |
|---:|---|---|---|
| 0 | success | common `ApiService` parser; runtime confirmed for this operation | EXACT |
| 130 | invalid IRS delivery/exercise period | `BadIrsYearErrorEffect` plus login message | EXACT global status class |
| 131 | invalid IRS delivery/exercise period class | `BadIrsYearErrorEffect` | EXACT global status class |
| 53/54 | missing permissions class | `MissingPermissionsErrorEffect` | EXACT global status class |

No check-specific status switch exists. The shared DM3IRS error chain handles nonzero codes.

## One-shot runtime result

| Item | Result |
|---|---|
| request count | 1 |
| retries/fallbacks | 0 / 0 |
| Taxy mTLS authorized | YES |
| TLS | TLS 1.3 / `TLS_AES_128_GCM_SHA256` |
| HTTP | 200 / `text/xml` |
| SOAP response / Fault | YES / NO |
| response root | `checkEntregaDeclMobileResponse` |
| operation recognized | YES |
| `EstadoOperacao` | `0` |
| request year | `2025` |
| declaration field | present and nonzero; identifier not retained |
| PII persisted | NO |
| writes | 0 |

## Interpretation

`CHECK_ENTREGA_2025_VALID`: the service accepted exercise year `2025` for this operation and returned successful delivered-declaration state. The response does not expose whether the filing campaign is currently open or closed and does not indicate another year.

This explains the previous `infoUtilizador` status `130` only **partially**. In the official app, a positive `checkEntrega` result routes to receipt/status handling and bypasses `infoUtilizador`; the earlier direct `infoUtilizador` call therefore occurred outside the official no-declaration branch. The evidence strongly suggests that `130` represents invalid delivery-flow eligibility for that state, not rejection of the numeric year `2025`. The server contract does not expose enough detail to call that causal link exact.

Stop rule observed: no second request or operation was executed.
