# DM3IRS authentication analysis

## Application-layer authentication

The SOAP 1.1 header contains `wss:Security` with `wss:UsernameToken`, `wss:Username`, `wss:Password`, `wss:Nonce` and `wss:Created`. It carries AT authentication namespace metadata and version `2`.

Confirmed from compiled code:

- a fresh secure-random AES key is generated per authentication header;
- the password is encrypted with AES plus PKCS#7 padding and Base64 encoded;
- the digest is SHA-1 over assembled authentication material, encrypted with the AES key and Base64 encoded;
- the nonce transports the AES key encrypted with the AT RSA public key using PKCS#1 encoding, then Base64 encoded;
- `Created` is the current UTC ISO-8601 timestamp;
- username is the taxpayer login identity; household requests can carry one header per represented taxpayer whose credentials exist.

This is `CONFIRMED_FROM_CODE` at the algorithm/component level. Exact byte concatenation and legacy wire quirks require a sanctioned test contract before independent implementation.

## Transport authentication

The production client loads a bundled PKCS#12 certificate chain and private key into a Dart `SecurityContext`; DM3IRS therefore uses TLS client authentication in the official path. The app also pins the Portal public certificate. SNI follows the exact Portal hostname and the production service is on port 411.

No bundled PKCS#12 was opened, unlocked or used. Consequently the official client public certificate fingerprint is intentionally unknown.

## Taxy comparison

The AT RSA request-encryption public key matches Taxy's already-known public key by SPKI SHA-256. This confirms the same AT encryption recipient, not the same caller identity or entitlement.

The legitimate Taxy client identity is proven only for FactIntWS. DM3IRS authorization is not transitive, and no sanctioned Taxy DM3IRS channel metadata or entitlement is available. Result: `TAXY_AUTH_FEASIBILITY = UNKNOWN` and `TAXY_AUTH_PATH_KNOWN = NO`.

## Runtime evidence and current decision

Later, separately authorized one-shot probes used only the legitimate Taxy identity. Catalogs succeeded. A corrected `infoUtilizador` request completed TLS, returned HTTP 200 and the exact non-Fault response root, then returned status `130`. Offline AOT tracing now establishes that `130` and `131` are handled as `BadIrsYear`; the login flow displays “Período de entrega de IRS não é válido”.

This confirms Taxy mTLS acceptance and the common SOAP-auth framing, but it does not grant contractual product entitlement or establish successful profile access. The APK itself configures exercise year `2025`, which was also used by the corrected request. No deterministic request correction exists. The correct next step is AT clarification of the accepted exercise/campaign year and entitlement—not another probe or reuse of the official app identity.
