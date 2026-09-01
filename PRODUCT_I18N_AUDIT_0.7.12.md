# PT/EN audit — 0.7.12

The new fiscal profile, active-year, income, expense, appearance, privacy,
diagnostic and IRS estimate-basis surfaces are fully represented in all three ARB
catalogues (`en`, `pt`, `pt_PT`). Localization parity tests remain mandatory.

The legacy monolithic IRS wizard, result alternatives, comparison/opportunity
screens and parts of Home still contain Portuguese user-facing literals. They are
functionally preserved to avoid a risky engine-adjacent rewrite in this pass.
Therefore `PT_APP_WIDE` and `EN_APP_WIDE` cannot yet be marked PASS. The next
milestone must move those literals to ARB without changing fiscal logic or test
expectations.

