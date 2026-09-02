# Beta readiness — 0.7.14

This matrix distinguishes automated evidence from real-device evidence. A feature
is not promoted merely because its code builds.

| Feature | Status | Offline | PT | EN | Dark | Responsive | Accessibility | Real-device | Notes |
|---|---|---|---|---|---|---|---|---|---|
| Home | BETA | PASS | BETA | BETA | BETA | PASS | BETA | BLOCKED | Dashboard localized; IRS wizard strings and device journey remain. |
| Fiscal profile/checklist | BETA | PASS | PASS | PASS | PASS | PASS | BETA | BLOCKED | Six objective checklist items. |
| IRS estimate | BETA | PASS | BLOCKED | BLOCKED | BETA | BETA | BETA | BLOCKED | Fiscal engine unchanged; detailed wizard/result copy remains. |
| Scenario comparison | BETA | PASS | BETA | BETA | PASS | PASS | BETA | BLOCKED | Explicit overlays only. |
| Saved estimates | BETA | PASS | PASS | PASS | PASS | PASS | BETA | BLOCKED | Local, versioned and never silently recalculated. |
| Income | BETA | PASS | PASS | PASS | PASS | PASS | BETA | BLOCKED | Provenance and cautious duplicate status. |
| Expenses | BETA | PASS | PASS | PASS | PASS | PASS | BETA | BLOCKED | Local supporting evidence only. |
| e-Fatura explorer | BETA | BLOCKED | PASS | PASS | PASS | PASS | BETA | BLOCKED | Network-only, read-only, `api.taxy.pt`; no stale payload. |
| Settings/privacy/diagnostics | BETA | PASS | PASS | PASS | PASS | PASS | BETA | BLOCKED | Diagnostics contain no fiscal data. |
| Documents | PLANNED | — | — | — | — | — | — | — | Outside beta scope. |
| Obligations | PLANNED | — | — | — | — | — | — | — | Outside beta scope. |

## Automated evidence

- Connector: 139/139 tests passed.
- Flutter: 515/515 tests passed; `flutter analyze` has no issues.
- Android native unit tests: PASS.
- Compact layout: Home, Fiscal Profile, Income, Expenses, e-Fatura, saved
  estimates and Settings render at 320×640 with 200% text without overflow.
- Debug APK: built successfully.
- Release build: stopped at the intentional production-signing gate; it did not
  fall back to debug signing.
- Public e-Fatura path: `api.taxy.pt` only. Android production entrypoint no
  longer registers the direct FactIntWS bridge.
- Android device and TalkBack: NOT_RUN because ADB exposed no attached device.
- Cloudflare key rotation: NOT_CONFIRMED; no rotation evidence was available and
  no previously exposed credential was used.

## External RC decision

`PRODUCT_READY_FOR_EXTERNAL_RC = NO` until the blocked PT/EN legacy audit,
real-device Android/TalkBack journey, and Cloudflare key rotation evidence close.
