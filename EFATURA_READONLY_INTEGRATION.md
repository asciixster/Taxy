# e-Fatura read-only integration (0.7.7)

## Status

The e-Fatura application surface is **Experimental** and disabled by default.
It can be compiled in with `--dart-define=TAXY_EFATURA_EXPERIMENTAL=true`.

## Runtime status (2026-09-20)

The public Taxy endpoint reaches two independent authenticated official
e-Fatura JSON operations. The invoice-list operation can return HTTP 429 at
`/json/obterDocumentosAdquirente.action`, while the personal-deductions
operation `/json/obterDocumentosIRSAdquirente.action` remains available.

The backend now preserves invoice HTTP 429 as partial availability. Login and
overview continue with official personal-deduction totals, while the pending
invoice counter remains `unavailable` and the invoice list retains the
actionable rate-limit state. No automatic retry is performed.

Controlled runtime confirmation for 2026 returned HTTP 201 from the public
session endpoint, six official sector groups (`C01`, `C03`, `C05`, `C06`,
`C09`, `C99`) and an available provisional benefit. The session was then
deleted successfully (HTTP 200). No amount or invoice payload was persisted.
The app wiring now uses a concrete Android platform bridge. Portal credentials
are saved through an Android Keystore-backed store and are never returned to
Flutter after save. The native module owns NTP, crypto, mTLS, SOAP and parsing;
only normalized overview and invoice fields cross into Flutter.

The bridge remains Experimental and requires user-controlled provisioning of a
client identity in Android KeyChain plus the public AT cipher certificate. No
PFX is bundled.

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

No live SOAP payload, NIF, issuer tax identifier, document ID, credential,
certificate or passphrase is persisted. Tests use synthetic data only. No cache,
polling or background synchronization is implemented.

See [EFATURA_RUNTIME_BRIDGE_ARCHITECTURE.md](EFATURA_RUNTIME_BRIDGE_ARCHITECTURE.md)
and [EFATURA_SECURITY_REVIEW.md](EFATURA_SECURITY_REVIEW.md).
