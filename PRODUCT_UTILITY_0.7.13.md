# Product utility and quality evidence — 0.7.13

This pass adds four user-facing foundations without changing tax rules:

1. Scenario overrides apply only supported hypothetical inputs over a base simulation.
2. e-Fatura invoice exploration is entirely local over already received read-only data.
3. The fiscal checklist counts known essentials and explains demonstrated impact.
4. Saved estimates are local, versioned, immutable historical results.

Invoice summaries are labelled document totals, never tax benefits. Filtering was
tested with 500 synthetic invoices. Snapshot schema v2 reads existing v1 product
state and never silently recalculates history after an engine change.

New surfaces are PT/EN localized, theme-aware and covered at 320×640 with 200%
text. Full legacy IRS localization and a real-device TalkBack journey remain open;
therefore this branch is useful beta progress but not an external RC gate closure.
