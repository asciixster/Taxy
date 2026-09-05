# Guided tax interview architecture

## Flow

`TaxQuestion → TaxAnswer → TaxFact → next visible TaxQuestion → estimate → explanation → TaxNextAction`

The UI renders one question. It does not decide fiscal relevance. The
`TaxInterviewEngine` owns visibility, progress, missing-data classification and
cleanup. `FiscalProfile` remains the single source of truth for fields already
owned by the product model.

## Model

- `TaxInterview` is scoped to one explicit tax year.
- `TaxInterviewSection` represents the seven product areas, not tax forms.
- `TaxQuestion` describes the input type and localization keys.
- `TaxRule` is presentation-independent.
- `TaxAnswer` stores only a typed value and provenance.
- `TaxFact` adds year, provenance and confidence as independent dimensions.
- `TaxInterviewProgress` reports completed sections, never a false fixed
  percentage.
- `TaxInterviewResult` reports facts, required/recommended omissions,
  calculability and one `TaxNextAction`.

Supported input primitives are yes/no, single choice, multiple choice, money,
integer, date, text, country, document and confirmation. The MVP uses only the
types required by its current questions.

## Branching and cleanup

Visibility is recomputed after every changed answer. Answers to newly hidden
questions are removed immediately. For example, changing employment from yes
to no removes gross income, withholding and Social Security answers. Changing
a couple to single removes the joint-taxation preference. This prevents stale
facts from silently participating in a calculation.

## Existing data and provenance

Known `FiscalProfile` values pre-fill matching questions with `IMPORTED`
provenance. User changes become `USER_ENTERED`. The model also supports
`OFFICIAL`, `CALCULATED` and `INFERRED`; these labels do not imply confidence.
Confidence is separately represented as `CONFIRMED`, `LIKELY`, `INCOMPLETE` or
`UNKNOWN`.

## Persistence and year isolation

Progress is atomically written to the private application directory after each
answer, using one versioned file per fiscal year. No authentication secret is
stored. A killed application resumes at the last question. Existing product
data is migrated by pre-filling rather than duplicating the fiscal profile.

## IRS integration and safety

The existing `TaxEngine` is unchanged. A calculation is created only for a
supported full-year, single-taxpayer employment case with the required numeric
inputs. Category B, pensions, foreign income and property income are retained
as facts but block approximation. This is a fail-closed boundary.

The estimate is labelled provisional and explained with income, withholding,
deductions considered and estimated result. Editing answers re-evaluates the
branch before the next calculation.

## e-Fatura and documents

The model can carry official provenance and expose e-Fatura enrichment without
treating unavailable aggregates as zero. Pending invoices are an advisory next
step and do not block the interview. `DocumentInput` establishes a local,
confirmation-first boundary; OCR and automatic extraction are deliberately out
of scope.

## Privacy and observability

Allowed events contain only lifecycle names: interview started, section
completed, interview completed, abandoned section and an error category.
Income, household answers, documents, identifiers and estimates are forbidden
event properties.

## Future foundations

`TaxEvent` and `TaxDeadline` exist as neutral types. No legal deadline is
populated without a validated source. Multi-year support reuses the same
question/rule graph with year-specific tax rules.
