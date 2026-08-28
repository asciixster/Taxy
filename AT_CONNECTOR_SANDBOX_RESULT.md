# AT Connector Sandbox Result — Taxy 0.7.2

Date (UTC): 2026-08-28  
Environment: AT test  
Endpoint: `https://servicos.portaldasfinancas.gov.pt:725/fatshare/ws/fatshareFaturas`  
Branch: `at-connector-historical-soap-0.7.2`  
Commit SHA: NOT_APPLICABLE (live request not executed)  
Live request count: **0**

## Result

`AUTH_CONFIGURATION_MISSING`

The local AT client PFX and public cipher certificate were available, but `AT_USERNAME` and `AT_PASSWORD` were absent. No authenticated request was sent. This is a fail-closed configuration result, not a protocol rejection.

| Check | Result |
|---|---|
| Historical envelope implementation | PASS (offline) |
| Sanitized dry-run behavior | PASS (offline tests) |
| TLS authorized | NOT_EXECUTED |
| HTTP status | NOT_EXECUTED |
| SOAP fault | NOT_EXECUTED |
| `EstadoOperacao` / `Desc` | NOT_EXECUTED |
| `totalPages` / invoice count | NOT_EXECUTED |
| Runtime evidence confirmed | NO |
| Production request | BLOCKED |

No NIF, username, password, ciphertext, AES key, nonce, certificate content or invoice detail is recorded. A future authorized execution must update this file with sanitized facts only and still make no more than one request.
