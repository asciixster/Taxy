# Android production signing

Release builds are fail-closed: Taxy never falls back to the Android debug key.

Configure the release runner with these secret environment variables:

- `TAXY_ANDROID_KEYSTORE_PATH`
- `TAXY_ANDROID_KEYSTORE_PASSWORD`
- `TAXY_ANDROID_KEY_ALIAS`
- `TAXY_ANDROID_KEY_PASSWORD`

The keystore must live outside Git and outside the APK source tree. CI secrets must
provide the file and values only for the release job. A release/bundle task fails
before compilation if any value is absent. Debug builds remain developer-signed.

Before distribution, verify the AAB signature, record the signing certificate
fingerprint in the private release register, and scan the archive for `.env`,
keystore, certificate, private-key, password, token and raw fiscal payload files.

