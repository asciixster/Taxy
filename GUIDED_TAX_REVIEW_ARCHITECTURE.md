# Guided tax review architecture — 0.8.3

## Product contract

The review is the synthesis layer after the guided interview. It answers four
questions in order: what Taxy knows, what is missing, what the known data means
for the supported IRS calculation, and the single best next action. It does not
duplicate the interview or the tax engine.

`TaxInterview + FiscalProfile + evidence + e-Fatura → orchestration → review → presentation policy`

## Central models

- `TaxReviewCompleteness`: `ready`, `needsReview`, `incomplete`, or
  `unsupportedSituation`. Ready means the supported scenario has the required
  data and no unresolved critical conflict; it is not an official declaration.
- `TaxCalculationInclusion`: records whether a relevant fact is included,
  missing, conflicted, not relevant, or excluded because the engine does not
  support that situation.
- `TaxEstimatePresentationPolicy`: is the only place that decides whether the
  UI shows a complete estimate, a visibly partial estimate, or no amount.
- `TaxExplainabilityViewModel`: translates the existing `TaxResult` and its
  trace into human concepts. It never recalculates tax.
- `TaxReviewNextAction`: produces one primary action using conflict, required
  missing data, unsupported situations, interview progress, e-Fatura pending
  items, and estimate review in that order.

## Conflict safety

A conflict keeps both candidates and their provenance. Selecting a candidate
stores the selected value, source, competing value, resolution time, and fiscal
year inside the existing year-scoped interview. The underlying document
evidence remains intact. A resolution applies only while the exact pair remains
the same; changed evidence reopens the conflict. “Review later” leaves the
conflict unresolved and prevents a falsely complete presentation.

## Calculation and explainability

The existing `TaxEngine` remains the sole calculation authority. Positive
`TaxResult.balance` means an estimated refund and negative means estimated tax
to pay. The review uses this documented contract rather than inferring the
meaning of a sign in a widget. Income, credits, tax due, withholding, and result
come directly from engine output.

Self-employment, pension, foreign, and rental income are identified and shown as
not included. They are never approximated. The current policy hides a
conclusive amount when required inputs are missing or an unsupported situation
exists; unresolved evidence conflicts permit only an explicitly partial
presentation.

## Persistence, years, and navigation

Only answers, evidence metadata, and explicit conflict resolutions are
persisted. Completeness, inclusion, explanation, and next action are derived on
open. Every input is scoped to a fiscal year, so switching year rebuilds the
review instead of carrying an estimate or conflict across years. Review edits
return to the existing interview question flow; they do not create a second
fiscal profile.

## Privacy and observability

The UI may display the user’s fiscal data locally. Logs and analytics must not
contain amounts, answers, income types, household state, evidence, conflicts,
or estimates. Allowed lifecycle events are names such as `review_opened`,
`conflict_resolution_opened`, `review_completed`, and `next_action_opened`,
without fiscal properties.

## Out of scope

No IRS formula, OCR, raw document storage, filing, legal deadline, e-Fatura
write operation, or direct FactIntWS request is introduced by this release.
