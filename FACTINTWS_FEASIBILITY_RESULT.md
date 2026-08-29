# Taxy 0.7.4 — FactIntWS read-only feasibility result

## Decision

`NOT_READY`

Final classification: `FACTINTWS_DIGEST_NOT_READY`.

The operation schema is also `FACTINTWS_OPERATION_SCHEMA_UNKNOWN`. Because critical fields remained unknown, the fail-closed eligibility gate stopped before configuration loading, PFX use, TLS, HTTP, or SOAP.

## Execution summary

| Field | Result |
|---|---|
| Endpoint selected | `https://servicos.portaldasfinancas.gov.pt:443/mobile/a4/factintws/ws` |
| Operation selected | `ecraInicialF` |
| Planned identity | `TesteWebservices.pfx` |
| PFX actually opened/used | No |
| Live eligibility | `NOT_READY` |
| Network requests | 0 |
| mTLS | `NOT_ATTEMPTED` |
| HTTP | `NOT_AVAILABLE` |
| SOAP response | `NO` |
| Runtime-confirmed FactIntWS elements | None |

## Critical unknowns

- password digest formula, inputs, order, encoding, and XML type/attribute;
- nonce generation, byte length, hash representation, and XML encoding;
- Created timezone, precision, exact format, and digest representation;
- exact `ecraInicialF` root element and mandatory request body;
- SOAPAction and wrapping behavior;
- acceptance of the planned client identity by FactIntWS.

## Next research step

Continue **offline** FactIntWS research by locating the historical `buildPasswordDigest` implementation and the request DTO/serializer for `ecraInicialF`, or equivalent official documentation. Do not perform a live request until both gates can be independently reviewed.

## Safety confirmation

- no AT endpoint was contacted;
- no official-app certificate or private key was used;
- no local credential or PFX was read;
- no raw SOAP containing credentials was created;
- fatshare code and evidence were not changed.
