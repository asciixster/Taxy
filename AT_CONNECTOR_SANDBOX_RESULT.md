# AT Connector Sandbox Result — Taxy 0.7.2

Date (UTC): 2026-08-28  
Environment: AT test  
Endpoint: consultation service on port 725
Branch: `at-connector-historical-soap-0.7.2`  
Live request count: **1**

## Sanitized result

| Field | Result |
|---|---|
| TLS / mTLS | SUCCESS (`authorized: true`) |
| HTTP | 500 |
| SOAP response | YES |
| SOAP fault code | `33` |
| Classification | `SOAP_PROTOCOL_ERROR` |
| `EstadoOperacao` | NOT_AVAILABLE |
| `Desc` | NOT_AVAILABLE |
| `totalPages` | NOT_AVAILABLE |
| Invoice count | NOT_AVAILABLE |

The service rejected the historical application namespace and identified `http://factemi.at.min_financas.pt/fatshareInvoices` as the expected namespace for `InvoicesRequest`. The request used the unchanged historical namespace `http://fatshare.at.min_financas.pt/fatshare`.

No retry, fallback or protocol variant was attempted. No field was promoted to `RUNTIME_BEHAVIOR_CONFIRMED`, because authentication and the application operation were not accepted. The next minimum experiment is a separately reviewed namespace-only change followed by one new opt-in request.

No NIF, username, password, ciphertext, AES key, nonce, certificate content, raw XML or invoice detail is recorded.
