# Guided document evidence

## Scope

Taxy 0.8.2 adds a deliberately narrow evidence workflow for values already supported by
the current IRS estimate: employment gross income, IRS withholding and mandatory Social
Security contributions. It does not perform OCR, upload a document or claim support for a
tax category that the engine cannot calculate.

## Confirmation flow

`document -> user reads value -> explicit confirmation -> year-scoped evidence -> TaxFact candidate`

Only the confirmed integer-cent amount, document type, fiscal year and confirmation time are
stored in the app-private data directory. The original file, its path, filename, image, text,
issuer and identifiers are neither uploaded nor persisted.

When a fact is not already known, confirmed evidence can prefill the guided interview with
`IMPORTED` provenance. When it differs from an existing answer, the orchestration layer emits
`DATA_CONFLICT`; it never silently overwrites the user answer.

## Supported document types

| Type | Normalized fact | Calculation support |
|---|---|---|
| Employment income statement | `employmentGrossCents` | Supported simple employee case |
| IRS withholding proof | `withholdingCents` | Supported simple employee case |
| Social Security contributions proof | `socialSecurityCents` | Supported simple employee case |

All monetary values use integer cents. Evidence is isolated by fiscal year and is removed by
the explicit reset for that year.

## Complex income boundary

Self-employment, pensions, foreign income and rental income remain identifiable TaxFacts.
The result screen lists identified complex situations and states that they are excluded until
the engine supports them safely. No approximation or tax formula was added in 0.8.2.

## Privacy and future work

There is no analytics payload for document type, amount or status. Future OCR/import work must
use an app-private encrypted file lifecycle, explicit review, deletion controls and a separate
security review before any raw document is retained.
