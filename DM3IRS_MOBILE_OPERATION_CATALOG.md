# DM3IRS Mobile operation catalog

## Executive result

Seven operation roots are catalogued: six read candidates and one confirmed write by functional meaning. None is fully reconstructed and none is live-eligible. The absent APK/mobile schema prevents verification of SOAP version, action, namespace, field sequence, auth envelope, response models and side-effect semantics.

The service location is an `APK_OBSERVATION_SUPPLIED`, not an official public contract:

`https://servicos.portaldasfinancas.gov.pt:411/dm3irsMobileService/`

## Common transport and auth contract

| Property | Result | Evidence |
|---|---|---|
| SOAP version | `UNKNOWN` | mobile WSDL/XSD unavailable |
| SOAPAction | `UNKNOWN` per operation | mobile WSDL/XSD unavailable |
| operation namespace | `UNKNOWN` | the two reported schema URIs are locations, not proven XML namespace values |
| TLS endpoint | observed candidate on port 411 | supplied APK observation only |
| mTLS required | `UNKNOWN` | no handshake with an identity was attempted |
| WS-Security/header | `UNKNOWN` | no serializer/auth class available |
| public request-encryption key | existing AT public cert: certificate SHA-256 `43b40f…6383`, SPKI SHA-256 `b19983…4968`, RSA 4096 | existing sanitized Taxy evidence; equality with IRS-app material is not established |
| Taxy authorization | `UNKNOWN` | authorization is operation- and service-specific; FactIntWS success is not transitive |

The Taxy legitimate identity is documented only by public fingerprint metadata in `AT_IDENTITY_CAPABILITY_MAP.md`. No private material was opened, copied or committed.

## Operation matrix

| Operation | Functional hypothesis | Semantics status | APK trace | Schema confidence | Gate |
|---|---|---|---|---|---|
| `obterCatalogosMobileRequest` | obtain declaration catalogs | `READ_CANDIDATE` | unavailable | root name only | NO LIVE |
| `infoUtilizadorAutenticadoMobileRequest` | authenticated-user information | `READ_CANDIDATE` | unavailable | root name only | NO LIVE |
| `infoAgregadoMobileRequest` | household information | `READ_CANDIDATE` | unavailable | root name only | NO LIVE |
| `checkEntregaDeclMobileRequest` | check delivery eligibility/state | `READ_CANDIDATE_SIDE_EFFECT_UNPROVEN` | unavailable | root name only | NO LIVE |
| `obterReceiptMobileRequest` | obtain receipt/proof | `READ_CANDIDATE` | unavailable | root name only | NO LIVE |
| `obterDeclaracaoMobileRequest` | obtain declaration data | `READ_CANDIDATE` | unavailable | root name only | NO LIVE |
| `submeterDeclaracaoMobileRequest` | submit declaration | `WRITE` | deliberately not reconstructed | root name only | PROHIBITED |

## Per-operation reconstruction

For every read candidate, the only contract item confirmed from the supplied APK observation is the root request name. Endpoint, version, SOAPAction and XML namespace cannot be inferred from Java/KSOAP naming conventions.

### `infoUtilizadorAutenticadoMobileRequest`

- Exact endpoint: service-path candidate only; operation binding `UNKNOWN`.
- Required/optional fields, auth header, encryption/digest: `UNKNOWN`.
- Response root/fields, faults/statuses: `UNKNOWN`.
- Builder, serializer, parser, repository, calling screen, consumer: `NOT_VERIFIABLE_APK_ABSENT`.
- Data claims: zero taxpayer-profile response fields are discoverable from a parser/model. Residence, marital status and fiscal situation remain hypotheses, not findings.
- Sequence dependency and no-side-effect proof: `UNKNOWN`.

### `infoAgregadoMobileRequest`

- Contract and APK trace: `UNKNOWN` / `NOT_VERIFIABLE_APK_ABSENT` as above.
- Data claims: zero household response fields are discoverable from a parser/model.
- The public Modelo 3 XSD contains declaration-input concepts `IntegraAgregadoSP`, `IntegraAgregadoOutro` and `Dependente`; this does not prove the mobile operation returns them.

### `obterCatalogosMobileRequest`

- Contract and APK trace: `UNKNOWN` / `NOT_VERIFIABLE_APK_ABSENT`.
- Public-schema evidence: `types.xsd` exposes 32 income/activity/country-related catalog types, including Article 151 activity codes and `Cat_M3V2026_AnexoBRendimentos`.
- Mobile-response groups discoverable: zero. It is not proven that this operation emits any public-XSD catalog.
- The operation would be first in a future controlled probe because it is expected to be least sensitive, not because authorization/read semantics are currently proven.

### `obterDeclaracaoMobileRequest`

- Contract and APK trace: `UNKNOWN` / `NOT_VERIFIABLE_APK_ABSENT`.
- Public product evidence: the official app listing states that a user can consult the 2025 declaration. The linkage to this exact request is plausible but unverified.
- Public XSD evidence: `Modelo3IRSv2026` defines `Rosto` plus 13 annex groups. This is an input/filing schema, not proof that the operation returns a submitted declaration, draft, prefill, calculation or liquidation.
- Mobile declaration groups discoverable: zero. Public declaration-input groups discoverable: 14.
- Official calculation outputs: none discovered.

### `checkEntregaDeclMobileRequest`

- Contract and APK trace: `UNKNOWN` / `NOT_VERIFIABLE_APK_ABSENT`.
- “Check” is not enough to prove read-only or absence of server state. It stays explicitly blocked until the call graph and request contract show no submission/preparation side effect.
- Potential monitoring (conditional only): declaration delivery-state change.

### `obterReceiptMobileRequest`

- Contract and APK trace: `UNKNOWN` / `NOT_VERIFIABLE_APK_ABSENT`.
- Return type (metadata, binary/PDF, identifier, status) is unknown.
- Potential monitoring (conditional only): proof/receipt availability.
- No receipt download or persistence occurred.

### `submeterDeclaracaoMobileRequest`

- Classified `WRITE` by operation meaning.
- Request/response detail deliberately not reconstructed beyond the supplied root name.
- It is excluded from tooling and probing. `writeRequests = 0`.

## APK trace ledger

| Operation | Builder/request class | Serializer | Parser | Repository/service | Calling screen | Consumer |
|---|---|---|---|---|---|---|
| all six read candidates | not available | not available | not available | not available | not available | not available |
| submit | write-block | write-block | write-block | write-block | write-block | write-block |

This is a documented evidence gap, not a negative claim about what the official APK contains.

## Live gate decision

Required: confirmed read-only + sufficiently reconstructed schema + legitimate Taxy auth path + deterministic request + confirmed no side effect.

Result for every candidate: **NO_LIVE_PROBE**. At least schema, authorization and side-effect proof fail. Consequently, business `networkRequests = 0`, live requests = 0 and write requests = 0.

The earlier attempts to retrieve public schema/WSDL metadata failed during TLS before HTTP and did not carry credentials or a SOAP body. They are documentation retrieval attempts, not operation probes.
