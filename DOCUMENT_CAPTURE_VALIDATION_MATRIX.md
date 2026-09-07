# Taxy 0.8.4 document capture validation matrix

Scope: synthetic inputs only. `EXTRACTED_CANDIDATE` has no fiscal effect until
explicit confirmation. Raw documents remain on-device, app-private and
encrypted, and are deleted after confirmation or cancellation.

| Scenario | Expected | Automated test | Real device needed | Status |
|---|---|---|---|---|
| JPG/PDF/PNG signature and MIME agree | Accepted | Native boundary assertions + CI APK build | Yes, final picker smoke | PASS offline |
| Extension/MIME disagrees with magic bytes | Fail closed (`MIME_MISMATCH`) | Native boundary assertion | No | PASS |
| Unknown or malformed binary/PDF | Sanitized failure; manual fallback | Extractor/native boundary assertions | Yes, final malformed-picker smoke | PASS offline |
| File above 10 MiB | Rejected while streaming; no OCR | Native limit assertion | No | PASS |
| PDF above 10 pages | Rejected before OCR loop | Native limit assertion | No | PASS |
| Malicious filename/path | External name never persisted or used as path | `secure_document_capture_test.dart` | No | PASS |
| Image with EXIF GPS | Bitmap is re-encoded; EXIF is not copied | Native source assertion | Yes, artifact verification | PASS offline |
| Capture interrupted/cancelled | Camera cache file deleted | Native lifecycle assertion | Yes, final camera smoke | PASS offline |
| Processing failure | Raw/preview candidates deleted; safe error | Native lifecycle audit | Yes, final failure smoke | PASS offline |
| Activity destroyed during camera capture | Pending camera cache deleted in `detach` | Native lifecycle assertion | No | PASS |
| App restart with interrupted metadata | Staging file discarded; unconfirmed state recoverable/clearable, never auto-confirmed | Repository test | No | PASS |
| Temporary item older than 24 hours | Raw native files and unconfirmed metadata removed | Repository test + native source audit | No | PASS |
| Candidate extracted | No evidence or TaxFact is created | Repository boundary test | No | PASS |
| Partial confirmation | Only selected fields become confirmed evidence | Widget test | No | PASS |
| User correction | Corrected cents, not OCR candidate, become evidence | Widget test | No | PASS |
| Document year differs from active year | Confirmation disabled; no 2026 evidence | Widget test | No | PASS |
| Raw deletion fails during confirmation | Evidence transaction rolled back | Widget test | No | PASS |
| Manual/document values differ | `DATA_CONFLICT`; no silent overwrite; Review/NextAction affected | Fiscal orchestration regression tests | No | PASS |
| Matching manual/document values | No false conflict | Fiscal orchestration regression tests | No | PASS |
| Confirm succeeds | Encrypted raw and preview deleted; candidate metadata removed | Widget test + native delete path | Yes, physical verification | PASS offline |
| User deletes/cancels review | Raw and candidate metadata deleted; no evidence | Widget test | Yes, physical verification | PASS offline |
| Evidence removed later | Imported matching TaxFact removed; manual value preserved | `document_evidence_test.dart` | No | PASS |
| Persisted metadata privacy | No filename, path, OCR text, raw candidate, bytes, hash, employer, NIF or GPS | Serialization test + static scan | No | PASS |
| Small screen, 200% text, dark mode and semantics | No overflow; controls remain labelled and reachable | Widget test | Yes, TalkBack confirmation | PASS offline |
| Raw document network egress | No upload/client call exists in capture path | Diff/network audit | No | PASS |
| Real camera/SAF/ML Kit integration | Capture/select → extraction → review → confirm | Checklist below | Yes | PENDING DEVICE |

## Lifecycle matrix

| Exit path | Raw state |
|---|---|
| Successful processing, review pending | Encrypted app-private raw retained for preview, maximum 24 h |
| Confirm | Raw + preview deleted, then candidate metadata removed |
| Delete/cancel review | Raw + preview deleted, then candidate metadata removed |
| Camera cancellation | Unencrypted app-private camera cache deleted immediately |
| Processing exception or validation failure | Raw + preview + camera cache deleted |
| Activity detach/interruption | Pending camera cache deleted immediately |
| Process killed after successful processing | Encrypted raw recoverable only until review/TTL; never auto-confirmed |
| Startup after TTL | Expired raw/preview and unconfirmed metadata removed |
| Logout/reset | All temporary raw/preview and unconfirmed candidates cleared |

The only remaining release gate is the synthetic-document physical smoke in
`REAL_DEVICE_DOCUMENT_CAPTURE_SMOKE.md`.
