# Taxy 0.7.3 — e-Fatura invoice field presence

This table distinguishes runtime observation from offline parser coverage. A 0.7.3 request using the separate CA2 identity failed during mTLS. A later single-variable request restored the exact `TesteWebservices.pfx` identity known to work in 0.7.2 and completed with mTLS authorized, HTTP 200 and `EstadoOperacao` 486. The returned list was empty, so no invoice payload was received and **no invoice field is claimed as runtime-observed**.

The parser coverage column is exercised only with clearly synthetic, sanitized XML. It is not evidence of the AT response contract.

| Field | Observed in real invoice | Parsed offline | Type | Notes |
|---|---:|---:|---|---|
| Invoice date | No | Yes | date-only `YYYY-MM-DD` | No timezone conversion |
| Issuer tax identifier | No | Presence only | boolean | Identifier value is never exposed by the typed result |
| Document type | No | Yes | optional string/status | Unknown value remains explicit |
| Document reference | No | Presence only | boolean | Reference value is never exposed |
| Total amount | No | Yes | integer cents | Decimal parsing is exact; no `double` |
| Taxable amount | No | Yes | optional integer cents | `NOT_AVAILABLE` when absent |
| VAT amount | No | Yes | optional integer cents | `NOT_AVAILABLE` when absent |
| VAT rates | No | Yes | optional list of basis points | Multiple rates remain separate |
| Sector/category | No | Yes | optional string/status | No semantic meaning is inferred |
| Classification status | No | Yes | optional string/status | Unknown value remains explicit |
| Pending status | No | Yes | optional string/status | No boolean coercion without runtime evidence |
| Invoice identifier | No | Presence only | boolean | Identifier value is never exposed |
| Source | No | Yes | optional string/status | No enum is invented |
| Pagination metadata | No | Yes | typed non-negative integers | Only page 1 is requested; no automatic pagination |

## Runtime conclusion

- Interval selected: `2026-08-28` through `2026-08-28`.
- Actual network requests: `1`.
- HTTP/SOAP/business response: HTTP 200, SOAP response received, `EstadoOperacao` 486.
- Preflight classification: `READY`.
- mTLS classification: `SUCCESS` (`authorized: true`) for the `TesteWebservices.pfx` identity.
- Real invoices parsed: `0`.
- Protocol changes: none.

The result confirms only the specific CA1-issued identity for this endpoint. It neither establishes a universal CA1 requirement nor rejects all possible use of the distinct CA2 identity.

No raw XML, certificate material, NIF, document reference, invoice identifier or credential was persisted.
