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
| Created | NTP client + Joda UTC output | `CONFIRMED_FROM_OFFICIAL_APP` | exact contract documented | yes |
| SOAPAction/HTTP headers | SOAP caller + transport | `CONFIRMED_FROM_OFFICIAL_APP` | contract implemented | yes |
| Certificate pinning | APK network-security config | `CONFIRMED_FROM_OFFICIAL_APP` | documented; app pin values not imported | not required for offline gate |
| `EcraInicial` | builder + response DTO | `CONFIRMED_FROM_OFFICIAL_APP` | serializer/parser | yes |
| `DadosContribuinte` | builder + response DTO | `CONFIRMED_FROM_OFFICIAL_APP` | serializer/parser | yes, but sensitive |
| `FaturasPorClassificar` | builder + response DTO | `CONFIRMED_FROM_OFFICIAL_APP` | serializer/parser | yes |
| `FaturasPorSetor` | builder + response DTO | `CONFIRMED_FROM_OFFICIAL_APP` | serializer/parser | yes |
| Four mutating operations | builders + response DTOs | `CONFIRMED_FROM_OFFICIAL_APP` | documented, blocked | no |
| Taxy client identity acceptance | none | `UNKNOWN` | not tested | unknown |
| Business-code semantics | names only | `UNKNOWN` | preserved as opaque values | not blocking transport test |
| First Taxy TLS attempt | OpenSSL `bad record mac` before HTTP | `RUNTIME_CONFIRMED` (failure only) | classified `TLS_ERROR`; no protocol promotion | blocked pending TLS diagnosis |

## Readiness

| Operation | AUTH | SOAP | REQUEST_SCHEMA | RESPONSE_SCHEMA | SAFETY | Overall |
|---|---|---|---|---|---|---|
| `EcraInicial` | READY | READY | READY | READY | READY | READY |
| `DadosContribuinte` | READY | READY | READY | READY | PARTIAL (PII response) | PARTIAL |
| `FaturasPorClassificar` | READY | READY | READY | READY | READY | READY |
| `FaturasPorSetor` | READY | READY | READY | READY | READY | READY |

Best first candidate: `EcraInicial`, because it is read-only, requires no paging/sector choice, and returns aggregates rather than an invoice list or taxpayer name.
