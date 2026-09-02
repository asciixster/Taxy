# Release configuration and feature flags — 0.7.14

| Name | Debug default | Release default | Purpose | Status |
|---|---:|---:|---|---|
| `TAXY_EFATURA_EXPERIMENTAL` | false | false | Shows the experimental read-only e-Fatura module | ACTIVE |
| `TAXY_API_BASE_URL` | `https://api.taxy.pt/` | `https://api.taxy.pt/` | Public API origin; runtime validation rejects every other host | ACTIVE |
| `TAXY_APP_VERSION` | 0.7.14 | 0.7.14 | Build diagnostics override | ACTIVE |
| `TAXY_BUILD_NUMBER` | 14 | 14 | Android/build diagnostics override | ACTIVE |
| `TAXY_GIT_SHA` | development | supplied by release | Sanitized revision diagnostics | ACTIVE |
| `TAXY_BUILD_ENVIRONMENT` | production | production | Controls internal-beta build information | ACTIVE |

Release has no localhost, private address, development endpoint or direct FactIntWS
fallback. Production signing is accepted only from environment variables and fails
closed; no signing secret or `--dart-define` secret is committed.

The Android activity registers only local data-path access and e-Fatura screen
protection. It does not register the historical direct FactIntWS runtime bridge;
normal and release Flutter traffic uses only `https://api.taxy.pt/`.
