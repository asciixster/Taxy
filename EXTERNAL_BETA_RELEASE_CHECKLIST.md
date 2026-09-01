# External beta release checklist

## Build and supply chain

- [ ] Production keystore provisioned outside Git
- [x] Release build cannot fall back to debug signing
- [ ] Signed AAB generated and signature fingerprint recorded privately
- [ ] AAB/APK archive secret scan passes
- [ ] Version, build, Git SHA and environment recorded
- [ ] Exposed Cloudflare credential rotation proven

## Product

- [x] Product, IRS and gap audits completed
- [ ] PT and EN app-wide string audits pass
- [ ] Fiscal profile has one source of truth and active year is coherent
- [ ] Estimate and missing-data wording verified on every result path
- [ ] e-Fatura unavailable/empty/error semantics verified
- [ ] Privacy/help and sanitized feedback route complete

## Security and operations

- [x] Android backup disabled; only Internet permission requested
- [x] Normal backend host fixed to `api.taxy.pt`
- [x] e-Fatura is read-only and secrets are absent from Git
- [ ] Secure-storage/logout/offline/recovery device checks pass
- [ ] Crash/error observability reviewed for PII

## Quality

- [ ] Backend/contract and connector suites pass
- [ ] Android native tests pass
- [ ] Flutter analyze and tests pass
- [ ] Gradle debug/release-signing gates pass
- [ ] 320 px, normal/large phone and 200% text checks pass
- [ ] Dark mode and screen-reader checks pass
- [ ] Clean-install global Android smoke passes

No external beta may ship while any security, signing, secret-rotation or global
smoke item is open.

