# Android release signing required

The release signing configuration is complete but its credentials are not
present on this machine. Keep the production keystore outside the repository
and provide these environment variables only in the private release shell or
CI secret store:

- `TAXY_ANDROID_KEYSTORE_PATH`: absolute path to the production keystore
- `TAXY_ANDROID_KEYSTORE_PASSWORD`: keystore password
- `TAXY_ANDROID_KEY_ALIAS`: production key alias
- `TAXY_ANDROID_KEY_PASSWORD`: private-key password

Never commit the keystore, `key.properties`, passwords, aliases copied from a
private environment, or generated signing reports containing secrets. Do not
use the Android debug keystore for distribution.

After provisioning the four values, generate the signed bundle from the
repository root:

```powershell
flutter build appbundle --release --dart-define=TAXY_EFATURA_EXPERIMENTAL=true
```

Then verify the bundle identity/version and signing certificate in the private
release environment before upload.

The explicit e-Fatura define enables the reviewed read-only `api.taxy.pt`
product route for this beta. Omitting it keeps the experimental module hidden;
it never selects the native FactIntWS research bridge.
