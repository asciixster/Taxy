# Release dependency audit — 0.9.0-beta.1

Status: PASS.

This release branch introduces no dependency or lockfile change relative to
`main`. It therefore inherits the dependency review completed for secure
document capture and DM3IRS V1 without adding a new runtime, permission or
binary-size source.

The principal runtime dependencies remain Flutter, Riverpod,
`flutter_secure_storage`, AndroidX, ML Kit on-device text recognition and the
JNI support packages used by the native document pipeline. The merged Android
manifest confirms that these dependencies add network-state access but no
camera, broad-storage or backup permission. The approximately 188 MiB debug
universal APK size is consistent with the already accepted OCR/native-library
impact; effective store delivery is expected to benefit from AAB ABI splitting.

- ML Kit text recognition `16.0.1` is used directly by document capture and its
  local Maven metadata declares the ML Kit Terms of Service.
- `flutter_secure_storage` `10.0.0` is used directly for protected credentials
  and declares BSD-3-Clause in the installed package.
- PDF rendering uses Android `PdfRenderer`; encryption uses Android Keystore
  and platform JCA primitives. No separate PDF or cryptography library was
  added by this release.
- No dependency in the checked lock/build metadata carries a local vulnerability
  advisory, and no unused new heavy dependency was found. This is a local
  package audit, not a claim about future advisories.

Available incompatible package upgrades were reported by the package manager
but are intentionally deferred: changing them would expand release scope and
invalidate the already green regression baseline.
