# e-Fatura runtime bridge architecture (0.7.7)

## Decision

The experimental Android implementation uses a narrow **Android platform
channel/native module**. Flutter owns presentation and normalized application
models. Android owns credential encryption, client-key access, NTP, FactIntWS
cryptography, TLS/mTLS, SOAP serialization and response parsing.

The channel never exposes a method that loads stored credentials. After `save`,
Flutter can retrieve only readiness booleans. Native responses cross the channel
only after identifiers and SOAP details have been removed.

## Options considered

| Option | Security | Packaging/maintenance | Testability | Decision |
|---|---|---|---|---|
| A. Pure Dart protocol | Good for deterministic crypto and XML tests, but Dart `SecurityContext` cannot directly use a non-exportable Android KeyChain private key | Would require exporting key material or parsing a PFX in Dart memory | High for protocol; weak for Android identity lifecycle | Rejected for client identity |
| B. Android platform channel/native module | Android KeyStore protects credentials and KeyChain performs operations with the selected client key without exporting it | No Node runtime, shell, command-line secrets or localhost service | Flutter channel tests + Kotlin protocol vectors | **Selected** |
| C. Embedded local service/process | Adds lifecycle, IPC authentication and packaging attack surface | Requires a second runtime/process on device | Complex | Rejected |

This follows Android's documented model: KeyStore keys can remain
non-exportable, while `KeyChain.choosePrivateKeyAlias` grants an app access to a
user-selected client identity. The Flutter side uses the standard platform
channel mechanism.

- Android Keystore: https://developer.android.com/privacy-and-security/keystore
- Android KeyChain: https://developer.android.com/reference/android/security/KeyChain
- Flutter platform channels: https://docs.flutter.dev/platform-integration/platform-channels

## Runtime flow

```text
Flutter experimental UI
  -> saveCredentials(NIF, password)
  -> Android Keystore AES-GCM encrypted storage
  -> EcraInicial (single login-validation request)
  -> Android KeyChain client identity + native CA validation
  -> NTP Created + FactIntWS crypto/SOAP
  -> secure XML parser
  -> normalized overview/invoice maps only
  -> EfaturaReadOnlyService
  -> UI
```

Pending invoices are requested only when the overview count is positive.
Sector invoices are requested only after a user taps one sector. There is no
prefetch, retry, polling or write operation.

## Certificate strategy

The development identity is **not** embedded in the repository or APK. For the
local-direct experimental path, the user provisions a client identity into the
Android KeyChain and explicitly grants Taxy its alias. The public AT cipher
certificate is selected separately and copied into the application's
`noBackupFilesDir`; it contains no private key.

`TesteWebservices.pfx` remains development/runtime material and is never an APK
asset. Its private key is not the production distribution strategy.

## LOCAL_DIRECT_AT vs TAXY_BACKEND_PROXY

| Model | Advantages | Costs/risks |
|---|---|---|
| `LOCAL_DIRECT_AT` | Fiscal data and Portal credentials remain on device; no Taxy data processor in the request path | Client-certificate provisioning, protocol updates and device compatibility are difficult; a shared PFX must never be distributed |
| `TAXY_BACKEND_PROXY` | Keeps service identity server-side, centralizes protocol/security updates and simplifies the app | Fiscal data and credentials cross Taxy infrastructure, creating significant RGPD, security, audit and incident-response obligations |

**Production recommendation: `BACKEND_PROXY`, but only after a dedicated threat
model, DPIA/RGPD review, secret-management design and explicit user consent.**
The implemented local-direct bridge remains an experimental validation path;
this release does not implement a backend.

## Parity

Kotlin tests use the same synthetic AES key, Created and password vector as the
Node reference. Encrypted password and digest are byte-equal. RSAES-PKCS1-v1_5
ciphertext is randomized, so parity is verified by decrypting the nonce back to
the exact 128-bit AES key. Security header and request order are asserted
independently.
