# Taxy 0.7.4 — offline FactIntWS feasibility result

## Decision

`READY FOR A SEPARATELY APPROVED SINGLE LIVE FACTINTWS TEST`

The offline reconstruction gates now pass for the `EcraInicial` wire operation. This task made zero network requests and did not open any certificate or credential. Readiness means the official app contract is sufficiently reconstructed; it does not mean Taxy's TLS identity or credentials are accepted by FactIntWS.

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

## Recommended single live test

Use the legitimate Taxy PFX, primary endpoint 443, one `EcraInicial` request for the current year, a single fresh security token, no retry and no 8443 fallback. Capture only TLS/HTTP/fault/operation-presence metadata and sanitized aggregate field presence. Do not run another operation automatically.
