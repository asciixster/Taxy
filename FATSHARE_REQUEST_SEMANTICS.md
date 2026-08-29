# fatshareInvoices request semantics

## Scope and evidence boundary

This document began as an offline audit of the `InvoicesRequest` used by Taxy 0.7.3. The audit itself made **zero AT network requests**. A later authorized single-variable experiment changed only `CustomerTaxID` to `TaxRegistrationNumber` for the same 28-day interval. It also returned HTTP 200, no SOAP fault, `EstadoOperacao` 486, `Desc` "Lista de faturas vazia", and zero invoices.

Evidence labels mean:

- `RUNTIME_BEHAVIOR_CONFIRMED`: observed in those controlled responses.
- `HISTORICAL_CODE_EVIDENCE`: found in the original local implementation at baseline commit `2a874f0`, `connectors/index.js`; it is not official documentation.
- `OFFICIAL_DOCUMENTATION`: directly stated in an AT publication already cited by the project.
- `INFERENCE`: a bounded interpretation, not a demonstrated contract.
- `UNKNOWN`: not established.

## Current sanitized request body

```xml
<fat:InvoicesRequest xmlns:fat="http://factemi.at.min_financas.pt/fatshareInvoices">
  <fat:TaxRegistrationNumber>&lt;TAXPAYER_ID&gt;</fat:TaxRegistrationNumber>
  <fat:StartDate>&lt;START_DATE:YYYY-MM-DD&gt;</fat:StartDate>
  <fat:EndDate>&lt;END_DATE:YYYY-MM-DD&gt;</fat:EndDate>
  <fat:Pagination>
    <fat:nPage>1</fat:nPage>
    <fat:nDocsPage>500</fat:nDocsPage>
  </fat:Pagination>
</fat:InvoicesRequest>
```

The body contains exactly the elements above, in that order. It contains no explicit status, document type, sector, country, origin, channel, software, pending-state, invoice-direction, fiscal-year, or other filter. The authenticated header is intentionally excluded from this representation.

## Field map

| Field | Current value/source | Required | Type | Evidence source | Known meaning | Confidence | Potential effect on empty result |
|---|---|---:|---|---|---|---|---|
| `InvoicesRequest` | Constant root | yes | XML element | `RUNTIME_BEHAVIOR_CONFIRMED` | Operation dispatched successfully with this root and namespace | high | Low after successful dispatch |
| Namespace | `http://factemi.at.min_financas.pt/fatshareInvoices` | yes | URI | `RUNTIME_BEHAVIOR_CONFIRMED` | Expanded namespace accepted for `InvoicesRequest` | high | Low after successful dispatch |
| `TaxRegistrationNumber` | Base nine-digit NIF derived from `AT_USERNAME`; primary NIF remains unchanged, subuser suffix is removed | yes in current serializer | nine digits | `HISTORICAL_CODE_EVIDENCE` | Historical code used this element for its default/supplier role. The server accepted the serialization, but returned an empty list, so the population semantics were not confirmed. | medium | The empty result disproved neither role; this selector alone did not produce data for the controlled interval |
| `StartDate` | Harness input | yes | date-only `YYYY-MM-DD` | `HISTORICAL_CODE_EVIDENCE` | Lower bound and format accepted at runtime; whether it is issue, communication, registration, or another date is unknown | medium for format; unknown for business meaning | Medium |
| `EndDate` | Harness input | yes | date-only `YYYY-MM-DD` | `HISTORICAL_CODE_EVIDENCE` | Upper bound and format accepted at runtime; inclusivity and business-date meaning are unknown | medium for format; unknown for business meaning | Medium |
| `Pagination` | Constant container | yes in current serializer and historical implementation | XML element | `HISTORICAL_CODE_EVIDENCE` | Pagination container; the current form was accepted at runtime | medium | Low to medium |
| `nPage` | Constant `1` | yes in current serializer | integer | `HISTORICAL_CODE_EVIDENCE` | Historical code clamped pages to at least 1, indicating one-based indexing; value 1 was accepted at runtime | medium | Low for page 1 |
| `nDocsPage` | Constant `500` | yes in current serializer | integer | `HISTORICAL_CODE_EVIDENCE` | Requested page capacity; historical default was 300 and allowed 1..5000; value 500 was accepted at runtime | medium | Low: a larger positive capacity should not normally suppress all rows, but semantics are not official |

## Dates

- Names and order: `StartDate`, then `EndDate` — `HISTORICAL_EVIDENCE` and runtime-accepted.
- Wire format: `YYYY-MM-DD`, date-only — `CONFIRMED` for accepted serialization.
- Start/end ordering: current and historical validators reject start after end — local implementation behavior.
- Inclusivity: `UNKNOWN`.
- Whether the date is issue, communication, registration, or another business event: `UNKNOWN`.
- Timezone: none is serialized; business timezone semantics are `UNKNOWN`.
- Separate fiscal-year field: none exists in current or located historical request.
- Current live harness guard: at most seven elapsed days. This is a Taxy safety restriction, not an established AT contract. One earlier controlled 28-day run was performed before the guard was tightened.

## Party and population

The historical serializer had a two-way selector:

- `role === "customer"` -> `CustomerTaxID`
- every other/default role -> `TaxRegistrationNumber`

Its credential-validation call explicitly selected `role: "supplier"`. That is strong historical evidence that the two fields select different invoice populations. It does **not** establish that either population corresponds exactly to the consumer purchases visible in the current e-Fatura application. The controlled `TaxRegistrationNumber` experiment returned the same empty business result as `CustomerTaxID`, so the role/population hypothesis is `NOT_CONFIRMED`.

Hypotheses and boundaries:

| Hypothesis | Evidence | Confidence | Contradictions / gaps |
|---|---|---|---|
| `CustomerTaxID` selects the customer/acquirer side | Literal historical role name `customer` | medium | No located official definition; runtime acceptance proves syntax, not population |
| `TaxRegistrationNumber` selects supplier/issuer-side records | Historical default and explicit `supplier` validation call | medium-high | No non-empty historical response was found |
| Results are limited to invoices associated with a specific channel/software/certificate | None in body or located historical code | low | No such filter is serialized; server-side scope remains unknown |
| Results are pending/classifiable-only | No matching request field found | low | No historical non-empty response or official schema was found |

## Pagination

- Field names: `Pagination/nPage/nDocsPage` — historical evidence and runtime-accepted.
- Page base: historical code clamps to a minimum of 1; therefore one-based is `HISTORICAL_EVIDENCE`, not official proof.
- Current values: page 1, 500 documents.
- Historical defaults: page 1, 300 documents; caller could select page and size, with size clamped to 1..5000.
- Mandatory status: both located implementations always serialized the container; an official schema was not found.
- `totalPages`: absent in all four empty runtime responses. Whether it appears only for non-empty results is `UNKNOWN`.
- No page 2 request was made.

## `EstadoOperacao` 486

The only supported statement is the observed pair: `486` plus `Lista de faturas vazia` in controlled empty responses. The historical parser listed 486 among non-fault/accepted codes, and locally stored historical executions also paired 486 with an empty list. This supports “handled empty-result condition” as historical behavior, but does not prove a universal definition for code 486 across services, roles, or filters.

## Historical response/parser evidence

The offline search covered the historical Git source and plausible project, audit, backup, archive, download, and service directories while excluding repositories, dependencies, caches, and browser artifacts. No sanitized or real non-empty `InvoicesResponse` fixture/schema was found. Located historical executions were empty. The old parser extracted only operation code, description, and SOAP fault state; it retained raw XML but did not model invoice fields.

Consequently, compatibility of `AtInvoice`, `AtInvoicePage`, `AtInvoiceQueryResult`, and `AtDateOnly` with a real non-empty historical response is **UNKNOWN**. Existing non-empty parser fixtures are explicitly synthetic and are not runtime evidence.

## fatshareInvoices versus FactIntWS

| Dimension | fatshareInvoices | FactIntWS research | Conclusion |
|---|---|---|---|
| Apparent purpose | Read-only `InvoicesRequest` list consultation | Official-app historical service with a distinct contract | Different products/contracts; equivalence is unproven |
| Observed population | Empty results with both `CustomerTaxID` and `TaxRegistrationNumber` | No Taxy runtime population observed | Unknown on both sides |
| Operations available | Only the read-only query is implemented in Taxy | Research notes imply a broader mobile application service | Must not mix operations or assumptions |
| Authentication | mTLS plus encrypted WS-Security credentials in Taxy | Separate `SecurityContext` and historical namespaces | Structurally different; no credentials/material are shared |
| Response model | `InvoicesResponse`; only empty response is runtime-confirmed | Not runtime-tested | No cross-protocol parser inference |
| Filters | Party identifier, start/end dates, pagination | Not established in Taxy | No field mapping can be claimed |

No FactIntWS request was executed during this audit.

## Ranked empty-result hypotheses

| Rank | Category | Supporting evidence | Contradicting evidence | Confidence | Required single-variable experiment |
|---:|---|---|---|---|---|
| 1 | `DATE_SEMANTICS` | Business meaning and inclusivity are undocumented locally | Three increasingly broad accepted intervals remained empty | medium | Requires independent evidence before another experiment |
| 2 | `GENUINELY_EMPTY_DATA` | Empty response is internally consistent and no fault occurred for both party fields | Expectation of data remains unverified for the queried service population | medium | Confirm independently that this operation/population contains a known record |
| 3 | `ROLE/POPULATION_MISMATCH` | Historical code distinguishes the two party fields | The controlled `TaxRegistrationNumber` request returned the same empty result as `CustomerTaxID` | low | Experiment completed; hypothesis not confirmed |
| 4 | `CUSTOMER_TAX_ID_SEMANTICS` | Authentication identity and query party are separate concepts | Switching away from `CustomerTaxID` did not produce data | low | Experiment completed; hypothesis not confirmed |
| 5 | `HISTORICAL_PROTOCOL_DRIFT` | Historical transport and defaults differ | Root, namespace, body order, and field names were accepted | low-medium | Not selected |
| 6 | `PAGINATION_PARAMETER_ERROR` | Official pagination semantics/schema were not found | Positive page/size were accepted; page 1 is historical default | low | Not selected |
| 7 | `REQUEST_FILTER_ERROR` | Server-side defaults cannot be excluded | No hidden filter exists in current or historical body | low | Not selected |

## Completed single-variable experiment

The controlled read-only experiment changed only:

```text
CustomerTaxID -> TaxRegistrationNumber
```

The identifier value, 28-day interval `2026-08-01` through `2026-08-28`, page 1, page size 500, endpoint, namespace, SOAP version, SOAPAction absence, encryption, timestamp behavior, credentials, certificate, and parser were preserved. The single request completed with authorized mTLS, HTTP 200, no SOAP fault, `EstadoOperacao` 486, and zero invoices. Classification: `SUCCESS_EMPTY_RESULT`; `ROLE_POPULATION_HYPOTHESIS_NOT_CONFIRMED`. `TaxRegistrationNumber` is therefore **not** promoted to `RUNTIME_BEHAVIOR_CONFIRMED` population semantics.
