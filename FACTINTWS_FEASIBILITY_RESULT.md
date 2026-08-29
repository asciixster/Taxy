# Taxy 0.7.4 — offline FactIntWS feasibility result

## Offline decision

`READY FOR A SEPARATELY APPROVED SINGLE LIVE FACTINTWS TEST`

The offline reconstruction gates pass for the `EcraInicial` wire operation. The
offline phase made zero network requests and did not open any certificate or
credential. Readiness means the official app contract is sufficiently
reconstructed; it does not mean Taxy's TLS identity or credentials are accepted
by FactIntWS.

| Field | Result |
|---|---|
| Candidate | `EcraInicial` (read-only) |
| Endpoint | primary port 443 |
| Auth reconstruction | exact from official app code |
| Request schema | complete |
| Response schema/parser | complete for documented DTO fields |
| HTTP/SOAP serialization | complete |
| Network requests | 0 |
| Runtime-confirmed elements | none |
| Official-app private identity used | no |

## First controlled live attempt (subsequent explicit authorization)

Exactly one request was attempted against the primary 443 endpoint. It failed
during TLS before any HTTP or SOAP response with the sanitized OpenSSL category
`decryption failed or bad record mac`. This is classified `TLS_ERROR`, not
`TLS_IDENTITY_REJECTED`: no certificate-required/bad-certificate alert was
observed, so the run neither confirms nor rejects the Taxy identity.

- network requests: 1;
- HTTP: not available;
- SOAP/operation response: not received;
- protocol elements promoted to runtime evidence: none;
- retries/fallback/alternate endpoint: none.

## Recommended single live test

Audit the Node/OpenSSL TLS failure locally before authorizing another request.
Do not change SOAP, authentication fields, endpoint, operation or credentials
until the transport-level cause is isolated.
