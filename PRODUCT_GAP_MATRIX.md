# Product gap matrix — 0.8.4

## Secure document capture and reviewed extraction

| Capability | Status | Notes |
|---|---|---|
| Android photo/file capture | BETA | Camera intent and SAF; no broad permission |
| Local extraction | BETA | Bundled Latin OCR; supported employment facts only |
| Reviewed confirmation | IMPLEMENTED | Partial correction/confirmation before evidence |
| Encrypted temporary lifecycle | IMPLEMENTED | Keystore AES-GCM, secure preview, TTL and delete-after-confirmation |
| Extraction/TaxFact separation | IMPLEMENTED | Candidate has zero engine impact |
| Universal fiscal OCR | OUT OF SCOPE | Unsupported documents remain excluded |

## Guided review and explainability

| Capability | Status | Notes |
|---|---|---|
| Guided Tax Review | IMPLEMENTED | Human-first synthesis available after interview and from Home |
| Completeness | IMPLEMENTED | Ready, needs review, incomplete, and unsupported are derived centrally |
| Conflict center | IMPLEMENTED | Choice is persisted with provenance; changed evidence reopens the conflict |
| Calculation inclusion | IMPLEMENTED | Included, missing, conflicted, unsupported, and irrelevant states |
| Estimate presentation policy | IMPLEMENTED | Complete, explicitly partial, or hidden; no widget-level formula |
| Explainability | IMPLEMENTED | Breakdown comes from actual `TaxResult` output |
| One next action | IMPLEMENTED | Deterministic priority; e-Fatura pending remains advisory/read-only |
| Complex-income calculation | PLANNED | Identified and visibly excluded, never approximated |
| IRS submission | OUT OF SCOPE | No filing or AT write operation |

## Taxy 0.8.1 — integrated fiscal companion

| Capability | Status | Notes |
|---|---|---|
| Cross-source orchestration | IMPLEMENTED | Year-scoped provenance, confidence and freshness |
| Existing-data prefill | IMPLEMENTED | Profile and normalized ledgers reduce repeated questions |
| Conflict detection/resolution | IMPLEMENTED | No silent source selection |
| Central missing-data model | IMPLEMENTED | Severity, reason and action shared with Home |
| Dirty-section review | IMPLEMENTED | Conflicts/new evidence target the affected section |
| e-Fatura next action | IMPLEMENTED | Pending count only; strictly read-only |
| Official benefit/sector totals | UNAVAILABLE | Never represented as zero |
| Complex-income calculation | PLANNED | Identified and fail-closed |
| Broad document ingestion/OCR | BETA | Narrow local extraction for three supported facts; universal OCR remains out of scope |

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
| Documents | BETA | PARTIAL | Secure local capture and reviewed extraction for supported employment evidence. |
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

## 0.8.2 evidence and complex-income boundary

| Area | Taxy 0.8.2 | Remaining gap |
|---|---|---|
| Document evidence | Explicit confirmation for three engine-supported annual values; local metadata only | Secure file capture and reviewed OCR |
| Complex income | Self-employment, pensions, foreign and rental income identified and visibly excluded | Validated calculation rules and detailed evidence models |
| Conflict safety | Document candidates use existing conflict resolution instead of overwriting | Richer field-specific comparison language |
| Privacy | No document file, path, filename or identifier persisted | Encrypted lifecycle required before raw capture |
