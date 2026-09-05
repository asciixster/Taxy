# Fiscal data orchestration

## Purpose

Taxy 0.8.1 connects the existing fiscal profile, guided interview, normalized ledgers,
e-Fatura evidence, estimate and Home without creating a second fiscal profile.
`FiscalProfile` remains the value source consumed by the application. The orchestration
layer records candidates, provenance, confidence, fiscal year and freshness, detects
conflicts and derives presentation state.

## Flow

`source evidence -> FiscalDataOrchestrator -> conflicts/missing/section state -> interview + Home`

The IRS engine continues to consume only normalized supported inputs. e-Fatura evidence
does not enter the calculation merely because it exists.

## Sources and precedence

| Source | Typical use | Default priority |
|---|---|---:|
| Explicit user override | A resolved conflict | 100 |
| Interview/user-entered | Confirmed answer | 90 |
| Official | Runtime-confirmed e-Fatura evidence | 80 |
| Imported | Existing profile/ledger prefill | 60 |
| Calculated | Derived output | 50 |
| Inferred | Suggestion requiring review | 20 |

Priority is not silent conflict resolution. Different values produce `FiscalDataConflict`.
An explicit user selection is stored as an override while the source candidates remain
available to the resolution flow.

## Tax-year and freshness rules

- Every point has an explicit fiscal year.
- Candidates for another year are ignored; interview/e-Fatura year mismatches fail closed.
- Official/imported data without a timestamp is stale.
- External data older than 31 days is stale for companion presentation.
- Profile and interview values are not assigned artificial network freshness.

## e-Fatura boundary

Only runtime-confirmed availability, invoice count and pending count are companion evidence.
Provisional benefit and sector aggregates remain unavailable and are never converted to zero.
Pending invoices may generate a read-only next action that sends the user to the official
channel. Disconnect clears only e-Fatura evidence/session, not profile/interview data.

## Missing data and section state

Missing items are centralized as `TaxMissingDataItem` with area, severity, reason and action.
Severity is `requiredForCalculation`, `improvesEstimate` or `optional`. Interview sections are
`clean`, `needsReview` or `incomplete`. Conflicting/new evidence marks only the affected section.

## Estimate consistency

Estimate state is `ready`, `provisional`, `incomplete` or `unavailable`. Unsupported income
keeps the estimate provisional and fail-closed. `TaxEstimateSnapshot` stores tax year, engine
version, result, completeness and a deterministic fingerprint of normalized inputs—not raw PII.

## Privacy and observability

Allowed analytics are event names and technical outcome categories. Fiscal values, answers,
NIFs, documents and estimates are prohibited. No AT write operation is introduced.

## Android real-device validation

The 0.8.1 internal-beta build was validated on Android 15/API 35 with the experimental
e-Fatura flag enabled only for the smoke build. A clean install completed a partial guided
interview, connected to the read-only backend, received available aggregate evidence, and
updated Home with a pending-invoice next action. Completing the interview produced an
estimate; editing a supported income answer recalculated it and displayed the change summary.

After force-stop and cold relaunch, the interview, estimate and e-Fatura companion state were
restored. Disconnecting e-Fatura cleared its session/evidence while preserving the manual
fiscal estimate. No raw response, credential, taxpayer identifier, invoice identifier or
other personal value was retained as test evidence.
