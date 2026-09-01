# Taxy 0.7.11 product audit

## Product definition

Taxy is a Portuguese personal tax assistant. Its current dependable core is an
IRS estimate based on user-entered data, plus an experimental, read-only e-Fatura
connection. It is not yet a complete fiscal account, document manager or deadline
service. Unknown data must remain unavailable; estimates must never look official.

## Surface map

| Area | Current purpose and data | State | Main issue / decision |
|---|---|---|---|
| Onboarding | Explains the IRS conversation; local state | BETA | Clear and short; disclaimer must remain visible in result context. |
| Home | Entry to a saved/new IRS simulation and experimental modules | BETA | Useful launcher, not yet a complete fiscal overview; avoid invented totals/deadlines. |
| Fiscal profile | Household/residence/year facts inside the IRS wizard | INCOMPLETE | Real inputs, but no independent reusable profile or global active-year model. |
| IRS | Rules repository + deterministic engine + manual inputs | BETA | Strongest module; supported scope and assumptions must remain explicit. |
| Income | Entered inside IRS flow | INCOMPLETE | No independent ledger/source attribution or import deduplication. |
| Expenses | Limited IRS inputs and e-Fatura document views | INCOMPLETE | No unified expense model; a document is not automatically a deduction. |
| e-Fatura | `Flutter -> api.taxy.pt`; real read-only session/invoices | EXPERIMENTAL | Pending documents work. Provisional benefit and sectors are not beta claims until an official semantically equivalent source exists. |
| Documents | e-Fatura invoice list only | PLANNED | Do not build a fictitious DMS. |
| Obligations | No individualized obligation engine | PLANNED | Model is documented; do not invent deadlines from incomplete profiles. |
| Settings | Locale and build diagnostics | BETA | Needs a user-facing privacy/help centre and formal feedback destination. |
| Validation lab | Internal tax verification | INTERNAL | Must not be presented as a normal consumer feature. |

## UX and safety findings

- Navigation is a shallow launcher/stack and is adequate for the current small
  surface; five empty bottom tabs would create dead ends.
- The IRS result has a calculation breakdown, warnings and supported-scope gates,
  but several production strings remain Portuguese-only. English external beta is
  therefore not ready.
- Home loading and module errors are isolated, but app-wide offline/freshness and
  error-taxonomy components are not yet unified.
- Local simulation data is real user-entered data; e-Fatura responses are real when
  connected. Tests and demos use synthetic fixtures.
- Experimental modules are correctly flagged/hidden by default. “Coming soon” cards
  are informational and must not imply working fiscal logic.
- No tax-engine changes are part of 0.7.11.

## Simplification decisions

Keep one Home entrypoint, one IRS conversation and one read-only e-Fatura module.
Hide or label incomplete modules. Do not add navigation destinations, deadlines,
income categories or deduction figures until backed by implementation and tests.

