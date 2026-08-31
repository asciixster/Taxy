# e-Fatura security review (0.7.7)

## Credential storage

- NIF and password are encrypted separately with AES-256-GCM.
- The encryption key is generated in `AndroidKeyStore` and is non-exportable.
- Ciphertext is stored in app-private preferences; Android backup is disabled.
- Associated data binds each ciphertext to its field name.
- No `loadCredentials` platform-channel method exists. Flutter receives only
  non-secret readiness flags after saving.
- Authentication/authorization failure clears stored credentials. Disconnect
  always clears them and transient UI state.

## Password lifecycle

- The UI password controller is obscured and cleared after every connect
  attempt and on disposal.
- Native temporary `CharArray`/`ByteArray` buffers are zeroed where the runtime
  permits it.
- Immutable platform strings can have a JVM-managed lifetime; they are never
  stored in UI state, exceptions, logs, analytics or crash metadata.
- No analytics/crash SDK is integrated.

## Certificate identity

- No PFX, private key or real certificate is committed or bundled.
- Client keys remain in Android KeyChain and are selected with explicit system
  UI. The bridge receives only an alias and uses the private key through the
  platform API.
- The separate AT cipher certificate is public material selected by the user
  and stored in `noBackupFilesDir` after X.509/RSA validation.
- Native CA/hostname validation stays enabled. No permissive trust manager or
  hostname verifier exists.

## Network and protocol

- Endpoint is fixed to the runtime-confirmed HTTPS/8443 FactIntWS endpoint.
- Created comes from one NTP exchange; there is no system-clock fallback or
  automatic retry.
- TLS uses the platform provider and default trust roots plus the selected
  KeyChain identity.
- Exactly three operations exist in the runtime enum: `EcraInicial`,
  `FaturasPorClassificar`, and `FaturasPorSetor`.
- XML parsing disables DTDs and external entities and fails closed on malformed
  invoices or count loss.

## UI, screenshots and logs

- `FLAG_SECURE` is enabled while the experimental screen is open.
- Password is never redisplayed after save.
- No native or Dart connector logging sink logs NIF, password, PFX password,
  issuer NIF, document IDs, request XML or response XML.
- Tests statically enforce the absence of native logging calls and write
  operations.

## Storage and backups

- No raw SOAP, invoice cache or background synchronization is implemented.
- `android:allowBackup="false"` and `android:fullBackupContent="false"` prevent
  app-data backup of credential ciphertext/configuration.
- Disconnect does not touch IRS simulations or drafts.

## Known limitations / blockers

- No Android device was connected in this development environment, so the new
  native bridge could not perform a real on-device request in this release.
- Production certificate provisioning is unresolved; a development PFX must
  never be distributed.
- Android KeyChain authorization and the selected public AT cipher certificate
  must be provisioned on a real device before live use.
- EstadoOperacao `419` is observed for `EcraInicial` year 2025, but its universal
  semantics remain `UNKNOWN`; the UI maps it to a safe `BUSINESS_ERROR` message.
- A backend proxy is a production recommendation, not an implemented service.
