# Beta release checklist

## Scope and fiscal safety

- [x] Version and build number fixed once.
- [x] Supported and unsupported scenarios documented.
- [x] Category B calculation remains disabled.
- [x] Unsupported income hides a complete estimate.
- [x] All official/reference fiscal fixtures pass with zero-cent tolerance.
- [x] AT write surface is absent.

## Product

- [ ] Onboarding and first manual path smoke.
- [ ] Guided interview and resume smoke.
- [ ] Supported estimate and explanation smoke.
- [ ] Unsupported Category B/foreign-income smoke.
- [ ] Document capture, review and cleanup smoke.
- [ ] Historical 2024 confirm-only flow smoke.
- [ ] e-Fatura read-only unavailable/login/logout smoke when safe.
- [ ] Dark mode and 200% text smoke.

## Engineering

- [x] `flutter analyze` passes.
- [x] Flutter tests pass.
- [x] AT connector offline tests pass.
- [x] Android native tests pass.
- [x] PT/PT-PT/EN localization parity passes.
- [ ] Debug/release-candidate APK builds and installs.
- [ ] Signed release AAB builds with external signing secrets.
- [ ] Release artifact signature is verified privately.

## Privacy and security

- [x] Repository and debug artifact contain no secrets, private keys or real PII.
- [x] No raw fiscal PDF/document persists after the flow.
- [x] Logs and crash output contain no sensitive fiscal data.
- [x] Logout/session expiry behavior passes in automated regression tests.
- [ ] Previously exposed Cloudflare global key rotation confirmed externally.

## Delivery

- [ ] Physical smoke passes on Motorola edge 50 pro / Android 15 / API 35.
- [x] CI is green on the release PR.
- [x] Known limitations accompany the beta.
- [x] PR remains open for explicit human merge approval.
