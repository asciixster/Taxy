# External RC evidence — 0.7.15

## Real Android device

- Device class: Motorola Edge 50 Pro, Android 15 / API 35.
- Debug build `0.7.15 (15)` installed successfully.
- Cold and warm launch: PASS.
- Home, Fiscal Profile, IRS, Income, Expenses, e-Fatura, Settings, scenario
  comparison and saved estimates: PASS.
- PT → EN → Automatic and dark → system appearance: PASS without restart.
- English IRS result used locale-aware currency (`€45,195.35`).
- Network loss produced a scoped connection state while local IRS remained
  usable; recovery did not require an app restart.
- TalkBack traversal: PASS with no critical unnamed action. A discovered
  authentication-field label gap was fixed and covered by a widget test.
- The device's original accessibility-service configuration and app language /
  theme automatic preferences were restored after the smoke.

No AT write operation or live FactIntWS request was executed.

## API security smoke

On 2026-09-02, bounded unauthenticated requests confirmed valid HTTPS and host,
health `200`, `Cache-Control: no-store`, unauthorized and invalid-session `401`,
write-like route `404`, no wildcard CORS, and no sampled stack trace or secret.

## Release engineering

- `api.taxy.pt` is the only accepted production e-Fatura base URL.
- Production Android does not register the direct FactIntWS runtime bridge.
- Debug APK generation: PASS.
- Release AAB signing gate: BLOCKED_EXTERNAL, fail-closed because the four
  required private signing inputs were absent.
- Cloudflare key rotation: NOT_CONFIRMED. No exposed credential was reused.
- Secret scan: no private identity, certificate bundle, token or password was
  accepted as a tracked release input.

## Feature and build configuration inventory

| Setting | Debug default | Release default | Purpose | Status |
|---|---|---|---|---|
| `TAXY_EFATURA_EXPERIMENTAL` | false | false | Enables the experimental read-only surface | Active; enabled explicitly only for device smoke |
| `TAXY_API_BASE_URL` | `https://api.taxy.pt/` | `https://api.taxy.pt/` | Public e-Fatura API | Active; any other host/scheme/port fails closed |
| `TAXY_APP_VERSION` / `TAXY_BUILD_NUMBER` | 0.7.15 / 15 | 0.7.15 / 15 | Sanitized diagnostics | Active |
| `TAXY_GIT_SHA` / `TAXY_ENVIRONMENT` | unknown / local | supplied by release runner | Sanitized build provenance | Active; no secret content |

## Gate

The product-quality smoke is positive, but external RC publication remains
blocked by Cloudflare rotation evidence and production signing.
