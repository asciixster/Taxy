# Taxy 0.7.4 — offline FactIntWS feasibility result

## Offline decision

`CONTINUE WITH ONE TARGETED FIX — TLS TRANSPORT FAILURE`

The cryptographic and wire reconstruction gates pass for the `EcraInicial` operation. The
offline phase made zero network requests and did not open any certificate or
credential. Readiness means the official app contract is sufficiently
reconstructed. The channel semantics were closed as `RUNTIME_DEVICE_METADATA` and
the first request used the coherent API 35 / Android 15 pair. All offline gates
passed before the one permitted request.

| Field | Result |
|---|---|
| Candidate | `EcraInicial` (read-only) |
| Endpoint | primary port 443 |
| Auth reconstruction | exact from official app code |
| Request schema | complete |
| Response schema/parser | complete for documented DTO fields |
| HTTP/SOAP serialization | complete, including exact unquoted SOAPAction |
| Created source | NTP verified in one real UDP exchange; system fallback forbidden |
| Channel evidence | `Sistema=A`; exact dynamic `Versao` formula confirmed |
| Concrete channel values | API 35 / Android 15; explicit runtime metadata |
| Local PFX preflight | READY; key present; 3 certs; valid chain/clientAuth EKU |
| Network requests | 1 |
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

## Controlled live result

The connection emitted TLS `secureConnect`, then failed before HTTP with
`ERR_SSL_DECRYPTION_FAILED_OR_BAD_RECORD_MAC`. No SOAP response or fault was
received, the operation was not recognized, and no channel or authentication
element was promoted to runtime-confirmed. No retry, 8443 fallback, second
channel, second certificate, or second operation was attempted.

The next work should target only the post-handshake TLS transport failure. It must
not vary `CanalOrigem` or SOAP fields without new evidence.

## TLS 1.2-only single-variable experiment

Exactly one later request changed only the TLS maximum version, producing the
range `TLSv1.2`–`TLSv1.2`. It used no custom cipher list. The server returned
OpenSSL code `EPROTO` with sanitized TLS alert 40 (`handshake failure`) during the
handshake, before `secureConnect`.

- network requests: 1;
- negotiated protocol/cipher/ALPN: not available;
- HTTP/SOAP: not available;
- TLS 1.2 runtime-confirmed: no;
- retries, fallback and additional variations: none.

The next investigation should remain TLS-only and evidence-led. SOAP,
`CanalOrigem`, credentials and application operations were not implicated.
