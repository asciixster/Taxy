# IRS history assisted prefill — V1 boundary

## Supported runtime V1

The Android connector allowlists three read-only operations: delivery check, receipt lookup and declaration retrieval. It supports only tax year 2024 and only the structural template fingerprint `MODELO3_2024_V1` confirmed at runtime.

Accepted parser output is limited to exact ownership by template, annex, printed field code and cell coordinates:

- declaration availability and year;
- annex A, C, H and SS presence;
- Category A and Category B presence;
- organized-accounting Category B regime;
- activity code;
- field 470 taxable profit;
- field 602 withholding.

The raw SOAP bodies, declaration identifiers, PDF bytes and recognized text remain session-only. On Android 11 or later, the PDF is decoded into an anonymous in-memory file descriptor, parsed locally, zeroed and released. Earlier Android versions fall back to the manual interview. Only user-confirmed minimal values, source year, target year, confirmation time, official provenance, exact confidence and the template fingerprint can be persisted.

## Product boundary

`HistoricalTaxEvidence` is not a `TaxFact`. The screen presents historical suggestions with confirm, edit and ignore controls. Only an explicit confirmation can create or update a mapped current-year interview answer. Source year 2024 never equals or silently becomes target year 2025/2026.

Category B regime, activity code and historical taxable profit remain historical context because the production Category B engine is unsupported. Category presence and withholding can update their existing interview equivalents only after the user confirms them.

## Fail-closed behavior

The parser rejects an unknown page count, annex order, missing anchor, duplicate/ambiguous cell, non-exact value, malformed Base64 or invalid PDF magic. Unknown templates produce no suggestions and the manual interview remains available.

Field 603 (payments on account) is marked `RUNTIME_VALIDATION_REQUIRED` and is never returned to Flutter, even though the research parser recognizes its printed location.

## Network and security

- Exact endpoint: `https://servicos.portaldasfinancas.gov.pt:411/ws/dm3irsMobileService/`.
- SOAP 1.1 and the three exact read actions are hard-coded in an enum allowlist.
- `submeterDeclaracaoMobileRequest` has no transport path and is explicitly listed as prohibited in tests.
- The app uses only the user-selected legitimate Taxy client identity from Android KeyChain.
- The official IRS application's private identity is neither bundled nor accessed.
- Credentials are encrypted with an Android Keystore key and are never logged.
- The history screen uses `FLAG_SECURE`; analytics and crash payloads contain no fiscal data.

## Explicitly unsupported

- field 603 payments on account;
- ambiguous or high-confidence-only fields;
- any unknown template or tax year;
- automatic TaxFact import;
- Category B calculation;
- IRS submission or declaration mutation;
- any DM3IRS write;
- any field not confirmed in the runtime V1 evidence.
