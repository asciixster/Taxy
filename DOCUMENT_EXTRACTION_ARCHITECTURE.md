# Document extraction architecture

## Components

- `SecureDocumentCaptureBridge`: Android intents, validation, local OCR, Keystore encryption, preview and lifecycle.
- `TaxDocumentCaptureGateway`: Flutter/native boundary.
- `CapturedTaxDocument`: temporary, year-scoped metadata.
- `TaxDocumentExtractor`: provider-independent extraction contract.
- `PortugueseEmploymentDocumentExtractor`: narrow 0.8.4 parser.
- `TaxDocumentExtraction`: type candidate, normalized fields, extraction confidence and machine warnings.
- `DocumentExtractionReviewScreen`: explicit and partial confirmation.
- Existing `GuidedDocumentEvidenceRepository` and `FiscalDataOrchestrator`: evidence persistence and conflict-safe reconciliation.

## State and field contract

The model supports `captured`, `processing`, `reviewRequired`, `confirmed`, `failed`, and `deleted`. Recoverable review state persists normalized candidates only. OCR text is transient and discarded before repository writes.

Supported candidates are `employmentGross`, `irsWithholding`, `socialSecurityContributions` (integer cents), and `taxYear`. Employer names are neither required nor persisted. Ambiguous values fail closed with low confidence and no selected normalized value.

## Confirmation

Low-confidence candidates require explicit review. A user may correct values or confirm a subset. Evidence is saved before raw deletion; if deletion fails, prior evidence is restored and review stays open. Only after the screen closes does the interview reconcile evidence. Different existing values become `DATA_CONFLICT`; equal values do not create false conflicts.

An extracted year different from the active year disables confirmation. All temporary and confirmed records remain year-scoped.

## Dependency decision

The bundled `com.google.mlkit:text-recognition:16.0.1` Latin model works offline and avoids upload. Google's documentation estimates about 4 MB per bundled script architecture. Android system intents cover camera and files, so no Flutter picker/camera package or additional runtime permission was introduced.
