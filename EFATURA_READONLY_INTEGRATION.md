# e-Fatura read-only integration (0.7.6)

## Status

The e-Fatura application surface is **Experimental** and disabled by default.
It can be compiled in with `--dart-define=TAXY_EFATURA_EXPERIMENTAL=true`.
The default app wiring uses an unconfigured gateway; no PFX path, password,
username, SOAP envelope or authentication object crosses into Flutter UI code.
A future secure native/tooling bridge is required before live data can be shown
inside the app.

## Application boundary

`EfaturaReadOnlyService` exposes only:

- `loadOverview()`;
- `loadPendingInvoices()`;
- `loadSectorInvoices(sectorCode)`.

Sector input is validated before reaching the gateway. Models contain normalized
display data and integer cents only. The UI offers manual refresh and read-only
navigation; it contains no classification, registration, deletion or revenue
association action.

## Controlled runtime discovery

Exactly two FactIntWS calls were made, without retries:

1. `EcraInicial`, year 2026: HTTP 200, business status 200; sectors `C01`–`C15`
   and `C99` were present, with all observed activity aggregates equal to zero.
2. `EcraInicial`, year 2025: HTTP 200, business status 419; the sanitized
   message directs the taxpayer to Portal das Finanças for IRS deduction expenses.

No sector had runtime evidence of documents, and the pending counters were zero.
The exploration therefore stopped without speculative sector requests.

`REAL_FACTINT_INVOICE_RESPONSE_OBSERVED = NO`

`REAL_FACTINT_INVOICE_PARSING_CONFIRMED = NO`

## Privacy and storage

No live SOAP payload, NIF, issuer identity, document ID, credential,
certificate or passphrase is persisted. Tests use synthetic data only. No cache,
polling or background synchronization is implemented.
