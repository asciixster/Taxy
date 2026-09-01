# Taxy 0.7.10 internal beta checklist

## Build

- [ ] Build from `internal-beta-rollout-0.7.10` with a recorded Git SHA.
- [ ] `TAXY_EFATURA_EXPERIMENTAL=true` only for the internal artifact.
- [ ] Environment is `internal-beta`; API host is `api.taxy.pt`.
- [ ] APK contains no PFX, private key, password, API token, Cloudflare key, old-backend fallback, or raw fiscal payload.

## Device acceptance

- [ ] Clean install and launch.
- [ ] PT and EN reviewed; light/dark and large text show no overflow.
- [ ] Login returns real pending count and invoice list.
- [ ] Sectors and provisional benefit show **Unavailable**, never a fabricated zero.
- [ ] Logout clears token, overview, invoices, and transient state.
- [ ] Relogin creates a fresh session without stale data.
- [ ] Valid-session cold start verifies the token before showing connected.
- [ ] Expired and invalid tokens fail closed and require authentication.
- [ ] Offline request fails without crash or endless loading; manual retry recovers.
- [ ] 502/503/504 and timeout use human copy and manual retry only.
- [ ] Double taps do not create duplicate login, refresh, or invoice requests.
- [ ] Background/foreground and process kill do not restore transient fiscal data.
- [ ] `FLAG_SECURE` blocks screenshots and recent-app preview for e-Fatura.
- [ ] No write action exists or is executed.

## Verification

- [ ] Public API health is 200 before and after E2E.
- [ ] Backend/contract, connector, Android native, Flutter analyze/test, and Gradle checks pass.
- [ ] Final APK installs and repeats login, invoices, and logout.
- [ ] Sensitive-log and persistent-cache audits are clean.

## Build command

Use a short SHA from the current commit:

```text
flutter build apk --release --build-name=0.7.10 --build-number=10 --dart-define=TAXY_EFATURA_EXPERIMENTAL=true --dart-define=TAXY_API_BASE_URL=https://api.taxy.pt/ --dart-define=TAXY_BUILD_ENVIRONMENT=internal-beta --dart-define=TAXY_APP_VERSION=0.7.10 --dart-define=TAXY_BUILD_NUMBER=10 --dart-define=TAXY_GIT_SHA=<short-sha>
```

This release-like internal APK is debug-signed by the current project configuration. It is not an externally distributable production-signed artifact.
