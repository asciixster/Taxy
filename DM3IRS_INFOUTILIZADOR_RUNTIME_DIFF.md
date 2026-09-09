# DM3IRS `infoUtilizador` runtime diff

Scope: offline comparison only. The comparison uses the already-retained, sanitized metadata for the corrected one-shot request and the official APK call path. No live request was executed.

## Outcome

At the reconstructed HTTP/SOAP contract level, the corrected Taxy request matches the official request. The expected caller identity differs: Taxy used its own legitimate mTLS identity, not the official app identity. That is an authorization context difference, not a missing SOAP field or header.

The runtime `130` is not evidence of a missing session or a random request mismatch. The official code maps it exactly to an invalid IRS delivery/exercise period. Why the server rejected the `2025` context remains unresolved, because `2025` is also the value bundled by the analysed official APK. The strongest inference is that the service considered that delivery campaign unavailable at probe time, rather than that the request contained a mistyped year.

## Field and header comparison

| Property | Official app | Corrected Taxy request | Classification |
|---|---|---|---|
| endpoint | production `/ws/dm3irsMobileService/` on port 411 | exact same endpoint | EXACT_MATCH |
| SOAP version | SOAP 1.1 | SOAP 1.1 | EXACT_MATCH |
| `Content-Type` | `text/xml` | `text/xml` | EXACT_MATCH |
| `SOAPAction` | `tns:infoUtilizadorAutenticadoMobileRequest` | exact same value | EXACT_MATCH |
| body root/namespace | confirmed mobile operation and namespace | exact same root/namespace | EXACT_MATCH |
| child order | `ano-fiscal`, then `nif` | same | EXACT_MATCH |
| `ano-fiscal` | `exerciseYearForRequests`, bundled as `2025` | `2025` | EXACT_MATCH |
| body `nif` | base taxpayer NIF | base NIF derived from legitimate login identity | EXACT_MATCH |
| WS-Security username | full login identity, including subuser suffix when present | same semantics | EXACT_MATCH |
| WS-Security algorithm/shape | version 2, encrypted password/digest/nonce, UTC `Created` | same reconstructed semantics | EXACT_MATCH |
| nonce, digest, ciphertext, `Created` | fresh for every request | fresh for the request | EXPECTED_DYNAMIC_DIFFERENCE |
| cookies | no propagation found | none | EXACT_MATCH |
| bearer/session token | no path found | none | EXACT_MATCH |
| app/package/version/device/channel fields | none serialized | none | EXACT_MATCH |
| TLS client identity | bundled official-app client identity | legitimate Taxy identity | DIFFERENT_BY_DESIGN |

Differing request fields/headers: **0**. The mTLS certificate identity is separately tracked and was accepted by TLS; its product entitlement is not inferred from that fact.

## Official call sequence before `infoUtilizador`

1. Load environment and cryptographic configuration locally.
2. Store/select taxpayer credentials locally and build per-request WS-Security.
3. Resolve `exerciseYearForRequests` locally.
4. Call `checkEntregaDeclMobileRequest` with base NIF and exercise year.
5. If no delivered declaration is found, call `infoUtilizadorAutenticadoMobileRequest`.

There is one preceding SOAP operation in this branch. It is a mandatory control-flow check in the official app, but static tracing found no cookie, token, session identifier, or other state produced by it and consumed by `infoUtilizador`. It is therefore **not evidence of a server-session bootstrap**.

## Session/context matrix

| State | Official path | Corrected Taxy request | Assessment |
|---|---|---|---|
| mTLS client identity | present | legitimate Taxy identity present and TLS-authorized | caller differs by design |
| WS-Security identity | present per request | present | CONFIRMED semantic match |
| base NIF | present in body | present | EXACT_MATCH |
| exercise year | present in body | present as `2025` | EXACT_MATCH |
| prior delivery check | executed in app branch | not executed immediately before this probe | local sequence difference; no session dependency found |
| cookie | not found | absent | NOT_REQUIRED by observed path |
| bearer/token | not found | absent | NOT_REQUIRED by observed path |
| session ID | not found | absent | NOT_REQUIRED by observed path |
| application metadata | no serialized fields | absent | no field-level difference |

## Year semantics

`ano-fiscal` is the selected IRS exercise/declaration year, not the device's current calendar year. `AppDataService.exerciseYearForRequests` prefers the environment's `exerciseYearRequests` and falls back to `config/app.json`'s `exerciseYear`. The analysed production and quality environment files and `config/app.json` all specify `2025`.

The login flow itself converts this value to a string and passes it both to `checkEntrega` and `infoUtilizador`. A missing local year raises `BadIrsYearException` before any request. A server response with status `130` or `131` raises the same exception class after parsing.

## NIF semantics

- Request body: base nine-digit taxpayer NIF.
- WS-Security username: the full login identity, with subuser suffix when applicable.
- No separate selected-taxpayer field is serialized.
- No static evidence associates NIF mismatch with status `130`; the explicit code mapping associates `130` with the IRS year/period.

## Authentication layers

| Layer | Status | Evidence |
|---|---|---|
| TLS client identity | CONFIRMED | Taxy identity completed TLS 1.3 and the server returned HTTP 200 |
| SOAP authentication | CONFIRMED | valid non-Fault operation response reached the shared business-status parser |
| user authentication | LIKELY | response is a year-class business error, not a credentials/security status; no payload was returned |
| session authentication | NOT_REQUIRED | no session token/cookie dependency found in static call graph |
| application authorization | UNKNOWN | no application fields exist; contractual/certificate entitlement remains unproven |
| operation authorization | LIKELY | exact response root was recognized and no missing-permission status was returned, but functional success was not obtained |

## Hypothesis ranking

| Hypothesis | Evidence for | Evidence against | Confidence |
|---|---|---|---|
| H5/H6: delivery campaign/year context unavailable | exact `BadIrsYearErrorEffect` mapping and “Período de entrega ... não é válido” UI message | APK itself configures `2025`, so the numeric value is not an obvious client mismatch | HIGH for error class; MEDIUM/HIGH for unavailable-period cause |
| H1: missing bootstrap/session | official flow calls `checkEntrega` first | no state from that response is propagated; no cookies/tokens/session IDs found | LOW |
| H2: user-auth context missing | no payload populated | WS-Security was present and response code is not mapped to auth/security | LOW |
| H3: application entitlement | Taxy certificate differs from official caller context | TLS accepted it; code `130` maps to year, not permission | LOW/MEDIUM as product gate, LOW as direct cause of 130 |
| H4: operation entitlement | operation-specific authorization is not contractually confirmed | exact response root and year-specific status, not codes 53/54 | LOW |
| H7: NIF/login mismatch | body and header use different representations by design | Taxy followed the same base/full identity split; 130 maps to year | VERY_LOW |
| H8: other | server-side campaign policy may not be represented in the APK | no deterministic static evidence | UNKNOWN |

## Probe decision

No further live probe is justified. Varying year, NIF, headers, operation, or certificate would be experimentation rather than a deterministic correction supported by the official code. The next evidence should come from the AT: accepted DM3IRS exercise/campaign year for this service and the precise contract for status codes 130/131.
