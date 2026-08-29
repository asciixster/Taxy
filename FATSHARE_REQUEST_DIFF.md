# fatshareInvoices historical/current request diff

## Sources

- Historical source: local `dev-contabilidades` baseline commit `2a874f0`, `connectors/index.js`, functions/metadata `atQueryBody`, `parseAtResponse`, `invoices.query`, and the AT credential validation call.
- Current source: `tools/at_connector/src/historical.mjs` and its unit tests on branch `at-real-invoice-parsing-0.7.3`.
- Historical source is `HISTORICAL_CODE_EVIDENCE`, not official documentation.
- This comparison used no AT network request and contains no real identifier or authenticated XML.

## Sanitized structural forms

Historical serializer:

```xml
<InvoicesRequest xmlns="http://factemi.at.min_financas.pt/fatshareInvoices">
  <TaxRegistrationNumber|CustomerTaxID>&lt;TAXPAYER_ID&gt;</TaxRegistrationNumber|CustomerTaxID>
  <StartDate>&lt;START_DATE:YYYY-MM-DD&gt;</StartDate>
  <EndDate>&lt;END_DATE:YYYY-MM-DD&gt;</EndDate>
  <Pagination>
    <nPage>&lt;PAGE; DEFAULT 1&gt;</nPage>
    <nDocsPage>&lt;PAGE_SIZE; DEFAULT 300; RANGE 1..5000&gt;</nDocsPage>
  </Pagination>
</InvoicesRequest>
```

Current Taxy serializer:

```xml
<fat:InvoicesRequest xmlns:fat="http://factemi.at.min_financas.pt/fatshareInvoices">
  <fat:CustomerTaxID>&lt;TAXPAYER_ID&gt;</fat:CustomerTaxID>
  <fat:StartDate>&lt;START_DATE:YYYY-MM-DD&gt;</fat:StartDate>
  <fat:EndDate>&lt;END_DATE:YYYY-MM-DD&gt;</fat:EndDate>
  <fat:Pagination>
    <fat:nPage>1</fat:nPage>
    <fat:nDocsPage>500</fat:nDocsPage>
  </fat:Pagination>
</fat:InvoicesRequest>
```

Default-namespace and `fat:`-prefix forms have the same expanded XML names. That lexical difference alone is not a semantic namespace change.

## Field-by-field comparison

| Item | Historical | Current Taxy | Classification | Consequence |
|---|---|---|---|---|
| Root | `InvoicesRequest` | `InvoicesRequest` | identical | None known |
| Expanded namespace | `http://factemi.at.min_financas.pt/fatshareInvoices` | same | identical | Runtime-confirmed in current form |
| Namespace serialization | Default namespace | `fat:` prefix | changed, lexical only | Expanded names are identical |
| Party selector | `CustomerTaxID` only when `role === "customer"`; otherwise `TaxRegistrationNumber` | Always `CustomerTaxID` | **changed** | Can select a different invoice population |
| Party identifier source | `payload.nif` or credential NIF, non-digits stripped | Strict base NIF derived from validated username; optional supplied ID must match | **changed** | Safer binding, but less caller flexibility; not the likely empty-result cause |
| `StartDate` | Caller value, `YYYY-MM-DD` | Caller value, `YYYY-MM-DD` | identical on wire | Business meaning remains unknown |
| `EndDate` | Caller value, `YYYY-MM-DD` | Caller value, `YYYY-MM-DD` | identical on wire | Business meaning remains unknown |
| Range restriction | No maximum in located serializer | At most seven elapsed days | **changed, local guard** | Limits experiments; cannot itself filter a valid in-range request |
| Child order | party, start, end, pagination | same | identical | Regression-tested |
| `Pagination` | Always serialized | Always serialized | identical | Mandatory status still not officially established |
| `nPage` | Caller-selectable; default/minimum 1 | Constant 1 | **changed behavior**, same first-page value | No page 2 support in current harness |
| `nDocsPage` | Caller-selectable; default 300; clamp 1..5000 | Constant 500 | **changed value/behavior** | Unlikely to suppress page 1, but not officially proven |
| Extra body filters | None | None | identical | No hidden client-side filter located |
| SOAPAction | Historical operation metadata set `Invoices` | Current transport omits header | **changed transport metadata** | Absence already accepted at runtime; not a body-semantic suspect |

## Difference count

There are **7 material implementation differences** tracked by this audit:

1. party selector/default role;
2. party identifier derivation/validation;
3. maximum date-range guard;
4. page configurability;
5. page-size value/configurability;
6. namespace lexical serialization;
7. SOAPAction transport metadata.

Only item 1 has strong evidence of selecting a different result population. Items 6 and 7 are already shown not to prevent dispatch in the current runtime. The root, expanded namespace, child order, field names, date wire format, pagination element names, and absence of extra body filters are identical.

## Hidden/default filters audit

The located historical request builder contains no field for invoice status, document type, sector, country, origin, situation, fiscal role beyond the party-element selector, version, channel, software, or search mode. No omitted optional request fields were found in the local source, scripts, tests, schemas, fixtures, or comments. Because no official WSDL/XSD was located, absence from historical code is not proof that the service has no optional server-side defaults.

## Response compatibility

No non-empty historical `InvoicesResponse` was located. Historical records found offline were empty and the old parser only modeled code/description/fault. Therefore:

- current empty-response parsing is compatible with observed historical empty responses;
- current non-empty response parsing remains `UNKNOWN`;
- synthetic Taxy fixtures must not be treated as historical or official evidence.

## Regression boundary

Offline tests freeze the current request shape and the historical contract metadata without changing the live request. The documented next experiment is intentionally not implemented in this branch.
