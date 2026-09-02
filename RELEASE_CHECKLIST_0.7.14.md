# Release checklist — 0.7.14

- [x] Base contains PR #21 merge.
- [x] Version is `0.7.14+14` in app metadata and diagnostics.
- [x] Flutter static analysis and automated tests.
- [x] Connector and Android unit tests.
- [x] Debug APK build.
- [x] Production signing fails closed when credentials are absent.
- [x] `api.taxy.pt` HTTPS/health/authorization/no-store security smoke.
- [x] Production API allow-list rejects localhost, private IP and development URLs.
- [x] e-Fatura remains read-only; write-like route returns 404.
- [x] Secret and sensitive logging scans.
- [x] ARB key parity and runtime locale tests.
- [x] New surfaces at 320×640 and 200% text.
- [x] Home dashboard and calculation-method PT/EN localization.
- [ ] Complete remaining IRS wizard/result PT and EN localization.
- [ ] Global real-device Android smoke.
- [ ] TalkBack smoke with no critical unlabeled controls.
- [ ] Real-device light/dark and offline/recovery journey.
- [ ] Technical confirmation that the previously exposed Cloudflare key was revoked.
- [ ] Production signing material supplied through the release environment.

## Validation results

- Connector tests: 139 passed.
- Android native tests: PASS (`testDebugUnitTest`).
- Flutter tests: 515 passed.
- Flutter analyze: no issues.
- Debug APK: generated successfully.
- Release signing: fail-closed gate confirmed; no ad-hoc keystore created.
- Secret scan: PASS after excluding the deliberate synthetic redaction marker.
- Android/TalkBack: NOT_RUN — no device was listed by ADB.
- Cloudflare rotation: NOT_CONFIRMED.

## Known limitations

- Documents and obligations remain explicitly planned and are outside this RC scope.
- Official e-Fatura provisional benefit remains unavailable without an equivalent source.
- e-Fatura is read-only and network-only; invoices are not persisted for stale display.
