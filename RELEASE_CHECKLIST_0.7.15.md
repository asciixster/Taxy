# Release checklist — 0.7.15

- [x] Base contains merged PR #22.
- [x] Version is `0.7.15+15`; Android reports version code 15.
- [x] PT-PT and English key parity, copy audit and runtime switch.
- [x] Locale-aware currency, dates and plurals across the product UI.
- [x] App-wide dark-mode and responsive regression coverage.
- [x] 320×640 at 200% text on critical surfaces.
- [x] Real-device cold/warm launch and principal navigation.
- [x] Real-device PT/EN, dark, offline and network recovery smoke.
- [x] TalkBack smoke with no critical unnamed action.
- [x] e-Fatura remains read-only and `api.taxy.pt` only.
- [x] Shared error taxonomy and partial-success behavior.
- [x] API HTTPS, authorization, no-store, CORS and write-route smoke.
- [x] Connector, Android, Flutter and static-analysis gates.
- [x] Debug APK built and installed on Android 15.
- [x] Release signing fails closed instead of using debug signing.
- [x] Secret and sensitive-logging scans.
- [ ] Technical evidence that the previously exposed Cloudflare key is revoked.
- [ ] Production signing material supplied through the private release runner.

## External blockers

Cloudflare dashboard/API authorization was not available without reusing the
exposed credential, which is prohibited. Production signing variables were
also absent. The release build correctly stopped at that gate; no keystore was
created or committed.

## Validation results

- Connector tests: 139 passed.
- Android native tests: PASS (`testDebugUnitTest`).
- Flutter tests: 518 passed.
- Flutter analyze: no issues.
- Debug APK: built and installed successfully.
- Release AAB: stopped at the intentional production-signing gate.
- Secret scan and sensitive-logging checks: PASS.

## Decision

`PRODUCT_READY_FOR_EXTERNAL_RC = NO` until both external checklist items above
are confirmed. The application-quality work itself is mergeable.
