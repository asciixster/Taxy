# Document capture threat model

| Threat | Control | Residual risk |
|---|---|---|
| Lost/unlocked device | App-private encryption, Keystore key, 24-hour TTL, delete after confirmation | An unlocked device can display data through Taxy |
| Malicious app | Private storage, non-exported provider, scoped URI, `FLAG_SECURE` | Rooted/compromised devices are outside the guarantee |
| Shared storage | SAF stream copied into encrypted private storage; no broad permission | The selected source remains with its provider |
| Backup/cloud copy | `allowBackup=false` | OEM behaviour outside Android's contract |
| Logs/crash reports | Sanitized categories; no filename/path/OCR/amount logs | Platform failures remain generic |
| Orphans | Startup TTL plus cancel/delete/confirm cleanup | Encrypted data can remain until next startup after power loss |
| Screenshots/recent apps | `FLAG_SECURE` | The external camera app owns its capture UI |
| Memory | Bounded sequential pages, sampled bitmaps, recycled buffers | Plaintext briefly exists in process memory for OCR/review |
| Backend retention | No backend path; extraction is on-device | None for this flow |
| Path traversal | Random 32-hex IDs; original filenames never form paths | Implementation defects remain possible |
| MIME spoofing | MIME and magic-byte validation | Platform decoder vulnerabilities remain possible |
| Malformed/bomb input | 10 MB, 10 pages, 20k dimension ceiling, sampling and preview bound | Valid highly compressed content still consumes bounded memory |
| PDF active content | `PdfRenderer` renders pages; no JS, links, attachments or macros | Renderer remains trusted computing base |
| EXIF GPS | Image re-encoding; metadata not copied | Source still retains its metadata outside Taxy |
| Silent fiscal mutation | Candidate/evidence/TaxFact separation and explicit confirmation | Incorrect user confirmation remains possible and editable |

## Invariants

1. Raw or extracted candidates have zero calculation impact.
2. No real fiscal document is committed.
3. No document is transmitted to Taxy or third parties.
4. No original filename, URI, path or OCR text is persisted.
5. Confirmation deletes raw/preview; failure restores prior evidence and fails closed.
6. Unsupported documents cannot create supported fiscal facts.
