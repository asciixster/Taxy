# DM3IRS V1 security review

Status: **PASS for the implemented boundary; real-device product smoke pending.**

## Identity and credentials

- The integration uses only an identity explicitly selected through Android KeyChain; no IRS application identity, private key, PFX, password, or certificate material is bundled.
- Portal credentials reuse the existing encrypted application-private store. Password copies and decoded response buffers are cleared after use.
- Error messages are fixed and sanitized. No response, credential, identifier, amount, OCR text, XML, or PDF content is logged or sent to analytics.

## Network boundary

- The production transport is reachable only through the three-value Dm3IrsReadOperation enum: delivery check, receipt metadata, and declaration retrieval.
- Every request is checked against the explicit read allowlist.
- submeterDeclaracaoMobileRequest exists only in the prohibited-operation regression assertion; there is no serializer, enum value, bridge method, or transport route for it.
- Redirects are disabled, responses are size-bounded, requests use no-store, and XML parsing disables DTDs, external entities, and XInclude.

## Document and parser boundary

- The received declaration is decoded and rendered through an anonymous in-memory file descriptor on Android 11 or newer; no filesystem path is created.
- The raw SOAP byte array and decoded PDF byte array are cleared after parsing.
- The parser requires the validated 2024 template, 17-page structure, exact annex routing, stable anchors, and field-code/cell ownership.
- Missing, duplicated, ambiguous, high-confidence-only, or unknown template input fails closed and produces no suggestions.
- Field 603 is hard-gated as RUNTIME_VALIDATION_REQUIRED_FIELD_603 and is never exposed by V1.

## Persistence and product boundary

- Historical evidence is separate from TaxFact and remains session-only.
- Nothing is selected by default. Only an explicit user confirmation persists the minimal normalized field, source year, target year, confirmation time, exact confidence, provenance, and template fingerprint.
- Raw PDF, XML, declaration/receipt identifiers, NIF, name, address, and OCR text are never persisted.
- Source and target years must match the confirmation being applied; historical evidence cannot silently affect another tax year.
- Disconnect clears stored Portal credentials. The sensitive screen uses FLAG_SECURE.

## Verification

- Flutter analysis and tests: pass.
- Android native tests: pass.
- AT connector tests: pass.
- Structural parser tests: pass.
- Debug APK build: pass.
- Repository scan: no private keys, PFX, PDF/APK fixtures, tokens, or hardcoded taxpayer credentials in the V1 change.
- Category B engine and tax-rule assets: unchanged.

The remaining release gate is the prescribed Android real-device smoke. It must inspect the V1 UI without confirming personal values, then disconnect and verify that no raw document or unconfirmed fiscal data remains.
