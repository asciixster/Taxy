# Release build report — 0.9.0-beta.1

## Verified

- Application ID: `pt.taxy.app`
- Version name: `0.9.0-beta.1`
- Version code: `22`
- Debug universal APK: generated successfully
- Debug APK size: 197,152,320 bytes (about 188 MiB)
- Android native unit tests: PASS
- Flutter analyzer: PASS
- Flutter tests: 611/611 PASS
- AT connector tests: 139 PASS, 4 credential-dependent skips, 0 FAIL
- Official comparison: 13/13 compared fields, zero-cent tolerance, PASS
- Clean detached checkout: dependency restore, analyze, 611 tests, debug APK
  build and Android native tests all PASS

## Distribution gate

Neither the signed release AAB nor a release APK was generated because none of
the four external `TAXY_ANDROID_*` signing variables is provisioned in this
environment. Both Gradle release tasks fail closed before compilation and do
not emit an unsigned intermediary or substitute a debug key. This is an
operational release gate, not an application-code failure. Provisioning is
documented in `SIGNING_SETUP_REQUIRED.md`.

The distribution command explicitly enables the read-only e-Fatura product
module. Its default remains fail-closed/hidden in ordinary builds, and the
enabled UI still constructs only the `api.taxy.pt` backend bridge.

## Artifact inspection

The generated debug APK declares API 24 minimum, API 35 target,
`android.permission.INTERNET` and `android.permission.ACCESS_NETWORK_STATE`.
It declares no camera or broad-storage permission, has `allowBackup=false`,
explicitly disables cleartext traffic, and its document FileProvider is
non-exported. No private-key container, raw PDF,
known token form, Cloudflare key material or obsolete backend hostname was
found in the artifact.

FactIntWS protocol symbols remain compiled in the Android layer because the
DM3IRS client shares its public security framing and the internal native
e-Fatura bridge remains covered by tests. The user-facing e-Fatura route is
still exclusively the `api.taxy.pt` backend bridge; there is no normal-flow
direct fallback.

The repository, generated APK and build intermediates contain no private-key
container, raw fiscal PDF, live token form or Cloudflare credential pattern.
The same Cloudflare-secret pattern was absent from the latest 100 commits. Key
rotation remains an external confirmation because local absence cannot prove
provider-side revocation.
