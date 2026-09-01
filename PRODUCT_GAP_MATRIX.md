# Product gap matrix — 0.7.12

Statuses describe closure evidence, not marketing readiness.

| Capability | Product status | Gap | Evidence / remaining work |
|---|---|---|---|
| Global fiscal profile | BETA | CLOSED | One persisted profile represents active year, residence, household and work contexts; unknowns stay null. IRS saves synchronize facts. |
| Active tax year | BETA | CLOSED | Selects initial rules and all local income/expense totals. Historical simulations retain their explicit year. |
| IRS core estimate | BETA | PARTIAL | Deterministic supported scope unchanged; profile sync added. Remaining hardcoded copy prevents app-wide EN closure. |
| IRS explainability | BETA | PARTIAL | Existing breakdown/trace preserved; formal assumptions and missing-input UI need a dedicated pass. |
| Income ledger | BETA | CLOSED | Local add/list/remove, integer cents, year, provenance/status and cautious duplicate flagging. |
| Expense ledger | BETA | CLOSED | Local add/list/remove, provenance, optional VAT/date and warning that entries are not automatic deductions. |
| e-Fatura pending invoices | EXPERIMENTAL | CLOSED | Read-only public API path preserved; no protocol or write change. |
| e-Fatura provisional benefit | INCOMPLETE | DEFERRED | No official semantically equivalent source; remains unavailable for external scope. |
| e-Fatura sectors | INCOMPLETE | DEFERRED | Same provenance blocker; never reconstructed from document sums. |
| Settings appearance/language | BETA | CLOSED | Persisted automatic/PT/EN language and system/light/dark theme switch immediately. |
| Privacy centre | BETA | CLOSED | Plain-language local/backend/read-only/session boundary in Settings. |
| Sanitized diagnostics/feedback | BETA | CLOSED | Version/build/revision/environment/API only; feedback template has no fiscal payload. |
| Shared error taxonomy | BETA | PARTIAL | Stable global taxonomy exists; legacy IRS UI still needs full mapping. |
| Offline semantics | BETA | PARTIAL | Local profile/ledgers/IRS work offline; e-Fatura has retry/errors. Freshness is not app-wide. |
| PT/EN app-wide | INCOMPLETE | OPEN | New surfaces are localized, but legacy IRS/Home strings remain hardcoded. |
| Accessibility/responsiveness | BETA | PARTIAL | New screens have 320×640/dark/200% test; real TalkBack/global pass outstanding. |
| Documents | PLANNED | DEFERRED | No safe useful minimum beyond invoice view; no uploads added. |
| Obligations/deadlines | PLANNED | DEFERRED | Contract documented; no unsourced deadlines produced. |
| Production signing | BETA | PARTIAL | Fail-closed configuration exists; release credentials/artifact belong to 0.7.13. |
| External release candidate | INCOMPLETE | OPEN | Cloudflare rotation proof, device smoke, full i18n/accessibility and signed artifact remain. |

## Counts

- CLOSED: 8
- PARTIAL: 6
- OPEN: 2
- DEFERRED: 4

