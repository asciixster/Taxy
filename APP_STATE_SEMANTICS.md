# Application state and error semantics

## Shared failure taxonomy

| Diagnostic category | User meaning | Expected action |
|---|---|---|
| `NETWORK_OFFLINE` | The device cannot reach a required service | Keep local state; offer manual retry |
| `TIMEOUT` | The service did not answer in time | Stop loading; offer manual retry |
| `AUTH_REQUIRED` | Credentials/session are required | Ask the user to connect |
| `SESSION_EXPIRED` | A previous capability is no longer valid | Clear it and reconnect |
| `SERVICE_UNAVAILABLE` | Remote service is temporarily unavailable | Preserve last usable local state |
| `MALFORMED_DATA` | Data cannot be interpreted safely | Fail closed; do not create zero values |
| `MISSING_REQUIRED_DATA` | The product needs more user facts | List the missing facts |
| `UNKNOWN` | No safe classification is available | Show a neutral message and correlation ID if present |

Profile, income, expenses and saved IRS simulations are local and available
offline. e-Fatura needs a network connection and never polls in the background.
No screen may show indefinite progress: every remote operation has finite timeout
and manual retry. A stale label can only be shown when a real `lastUpdatedAt`
exists; 0.7.12 does not invent one.

