# PR #28 offline scope review

Base: `origin/main` at the Taxy 0.8.3 merge. Reviewed head:
`9c6c1dddd253d644f938339142f23c695e6af458`.

| Area | Changes | Scope assessment |
|---|---|---|
| Capture | Android camera intent, SAF picker, FileProvider | IN SCOPE |
| Storage | Random IDs, app-private encrypted raw/preview, minimal recoverable metadata | IN SCOPE |
| Extraction | Bundled on-device Latin OCR; narrow employment/withholding/Social Security/year parser | IN SCOPE |
| Review | Preview, editable/partial selection, explicit confirmation, failure/manual fallback | IN SCOPE |
| Reconciliation | Reuses `GuidedDocumentEvidence`; candidate has no TaxFact effect; conflicts preserved | IN SCOPE |
| Privacy | Local-processing copy, EXIF stripping, no raw persistence after confirmation | IN SCOPE |
| Security | AES-256-GCM/Keystore, validation limits, FLAG_SECURE, backup disabled, lifecycle cleanup | IN SCOPE |
| Localization | PT, PT-PT and EN document flow strings | IN SCOPE |
| Documentation | Architecture, lifecycle, threat model, validation and device smoke | IN SCOPE |
| Tests | Extraction, boundaries, lifecycle, year, partial confirmation, rollback, privacy, accessibility | IN SCOPE |
| Build/dependencies | ML Kit bundled OCR, AndroidX FileProvider, Android compile/test CI and APK comparison | IN SCOPE |

No IRS formula, e-Fatura protocol/backend, AT write operation or production API
architecture changed. The only offline defect found was orphan camera-cache
cleanup on Activity detach; it now deletes immediately and has a regression
assertion. Interrupted metadata staging is also discarded fail-closed.

`SCOPE_REVIEW = PASS`

`MERGE_GATE = MERGE_RECOMMENDED_AFTER_DEVICE_SMOKE`
