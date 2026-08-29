# Taxy 0.7.4 — offline FactIntWS feasibility result

## Offline decision

`CONTINUE WITH ONE TARGETED FIX — LIVE GATE NOT READY`

The cryptographic and wire reconstruction gates pass for the `EcraInicial` operation. The
offline phase made zero network requests and did not open any certificate or
credential. Readiness means the official app contract is sufficiently
reconstructed. A one-exchange NTP provider and the local PFX preflight now pass;
live execution remains blocked only by the unknown concrete runtime Android
SDK/release pair used to construct `CanalOrigem.Versao`.

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
| Concrete channel values | runtime SDK/release unavailable; live-blocking |
| Local PFX preflight | READY; key present; 3 certs; valid chain/clientAuth EKU |
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

## Recommended single live test after both gates pass

Obtain one evidence-backed Android `SDK_INT` and `RELEASE` pair for the intended
mobile channel, then use only the legitimate `TesteWebservices.pfx`, the locally
validated AT RSA public cipher certificate, the primary endpoint 443 and one
`EcraInicial` request. Do not retry or fall back. No FactIntWS request was made in
this gate-completion task because the channel gate remained closed.
