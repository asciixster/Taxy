# AT Connector Sandbox Results — Taxy 0.7.2

Date (UTC): 2026-08-28  
Environment: AT test  
Endpoint: consultation service on port 725

## Experiment 1 — historical namespace

- Requests: 1
- TLS/mTLS: SUCCESS
- HTTP: 500
- SOAP fault: 33
- Classification: `SOAP_PROTOCOL_ERROR`
- Observation: the server reported `http://factemi.at.min_financas.pt/fatshareInvoices` as expected for `InvoicesRequest`.

## Experiment 2 — namespace only

Namespace: `http://factemi.at.min_financas.pt/fatshareInvoices`

| Field | Result |
|---|---|
| Network requests | 1 |
| TLS/mTLS | NOT_CONFIRMED for this execution |
| HTTP | NOT_AVAILABLE |
| SOAP response | NOT_CONFIRMED |
| Previous fault 33 | UNKNOWN |
| New SOAP fault | NOT_AVAILABLE |
| `EstadoOperacao` | NOT_AVAILABLE |
| `Desc` | NOT_AVAILABLE |
| `totalPages` | NOT_AVAILABLE |
| Invoice count | NOT_AVAILABLE |
| Classification | `PARSING_ERROR` |

The response reached the Node client, but result collection crashed because the response socket had already been released when TLS metadata was read. No raw response was persisted, so no conclusion about namespace acceptance can be made. No retry, fallback or second namespace was attempted.

The local metadata timing bug was corrected after the experiment and covered offline. The namespace was not promoted to `RUNTIME_BEHAVIOR_CONFIRMED`. A future test requires separate authorization and exactly one new request.

No NIF, username, password, ciphertext, AES key, nonce, certificate content, raw XML or invoice detail is recorded.

## Experiment 3 — repeat after TLS capture fix

The protocol and one-day interval were unchanged from experiment 2.

| Field | Result |
|---|---|
| Network requests | 1 |
| TLS/mTLS | SUCCESS (`authorized: true`) |
| HTTP | 200 |
| SOAP response | YES |
| Previous fault 33 | NO |
| Current SOAP fault | NONE |
| `EstadoOperacao` | 486 |
| `Desc` | Empty invoice list (sanitized) |
| `totalPages` | NOT_AVAILABLE |
| Invoice count | 0 |
| Classification | `SUCCESS` |

The operation passed SOAP dispatch and produced a typed business response. Only the `InvoicesRequest` namespace was promoted to `RUNTIME_BEHAVIOR_CONFIRMED`. SOAPAction, cryptography, timestamp precision, username authorization and WFA permissions retain their prior evidence status.

## Experiment 4 — 0.7.3 TLS identity isolation

The current 0.7.3 code, endpoint, SOAP request, one-day interval and TLS options were preserved. The only experimental change was restoring the `TesteWebservices.pfx` client identity that succeeded in 0.7.2. The newer CA2 identity was not retried.

| Field | Result |
|---|---|
| Network requests | 1 |
| TLS/mTLS | SUCCESS (`authorized: true`) |
| HTTP | 200 |
| SOAP response | YES |
| SOAP fault | NONE |
| `EstadoOperacao` | 486 |
| `Desc` | Empty invoice list (sanitized) |
| `totalPages` | NOT_AVAILABLE |
| Invoice count | 0 |
| Parsed invoice count | 0 |
| Classification | `SUCCESS_EMPTY_RESULT` |

This confirms only that the specific `TesteWebservices.pfx` identity is accepted by this test endpoint at runtime. It does not establish that AT Issuing CA1 is universally required, nor that the separate AT Issuing CA2 identity can never work. No invoice field received runtime confirmation because the returned list was empty.

## Experiment 5 — party/population selector

The request changed only `CustomerTaxID` to `TaxRegistrationNumber`, preserving the identifier and every other protocol parameter. The 28-day interval was `2026-08-01` through `2026-08-28`.

| Field | Result |
|---|---|
| Network requests | 1 |
| TLS/mTLS | SUCCESS (`authorized: true`) |
| HTTP | 200 |
| SOAP response | YES |
| SOAP fault | NONE |
| `EstadoOperacao` | 486 |
| `Desc` | Empty invoice list (sanitized) |
| `totalPages` | NOT_AVAILABLE |
| Invoice count | 0 |
| Parsed invoice count | 0 |
| Classification | `SUCCESS_EMPTY_RESULT` |
| Role/population hypothesis | `NOT_CONFIRMED` |

The server accepted the request shape, but an empty response does not confirm the semantic population selected by `TaxRegistrationNumber`. No invoice field was promoted and no retry was made.

## Experiment 5 — August date range only

The known-good identity and all TLS, endpoint, SOAP, authentication, pagination and parser settings were preserved. Only the inclusive date interval changed to `2026-08-01` through `2026-08-28`. The harness's local seven-day guard was temporarily relaxed solely to permit the authorized request and restored immediately afterwards; this did not change the wire protocol and was not committed.

| Field | Result |
|---|---|
| Network requests | 1 |
| TLS/mTLS | SUCCESS (`authorized: true`) |
| HTTP | 200 |
| SOAP response | YES |
| SOAP fault | NONE |
| `EstadoOperacao` | 486 |
| `Desc` | Empty invoice list (sanitized) |
| `totalPages` | NOT_AVAILABLE |
| Invoice count | 0 |
| Parsed invoice count | 0 |
| Page 2 requested | NO |
| Classification | `SUCCESS_EMPTY_RESULT` |
| Follow-up | `EMPTY_RESULT_REQUIRES_REQUEST_SEMANTICS_REVIEW` |

No larger interval, different month, retry or fallback was attempted. No invoice field is promoted to runtime evidence.
