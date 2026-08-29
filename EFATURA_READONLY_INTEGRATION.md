# e-Fatura read-only integration (0.7.7)

## Status

The e-Fatura application surface is **Experimental** and disabled by default.
It can be compiled in with `--dart-define=TAXY_EFATURA_EXPERIMENTAL=true`.
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
