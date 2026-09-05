# Product gap matrix — 0.7.13

Statuses describe verified implementation evidence, not marketing readiness.

| Capability | Product status | Gap | Evidence / remaining work |
|---|---|---|---|
| Global fiscal profile and active year | BETA | CLOSED | One persisted profile; unknown values remain unknown; contextual checklist added. |
| Fiscal profile checklist | BETA | CLOSED | Objective essential-item count, field impact and contextual income CTA. |
| IRS core estimate | BETA | PARTIAL | Deterministic supported engine unchanged; remaining legacy copy is not fully localized. |
| IRS scenario comparison | BETA | CLOSED | Explicit overlays preserve base data; supported income, withholding and deduction changes only. |
| Saved IRS estimates | BETA | CLOSED | Versioned local-only snapshots; immutable stored result; delete and duplicate supported. |
| IRS explainability | BETA | PARTIAL | Inputs, deductions, withholding, assumptions and missing information shown; legacy sections remain inconsistent. |
| Income ledger | BETA | CLOSED | Local CRUD, source filter, provenance/status and cautious duplicate flagging. |
| Expense ledger | BETA | CLOSED | Local CRUD, provenance and no automatic fiscal merging. |
| e-Fatura invoices | EXPERIMENTAL | CLOSED | Read-only api.taxy.pt flow with local search, date/value filters, sorting and monthly document totals. |
| e-Fatura provisional benefit | INCOMPLETE | DEFERRED | No semantically equivalent official source; remains unavailable. |
| Settings, privacy and diagnostics | BETA | CLOSED | Language/theme, snapshot disclosure and sanitized year/engine/API diagnostics. |
| Shared error taxonomy | BETA | PARTIAL | Stable contract and reusable AppErrorState exist; all legacy IRS branches are not migrated. |
| Offline semantics | BETA | PARTIAL | Local profile, ledgers and snapshots work offline; e-Fatura fails explicitly. No app-wide connectivity smoke. |
| PT/EN app-wide | INCOMPLETE | OPEN | New 0.7.13 surfaces are localized; legacy IRS strings remain hardcoded. |
| Accessibility/responsiveness/dark mode | BETA | PARTIAL | New surfaces covered at 320×640, dark and 200% text; real TalkBack/global pass outstanding. |
| Android real-device journey | INCOMPLETE | OPEN | No ADB device was attached during this pass. |
| Documents | PLANNED | DEFERRED | No sensitive upload/storage introduced. |
| Obligations/deadlines | PLANNED | DEFERRED | No unsourced deadlines introduced. |
| Production signing | BETA | PARTIAL | Fail-closed; signed distribution belongs to release engineering. |
| External release candidate | INCOMPLETE | OPEN | Requires global localization/accessibility/device smoke and Cloudflare rotation evidence. |

## Counts

- CLOSED: 9
- PARTIAL: 6
- OPEN: 3
- DEFERRED: 3
# 0.8.0 guided tax experience

The product now includes a reusable, year-scoped guided interview with
conditional branching, normalized facts, provenance, deterministic dependency
cleanup, local resume and fail-closed IRS integration. See
`TAXFIX_TAXY_PRODUCT_GAP.md` for the public-product comparison and
`GUIDED_TAX_INTERVIEW_ARCHITECTURE.md` for implementation boundaries.
