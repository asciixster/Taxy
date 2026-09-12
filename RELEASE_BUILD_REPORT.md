# Release build report — 0.9.0-beta.1

## Verified

- Application ID: `pt.taxy.app`
- Version name: `0.9.0-beta.1`
- Version code: `22`
- Debug universal APK: generated successfully
- Debug APK size: 197,152,320 bytes (about 188 MiB)
- Android native unit tests: PASS
- Flutter analyzer: PASS
- Flutter tests: 609/609 PASS
- AT connector tests: 139 PASS, 4 credential-dependent skips, 0 FAIL
- Official comparison: 13/13 compared fields, zero-cent tolerance, PASS

## Distribution gate

The signed release AAB was not generated because none of the four external
`TAXY_ANDROID_*` signing variables is provisioned in this environment. The
Gradle configuration failed closed before compilation and did not substitute a
debug key. This is an operational release gate, not an application-code
failure.

## Artifact inspection

The generated debug APK declares API 24 minimum, API 35 target,
`android.permission.INTERNET` and `android.permission.ACCESS_NETWORK_STATE`.
It declares no camera or broad-storage permission, has `allowBackup=false`, and
its document FileProvider is non-exported. No private-key container, raw PDF,
known token form, Cloudflare key material or obsolete backend hostname was
found in the artifact.

FactIntWS protocol symbols remain compiled in the Android layer because the
DM3IRS client shares its public security framing and the internal native
e-Fatura bridge remains covered by tests. The user-facing e-Fatura route is
still exclusively the `api.taxy.pt` backend bridge; there is no normal-flow
direct fallback.
