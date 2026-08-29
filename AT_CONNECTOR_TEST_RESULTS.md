# AT Connector Test Results — Taxy 0.7.3

Updated: 29 August 2026. Environment: AT test only.

## Confirmed by local execution

| Test | Result |
|---|---|
| PKCS#12 loaded in process memory | PASS |
| Incorrect PKCS#12 password rejected | PASS |
| AT cipher certificate parsed as RSA public key | PASS |
| TLS/mTLS to consultation test endpoint | PASS (`authorized: true`) |
| Empty SOAP 1.1 connectivity probe | HTTP 500, `env:Client / Internal Error` |
| Single `?wsdl` discovery request | HTTP 500, SOAP XML, no WSDL definitions |
| Historical authenticated consultation | Experiment 5: `TaxRegistrationNumber`, HTTP 200, no fault, EstadoOperacao 486, empty list; role/population hypothesis not confirmed |
| Real invoice parsing 0.7.3 | The CA2 identity passed local preflight but failed during mTLS. A separate single-variable repeat with the known-good `TesteWebservices.pfx` identity reached mTLS authorized, HTTP 200 and `EstadoOperacao` 486 with an empty list. No runtime invoice fields are claimed. |
| Production request | **BLOCKED** |

Experiment 1 established the namespace rejection. Experiment 2 changed only that namespace and made one read-only request, but a local TLS-metadata timing bug prevented capture of the response summary. It was fixed and regression-tested offline; the live request was not repeated.

Experiment 3 repeated the same request once after the capture fix. The namespace passed dispatch and was promoted alone to runtime-confirmed evidence. No invoice payload was stored and no retry occurred.

The 0.7.3 identity-isolation experiment changed only the client PFX identity back to `TesteWebservices.pfx`. It returned `SUCCESS_EMPTY_RESULT`. That identity is runtime-confirmed for the test endpoint; no universal CA requirement is inferred and the distinct CA2 identity remains unconfirmed.

## Offline verification

- Connector tests: 81 passed; 4 opt-in local integration tests skipped offline.
- Flutter tests: 371 passed; `flutter analyze` reported no issues.
- Local opt-in certificate/connectivity tests: 4 passed.

- AES-128-ECB/PKCS padding checked against an independent OpenSSL vector.
- RSA PKCS#1 v1.5, OAEP-SHA1 and OAEP-SHA256 are explicit library modes with no default; unit tests round-trip each using an independent private-key operation. Their implementation does not mean any mode is accepted for AT.
- New CSPRNG session keys are 16 bytes and differ across requests.
- UsernameToken, timestamp validation, XML escaping, consultation DTOs, evidence gate, redaction and error taxonomy are tested.
- Historical dry-run is fail-closed, sanitizes the envelope and performs zero network requests.
- PKCS#12 preflight uses ephemeral synthetic bundles for valid, invalid-password and certificate-without-key regressions. No test certificate is committed.
- PKCS#12 chain audit uses ephemeral synthetic leaf-only, complete-intermediate and unrelated-CA bundles. TLS error regression tests retain only stable sanitized categories.

No raw AT response, NIF, username, password, Nonce, AES key or certificate content is persisted.
