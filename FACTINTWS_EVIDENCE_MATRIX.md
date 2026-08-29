# FactIntWS evidence matrix

No successful FactIntWS protocol element is runtime-confirmed. The sole runtime
row records only a transport failure and does not promote the submitted protocol.

| Element | Evidence | Confidence | Implementation status | Live-ready |
|---|---|---|---|---|
| Primary/alternate endpoint | APK resources + communication setup | `CONFIRMED_FROM_OFFICIAL_APP` | primary selected, no fallback | yes |
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
| `FaturasPorClassificar` | builder + response DTO | `CONFIRMED_FROM_OFFICIAL_APP` | serializer/parser | yes |
| `FaturasPorSetor` | builder + response DTO | `CONFIRMED_FROM_OFFICIAL_APP` | serializer/parser | yes |
| Four mutating operations | builders + response DTOs | `CONFIRMED_FROM_OFFICIAL_APP` | documented, blocked | no |
| Taxy PFX local readiness | local PKCS#12/X.509 preflight | `OFFLINE_VERIFIED` | opens; key present; 3 certs; chain valid; clientAuth EKU valid | yes locally |
| Taxy client identity acceptance | none | `UNKNOWN` | not tested against FactIntWS | unknown |
| Business-code semantics | names only | `UNKNOWN` | preserved as opaque values | not blocking transport test |
| Controlled FactIntWS attempt | `secureConnect`, then OpenSSL `bad record mac` before HTTP | `RUNTIME_CONFIRMED` (transport failure only) | classified `TLS_ERROR`; no SOAP/channel promotion | blocked at transport |
| TLS 1.2-only experiment | TLS alert 40 before `secureConnect` | `RUNTIME_CONFIRMED` (failure only) | TLS 1.2 did not resolve transport; no protocol promotion | no |

## Readiness

| Operation | AUTH | SOAP | REQUEST_SCHEMA | RESPONSE_SCHEMA | SAFETY | Overall |
|---|---|---|---|---|---|---|
| `EcraInicial` | READY offline; TLS runtime blocked | READY | READY | READY | READY | NOT_READY |
| `DadosContribuinte` | READY offline; TLS runtime blocked | READY | READY | READY | PARTIAL (PII response) | NOT_READY |
| `FaturasPorClassificar` | READY offline; TLS runtime blocked | READY | READY | READY | READY | NOT_READY |
| `FaturasPorSetor` | READY offline; TLS runtime blocked | READY | READY | READY | READY | NOT_READY |

Best first candidate remains `EcraInicial`, because it is read-only, requires no
paging/sector choice, and returns aggregates rather than an invoice list or
taxpayer name. All offline gates pass. The TLS 1.2-only single-variable experiment
failed with TLS alert 40 before `secureConnect`; TLS 1.2 is not runtime-confirmed.
No retry, fallback, cipher variation or second request was made.
