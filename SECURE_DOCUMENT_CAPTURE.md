# Secure document capture

## Product boundary

Taxy 0.8.4 accepts a photo or user-selected PDF/JPG/PNG for three engine-supported facts only: annual employment income, IRS withholding, and Social Security contributions. Extraction is a candidate, never a fiscal fact.

`raw document → extracted candidate → user review → explicit confirmation → confirmed evidence → reconciliation → TaxFact → IRS engine`

Unsupported income documents are identified as not included and cannot produce engine values. Manual evidence remains available when capture or extraction fails.

## Device behaviour

- Camera uses the Android system intent and a narrowly scoped `FileProvider`; no persistent camera permission.
- File selection uses Android's Storage Access Framework; no broad storage permission.
- PDF/JPG/JPEG/PNG require valid magic bytes and consistent MIME.
- Input is limited to 10 MB and PDFs to 10 pages.
- The bundled ML Kit Latin model performs OCR locally and offline. Nothing is sent to `api.taxy.pt` or another processor.
- Images are re-encoded before storage, removing EXIF including location.
- Temporary raw and preview material uses AES-256-GCM with a non-exportable Android Keystore key.
- The flow enables `FLAG_SECURE`.
- Cancel, delete and successful confirmation remove raw/preview files. Startup applies a 24-hour TTL.
- Android backup remains disabled.

## Persistence and privacy

The recoverable review record contains only a random internal ID, tax year, media type, page count, timestamp, state, normalized candidates, confidence and stable warning categories. It contains no original filename, URI/path, OCR text, raw candidate, bytes or EXIF.

Confirmed `GuidedDocumentEvidence` remains backward-compatible with 0.8.2. Document content, type, amounts, year, names, filenames, paths, OCR and hashes are never logged or sent as analytics properties.

## Limits

- Capture is Android-only; manual evidence works elsewhere.
- Latin OCR is assistive and always reviewed.
- No OCR/storage backend was added.
- Unsupported fiscal scenarios remain visibly excluded.

## Dependency audit

`com.google.mlkit:text-recognition:16.0.1` is the Google-maintained, documented bundled Latin artifact. It adds no Android permission and avoids the first-use model download and network dependency of the Play Services variant. The documented binary impact is about 4 MB per script architecture. It is distributed under Google's SDK terms rather than introduced as an arbitrary third-party OCR service; release/legal policy must continue to track those terms and dependency updates. No document content is supplied to a training or retention service by this implementation.
