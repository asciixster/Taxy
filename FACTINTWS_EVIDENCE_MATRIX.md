# FactIntWS evidence matrix

FactIntWS transport and the three read-only operations listed below are
runtime-confirmed on endpoint 8443. No non-empty invoice item has yet been
observed, so invoice field contracts remain official-app/offline evidence only.

| Element | Evidence | Confidence | Implementation status | Live-ready |
|---|---|---|---|---|
| Primary endpoint 443 | APK resources + communication setup | `CONFIRMED_FROM_OFFICIAL_APP`; failed runtime attempts | transport failure before HTTP | no |
| Alternate endpoint 8443 | official-app resource + controlled request | `RUNTIME_CONFIRMED` | mTLS authorized; TLS 1.3; HTTP 200; functional SOAP response | yes |
| SOAP 1.1 envelope/namespaces/order | envelope constant | `CONFIRMED_FROM_OFFICIAL_APP` | serializer + snapshots | yes |
| Security actor/version | envelope constant | `CONFIRMED_FROM_OFFICIAL_APP` | implemented | yes |
| Password/Digest crypto | security manager + crypto helper | `CONFIRMED_FROM_OFFICIAL_APP` | implemented + vector | yes |
| Nonce | AES generator + RSA call | `CONFIRMED_FROM_OFFICIAL_APP` | implemented | yes |
| Created format/source | NTP client + Joda UTC output | `CONFIRMED_FROM_OFFICIAL_APP`; provider behavior locally verified | exact format; one-exchange provider implemented; system fallback disabled | yes |
| SOAPAction/HTTP headers | SOAP caller + transport | `CONFIRMED_FROM_OFFICIAL_APP` | contract implemented | yes |
| `CanalOrigem` structure | request builders | `CONFIRMED_FROM_OFFICIAL_APP` | exact child order implemented | yes |
| Channel semantics/system/formula | Android `ChanelType` constructor and call sites | `CONFIRMED_FROM_OFFICIAL_APP` | `RUNTIME_DEVICE_METADATA`; `Sistema=A`; dynamic Android version | yes |
| First tooling channel values | coherent Android platform pair | `EXPLICIT_RUNTIME_METADATA` | API 35 / Android 15; not server-confirmed | yes for request construction |
| Certificate pinning | APK network-security config | `CONFIRMED_FROM_OFFICIAL_APP` | documented; app pin values not imported | not required for offline gate |
| Taxy certificate pinning | Taxy harness | `UNKNOWN` | `NOT_IMPLEMENTED`; native CA validation remains enabled | not a SOAP blocker |
| `EcraInicial` | builder + response DTO | `CONFIRMED_FROM_OFFICIAL_APP` | serializer/parser | yes |
| `DadosContribuinte` | builder + response DTO | `CONFIRMED_FROM_OFFICIAL_APP` | serializer/parser | yes, but sensitive |
| `FaturasPorClassificar` | builder/UI flow + HTTP 200/EstadoOperacao 204 on endpoint 8443 | `RUNTIME_CONFIRMED` dispatch/empty contract; `CONFIRMED_FROM_OFFICIAL_APP` pending-only population | serializer, typed parser, client/repository | yes |
| `FaturasPorSetor` | builder/UI flow + HTTP 200/EstadoOperacao 204 for `C05`, offset 0, endpoint 8443 | `RUNTIME_CONFIRMED` concrete-sector dispatch/empty contract; official empty-sector aggregate remains offline evidence | serializer, typed parser, client/repository; empty `CodSetor` currently rejected | partial for population discovery |
| Four mutating operations | builders + response DTOs | `CONFIRMED_FROM_OFFICIAL_APP` | documented, blocked | no |
| Taxy PFX local readiness | local PKCS#12/X.509 preflight | `OFFLINE_VERIFIED` | opens; key present; 3 certs; chain valid; clientAuth EKU valid | yes locally |
| Taxy client identity acceptance | controlled calls on endpoint 8443 | `RUNTIME_CONFIRMED` | authorized mTLS, TLS 1.3, HTTP 200 | yes |
| Business code 204 | official-app constant `CODIGO_ESTADO_SUCESSO_VAZIO` | `CONFIRMED_FROM_OFFICIAL_APP` | accepted as successful empty operation result | yes |
| Business code 419 | runtime observation only; no APK mapping found | `UNKNOWN` | preserved as opaque non-success value | not blocking transport test |
| Controlled FactIntWS attempt | `secureConnect`, then OpenSSL `bad record mac` before HTTP | `RUNTIME_CONFIRMED` (transport failure only) | classified `TLS_ERROR`; no SOAP/channel promotion | blocked at transport |
| TLS 1.2-only experiment | TLS alert 40 before `secureConnect` | `RUNTIME_CONFIRMED` (failure only) | TLS 1.2 did not resolve transport; no protocol promotion | no |
| 8443 endpoint experiment | authorized TLS 1.3, HTTP 200, successful `EcraInicialResponse` | `RUNTIME_CONFIRMED` | endpoint, mTLS profile and operation accepted | yes |

## Readiness

| Operation | AUTH | SOAP | REQUEST_SCHEMA | RESPONSE_SCHEMA | SAFETY | Overall |
|---|---|---|---|---|---|---|
| `EcraInicial` | READY and authenticated on 8443 | READY | READY | READY | READY | READY |
| `DadosContribuinte` | READY offline; TLS runtime blocked | READY | READY | READY | PARTIAL (PII response) | NOT_READY |
| `FaturasPorClassificar` | READY and runtime accepted | READY | READY | READY; real item shape not yet observed | READY | READY |
| `FaturasPorSetor` | READY and runtime accepted for `C05`/index 0 | READY | READY | READY; real item shape not yet observed | READY | READY |

The 0.7.6 controlled discovery called `EcraInicial` for 2026 and 2025. The
2026 response exposed sectors `C01`–`C15` and `C99`, all with zero observed
aggregates; the 2025 response returned business status `419`. With no runtime
signal of invoice data, no random sector request was made. Real non-empty
invoice response and parsing remain `UNKNOWN`.
