# DM3IRS catalogs vs authenticated-user request diff

Date: 2026-09-08  
Scope: offline analysis only; no network request and no official-app private identity used.

## Outcome

`obterCatalogosMobileRequest` succeeded because its only operation-specific input was present. The failed `infoUtilizadorAutenticadoMobileRequest` probe sent an empty request element, while the official app call-site always supplies two non-null context values: selected exercise year followed by base taxpayer NIF. The serializer has null guards, but these are implementation guards, not evidence that the official flow intentionally omits the fields.

The highest-confidence explanation is therefore a malformed/incomplete operation body, not an entitlement failure. The retained evidence does not include the SOAP Fault body, so its exact `faultcode`, sanitized `faultstring`, detail names and server error code are `NOT_RETAINED` and cannot be recovered offline.

## Retained fault evidence

| Item | Result |
|---|---|
| HTTP | `500` |
| SOAP envelope | present |
| SOAP Fault | present |
| faultcode | `NOT_RETAINED` |
| faultstring | `NOT_RETAINED` |
| detail element names | `NOT_RETAINED` |
| detail namespace | `NOT_RETAINED` |
| server/application error code | `NOT_RETAINED` |
| sanitized category | `REQUEST_ERROR` |

`NOT_RETAINED` must not be read as “absent”. The raw response was intentionally zeroed after the one-shot probe to prevent PII persistence.

## Wire comparison

| Property | Successful catalogs request | Failed infoUser request | Official infoUser builder | Classification |
|---|---|---|---|---|
| Endpoint | production DM3IRS endpoint | same | same default endpoint | irrelevant / equal |
| SOAP version | 1.1 | 1.1 | 1.1 | irrelevant / equal |
| SOAPAction | `tns:obterCatalogosMobileRequest` | `tns:infoUtilizadorAutenticadoMobileRequest` | `tns:` + operation name | operation-specific and exact |
| Envelope namespace | SOAP 1.1 namespace | same | same | irrelevant / equal |
| WS-Security | encrypted password/digest/nonce, Created, SPA actor, version 2 | same structure | common `addUser()` path | irrelevant / semantic parity |
| Body root | catalogs operation | infoUser operation | infoUser operation | operation-specific and exact |
| Body namespace | DM3IRS mobile schema | same | same | irrelevant / equal |
| Operation fields | `tipoCatalogo` populated | none | `ano-fiscal`, then `nif`, both populated | **critical** |
| Content-Type | `text/xml` | `text/xml` | SOAP 1.1 content type | irrelevant / equal |
| Content-Length | derived from bytes | derived from bytes | runtime-derived | irrelevant |
| Created/Nonce | fresh per request | fresh per request | fresh per request | irrelevant / expected difference |
| Channel/device metadata | none | none | none in builder/call-site | irrelevant / equal |
| Cookies/bearer | none | none | no handling found | no dependency found |

## Exact official call-site reconstruction

Observed call chain:

1. `AuthenticationService.navigateAfterDelivery` obtains the exercise year from `AppDataService.exerciseYearForRequests`; absence causes `BadIrsYearException`.
2. The same method reads base NIF from `CredentialsService.field_7` and converts the selected exercise year to a string.
3. `AuthenticationService.getPostLoginNavigation` calls `UserInfoService.fetchUserInformation(yearString, baseNif)`.
4. `UserInfoService.fetchUserInformation` creates the insertion-ordered map `nif → baseNif`, `year → yearString`.
5. `UserInfoRequestBuilder.addBody` reads `year` first and emits `sch:ano-fiscal`; it then reads `nif` and emits `sch:nif`.
6. `ApiService.performRequest` sets HTTP `SOAPAction` to `tns:` plus the operation name and builds the shared SOAP/WS-Security envelope.

Canonical operation body:

```xml
<sch:infoUtilizadorAutenticadoMobileRequest>
  <sch:ano-fiscal>SYNTHETIC_YEAR</sch:ano-fiscal>
  <sch:nif>SYNTHETIC_BASE_NIF</sch:nif>
</sch:infoUtilizadorAutenticadoMobileRequest>
```

The NIF in the body is the base taxpayer identifier. The WS-Security username is `CredentialsService.fullNif`: base NIF alone or base NIF plus subuser suffix. Both are strings. The body does not use the full login identity.

## Required context matrix

| Context | Status | Evidence |
|---|---|---|
| selected exercise/tax year | `REQUIRED_CONFIRMED` | accessor throws when undefined; call-site always stringifies and passes it |
| base NIF in body | `REQUIRED_CONFIRMED` | read from credentials state and always passed by official call-site |
| full login identity in WS-Security | `REQUIRED_CONFIRMED` | common `addUser()` uses `fullNif` |
| selected taxpayer distinct from base NIF | `NOT_USED` | no separate selector in this call path |
| server session ID | `NOT_USED` | no session ID serialized |
| channel / Sistema / Versao | `NOT_USED` | absent from builder and call-site |
| app version / platform / device metadata | `NOT_USED` | absent from operation and shared request builder |
| bearer token | `NOT_USED` | no bearer path found |
| cookies | `NOT_USED` | no Cookie/Set-Cookie propagation found in DM3IRS client path |
| prior catalogs result | `NOT_USED` | catalogs are loaded after infoUser in the observed login flow |
| prior declaration check | `POSSIBLE_LOCAL_SEQUENCE_ONLY` | login flow checks delivery first, but no server-side state token/cookie dependency was found |

## Absent, empty and value behavior

For `year` and `nif`, the generated serializer behaves as follows:

| Map state | Wire state |
|---|---|
| key missing or value `null` | element `ABSENT` |
| value empty string | element present with `EMPTY_STRING` text |
| non-empty string | element present with `VALUE` |
| explicit XML nil | not generated by this builder |

The failed probe used `ABSENT` for both. The official call-site uses `VALUE` for both. Thus there are two concrete absent-vs-value differences and no empty-vs-value difference.

## Authentication parity

The catalogs and infoUser probes used the same legitimate Taxy client identity, endpoint, TLS requirements and semantic WS-Security algorithm/structure. Dynamic key material, nonce, digest and Created necessarily differ per request. No operation-specific authentication header was found.

## Sanitized canonical hashes

These hashes cover only the canonical operation body with placeholders; no credential or real identifier is included.

- failed empty body: `a225f44b8355d91d0868a275563055a4fc5df18c2f77d9fcae7fab3115a2fbfa`
- official synthetic body: `41ee027b67ef49697ca5582c2ce246bdffeed75626467ed8883e81dc7bf207eb`

## Difference classification

1. **CRITICAL:** `sch:ano-fiscal` was absent but the official call-site always provides a selected exercise year.
2. **CRITICAL:** `sch:nif` was absent but the official call-site always provides the base NIF.
3. **IRRELEVANT:** expected per-request differences in Created, nonce, digest and Content-Length.

No credible channel, cookie, bearer, device metadata or prior-catalog dependency was found.

## Retry gate

A separately authorized corrected probe was subsequently executed with both ordered values. It reached HTTP 200, returned the exact `infoUtilizadorAutenticadoMobileResponse` root without a SOAP Fault, and returned business status `130` with no profile fields. This validates the request framing correction but does not establish successful profile retrieval. The status meaning was not found in the retained static fixtures, so no further request should be made until the AT clarifies it or supplies the relevant status catalogue.

## Classification

`DM3IRS_INFOUSER_REQUEST_CONTEXT_MISMATCH_CORRECTED_STATUS_130`
