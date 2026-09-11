# AT read capability discovery — decision record

## Scope and result

This isolated worktree inventories legitimate read-only opportunities without changing Flutter, backend, connector production code or IRS formulas. It made **0 AT business requests** and **0 writes**. Documentation/WSDL retrieval is research traffic, not a taxpayer operation.

The reproducible catalog contains 16 endpoint/deployment records and 29 operations: 9 read-only, 17 write, 2 mixed, 1 unknown. Five read operations have prior runtime evidence (FactIntWS overview/pending/by-sector dispatch plus the Portal acquired-documents page/JSON flow). Only the Portal acquired-documents flow has the correct, non-empty personal population already used by Taxy production.

## Feasibility summary

| Capability | Result | Why |
|---|---|---|
| taxpayer profile/activity/CAE/CIRS/IVA regime | UNKNOWN | public ATGo capability, no public Taxy-authorizable endpoint |
| issued invoices | UNKNOWN | official fatshare read schema; intended production authorization not confirmed |
| received invoices | YES | legitimate Portal flow and normalized runtime confirmed |
| reported income/withholding | UNKNOWN | submission formats exist; no personal read API found |
| IRS declaration/assessment/payments/debt/obligations | UNKNOWN | Portal functions exist, no documented read contract mapped |
| VIES status | YES | official EU public read service; narrower than taxpayer IVA profile |

## Controlled probe decision

No new probe passed all three gates: explicit read semantics, sufficiently understood schema, and authorization of the current Taxy identity/session. Therefore a zero-request result is the safe discovery outcome. Existing runtime evidence was reused rather than repeating calls.

## Runtime-confirmed response field inventory

| Source | Field/category presence | Type/use | Persistence boundary |
|---|---|---|---|
| Portal acquired documents | date, total, VAT, issuer display, sector/status, pending state | invoice explorer/expenses | normalized fields only; no NIF/document ID/raw JSON |
| FactIntWS overview | operation status, pending/revenue counts, total/sector aggregates and sectors | overview semantics | current Taxy population was zero; never treat as account truth |
| FactIntWS pending/by-sector | operation status/list container | dispatch and empty-result contract | no real item payload stored |
| fatshare historical sandbox | operation status/description and invoice list envelope | schema/dispatch | empty response only; no PII |

## Highest-confidence conclusions

1. AT's public integration estate is optimized for businesses to **communicate** declarations/documents, not for third-party personal finance apps to read the taxpayer account.
2. The newly public `fatshareInvoices.wsdl` materially strengthens schema evidence for invoice consultation, but entitlement still needs AT confirmation.
3. ATGo proves high-value profile and analytics data exists inside an official application context. It is not a license to reuse that private context.
4. The next credible implementation is not broad Portal scraping. It is an authorization-focused release for taxpayer profile and fatshare issued invoices, with an AT clarification request before code.

## Production gate

No capability may be promoted without official/legitimate source, auth, read-only semantics, understood schema, runtime confirmation and sanitized tests. `unavailable` remains distinct from zero.
