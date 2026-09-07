# Taxy 0.8.4 dependency audit

Audit date: 2026-09-05. The PR adds two direct Android dependencies and no
Flutter or backend package dependency.

| Package | Version | License/terms | Maintenance | Permissions | Expected size impact | Security/privacy | Necessity |
|---|---:|---|---|---|---|---|---|
| `com.google.mlkit:text-recognition` | 16.0.1 | Google ML Kit Terms / Google APIs Terms (not represented as a project-owned OSS component) | Current bundled Latin artifact in Google's Android guide | Adds no manifest permission in Taxy | Google documents about 4 MB per script/architecture | OCR input/output stays on-device; the SDK may collect operational/device metrics described by Google, which must be reflected in Play data disclosure | Required for immediate, offline Latin OCR without uploading fiscal documents |
| `androidx.core:core-ktx` | 1.15.0 | Apache-2.0 AndroidX component | Stable AndroidX release; newer versions exist | Adds no broad storage/camera permission | Small support-library/transitive impact; exact packaged delta measured at APK level | No project-specific advisory established by this audit; keep dependency scanning enabled | Required for the narrow `FileProvider` content-URI boundary |

Primary references:

- https://developers.google.com/ml-kit/vision/text-recognition/v2/android
- https://developers.google.com/ml-kit/terms
- https://developers.google.com/ml-kit/android-data-disclosure
- https://developer.android.com/jetpack/androidx/releases/core

## Decision

Both dependencies are necessary for the selected architecture and introduce no
new Taxy runtime permission. The bundled ML Kit choice deliberately trades APK
size for offline availability and prevents raw fiscal documents from being sent
to a backend. The Google operational-metrics disclosure remains a release-store
privacy declaration requirement, not document-content egress.

The measured universal debug APK grew from 163,958,140 bytes (156.36 MiB) to
196,987,901 bytes (187.86 MiB): +33,029,761 bytes (+31.50 MiB, +20.15%). The
largest unpacked additions are ML Kit OCR native pipelines for x86_64, arm64-v8a
and armeabi-v7a, followed by the OCR Java/Dex code and bundled Latin models.
This is material but expected for a universal debug APK; release ABI splitting
should be assessed separately before store publication. The dependency is not
replaced in this quality-closure task.

`DEPENDENCY_AUDIT_PASS = YES`
