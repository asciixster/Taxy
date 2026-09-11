# IRS APK static inventory

## Artefact

- package: `pt.gov.portaldasfinancas.irs`
- application namespace/main activity: `pt.at.irs` / `pt.at.irs.MainActivity`
- version: `10.0.0` (`versionCode 89`), label `IRS 2025`
- SHA-256: `f6eb07e823d7243deb4de83fe5e00e478d759714f1c55737ddf15e5344308e52`
- size: 82,198,336 bytes
- base/split: standalone base APK
- minSdk / targetSdk / compileSdk: 24 / 36 / 36
- DEX: one (`classes.dex`); Flutter AOT application snapshot
- ABIs: arm64-v8a, armeabi-v7a, x86_64
- notable native libraries: Flutter application/runtime and PDFium

The APK remains in a private analysis directory outside the repository. Neither the APK nor extracted files appear in Git.

## Manifest and network

Permissions are limited to Internet/network state and biometric/fingerprint APIs. Backup is disabled. No broad storage permission or `MANAGE_EXTERNAL_STORAGE` is declared. The file-sharing provider is not exported. No custom Android network-security configuration was identified; the Dart client builds its own `SecurityContext`, loads certificate-chain/private-key bytes and pins the Portal public certificate.

## Cryptographic assets (classification only)

| Asset class | Count | Handling |
|---|---:|---|
| PKCS#12 containers | 2 | `PRIVATE_IDENTITY_CONTAINER`; listed/hashed only, never opened or unlocked |
| Portal trust certificate | 1 | `PUBLIC_CERT`; subject/issuer and public fingerprint inspected |
| AT request-encryption public keys | 2 | `PUBLIC_KEY`; public SPKI only |

The production request-encryption key is RSA-4096 and its public SPKI SHA-256 is `b19983ae125123d3b82afb0845018c2fe4fc8f9556686142b1e371a031a54968`. This matches the already-known Taxy AT encryption recipient key. It says nothing about client authorization.

The APK signing certificate is a public signing identity, not the TLS client identity. No password, private key, PKCS#12 content or private alias was inspected.

## Static analysis method

Manifest/resource inventory, ZIP asset inspection, sanitized fixture-shape analysis and static Dart AOT disassembly were used. The app was never installed or executed. Embedded fixtures were used only to enumerate element names/types; values and identifying filenames were not retained.

Sanitized response-shape counts are: 24 payload fields for `infoUtilizador` (excluding root/status), 89 distinct payload fields for `infoAgregado`, four catalog families in the active app, 16 receipt payload fields, one PDF payload field and one optional delivery-reference field.
