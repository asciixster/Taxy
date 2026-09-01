# Internal beta observability

## Scope

The 0.7.10 internal beta uses only `https://api.taxy.pt`. The normal Flutter flow has no direct FactIntWS path, old-backend fallback, localhost fallback, or write operation.

Each public API request emits a sanitized diagnostic event with:

- an opaque, random 128-bit correlation ID, also sent as `X-Correlation-ID`;
- a normalized route (dynamic sector codes become `:sector`);
- HTTP status when available;
- elapsed milliseconds;
- one stable error category;
- `manualAttempt=true` and `attempt=1` (there is no automatic retry).

Categories are `NETWORK_OFFLINE`, `DNS_ERROR`, `TLS_ERROR`, `TIMEOUT`, `AUTH_FAILED`, `SESSION_EXPIRED`, `RATE_LIMITED`, `BACKEND_UNAVAILABLE`, `UPSTREAM_PORTAL_UNAVAILABLE`, `MALFORMED_RESPONSE`, and `UNKNOWN`.

## Explicitly excluded data

Diagnostics never contain Portal passwords, NIFs, bearer tokens, invoice/document IDs, issuer identities, raw JSON, raw Portal HTML, cookies, PFX material, or upstream response bodies. Routes are allow-listed and normalized before logging.

## Timeouts and recovery

- connection establishment: 20 seconds;
- response and response-stream activity: 90 seconds;
- redirects: disabled;
- retries: manual only.

For 502/503/504, offline, TLS, timeout, invalid response, or rate limiting, the user sees localized non-technical copy and an explicit manual retry. A 401 or expired session deletes the local secure token and returns to authentication.

## Health and troubleshooting

Check `https://api.taxy.pt/health` once before and once after an E2E run. Correlate a client report and backend log using only the correlation ID, normalized route, status, and time window. Never request screenshots containing fiscal data or ask a tester to export application storage.

## Build identity

Internal builds expose version, build number, short Git SHA, `internal-beta`, and `api.taxy.pt` in Settings. Build with the documented `--dart-define` values; production defaults keep the e-Fatura feature disabled.
