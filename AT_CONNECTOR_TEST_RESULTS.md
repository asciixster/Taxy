# AT Connector Test Results — Taxy 0.7.1

Date: 28 August 2026. Environment: AT test only.

## Confirmed by local execution

| Test | Result |
|---|---|
| PKCS#12 loaded in process memory | PASS |
| Incorrect PKCS#12 password rejected | PASS |
| AT cipher certificate parsed as RSA public key | PASS |
| TLS/mTLS to consultation test endpoint | PASS (`authorized: true`) |
| Empty SOAP 1.1 connectivity probe | HTTP 500, `env:Client / Internal Error` |
| Single `?wsdl` discovery request | HTTP 500, SOAP XML, no WSDL definitions |
| Authenticated consultation | **NOT EXECUTED** |
| Production request | **BLOCKED** |

The authenticated request was not executed because RSA padding, namespace, WSDL/binding and SOAPAction remain unresolved in official sources. No combinations were tried.

## Offline verification

- Connector unit tests: 40 passed.
- Flutter tests: 371 passed; `flutter analyze` reported no issues.
- Local opt-in certificate/connectivity tests: 4 passed.

- AES-128-ECB/PKCS padding checked against an independent OpenSSL vector.
- RSA PKCS#1 v1.5, OAEP-SHA1 and OAEP-SHA256 are explicit library modes with no default; unit tests round-trip each using an independent private-key operation. Their implementation does not mean any mode is accepted for AT.
- New CSPRNG session keys are 16 bytes and differ across requests.
- UsernameToken, timestamp validation, XML escaping, consultation DTOs, evidence gate, redaction and error taxonomy are tested.
- Dry-run is fail-closed and performs zero network requests.

No raw AT response, NIF, username, password, Nonce, AES key or certificate content is persisted.
