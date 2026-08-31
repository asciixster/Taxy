# Taxy e-Fatura backend bridge

## Decision

The production direction is now `BACKEND_PROXY`:

```text
Flutter UI
  -> HTTPS Taxy backend session
  -> existing server-side Portal das Finanças reader
  -> normalized read-only JSON
  -> EfaturaReadOnlyService
```

The existing Android/FactIntWS implementation remains available only when no
backend URL is configured. It is not removed because it contains useful protocol
and runtime evidence, but it is not the recommended production path.

Enable the backend path only in an experimental build:

```text
--dart-define=TAXY_EFATURA_EXPERIMENTAL=true
--dart-define=TAXY_EFATURA_BACKEND_URL=https://dev.contabilidades.pt/
```

The URL must use HTTPS, must not contain user information and is never derived
from user input.

## Confirmed server-side source

The currently operational accounting portal uses the Portal das Finanças web
flow, not FactIntWS. Its reader:

- opens `consultarDocumentosAdquirente.action`;
- performs the official login/forward flow;
- keeps cookies in a mode-0600 temporary file;
- reads `json/obterDocumentosAdquirente.action`;
- splits date ranges when the AT result is truncated;
- logs out and destroys the cookie file;
- stores Portal credentials encrypted with libsodium;
- normalizes acquired-document fields before persistence.

This is the source now wrapped by the development backend API. The mobile application must not
receive its cookies, raw AT responses, database identifiers or encrypted
credential records.

## Mobile API contract

### Create session

`POST v1/efatura/sessions`

Request (TLS only):

```json
{"nif":"<9 digits>","password":"<portal password>"}
```

The backend validates the credentials through the existing read-only Portal
flow and returns a short-lived, random, single-user capability plus the first
overview. It must not log the request body.

```json
{
  "sessionToken": "<opaque random value>",
  "overview": {
    "provisionalBenefitCents": 0,
    "pendingValidation": 0,
    "pendingRevenueAssociation": 0,
    "sectors": []
  }
}
```

The Flutter bridge holds only the opaque token in memory. The first overview is
reused, so connecting does not create an immediate duplicate request.

### Read-only operations

- `GET v1/efatura/overview`
- `GET v1/efatura/invoices/pending`
- `GET v1/efatura/sectors/{sectorCode}/invoices`
- `DELETE v1/efatura/session`

Authenticated calls use `Authorization: Bearer <opaque token>`. Tokens have a
15-minute idle TTL and a one-hour absolute TTL, are stored as hashes server-side,
are bound to one taxpayer and are revoked on logout. No endpoint for classifying, registering,
deleting or associating invoices is part of this contract.

Invoice responses contain only normalized UI fields:

```json
{
  "invoices": [
    {
      "date": "2026-08-29",
      "totalCents": 2345,
      "vatCents": 439,
      "issuerDisplayName": "Example supplier",
      "sectorCode": "C05",
      "sectorLabel": "Health",
      "classificationStatus": "unknown",
      "pendingClassification": false
    }
  ]
}
```

The backend must never return taxpayer NIFs, issuer NIFs, document IDs, Portal
cookies, raw HTML/JSON, credential ciphertext or internal database keys.

Aggregate fields use the explicit availability contract documented in
`EFATURA_AGGREGATES_AVAILABILITY.md`. Missing upstream aggregates must be
reported as `unavailable`; they must never be represented by a synthetic zero
or empty list.

Available sector entries may additionally expose `totalExpenses` and
`totalVatExpenses` availability wrappers. The Flutter domain sums those values
only when the sector population is complete. They remain separate from AT's
official provisional-benefit aggregate and are evidence for a future IRS
estimate, not a final refund calculation.

Pending-validation data remains readable through the backend contract for
diagnostics and normalized data access, but the Taxy application does not
present any validation action. All account changes stay in the official
e-Fatura application.

## Required backend controls before public deployment

- explicit consent and privacy notice for transmitting Portal credentials;
- rate limiting by account and network source;
- no request-body, authorization-header or upstream-payload logging;
- encrypted credential handling only for the lifetime required by the session;
- CSRF is not relevant to bearer API calls, but strict CORS and content type are
  still required for browser clients;
- response `Cache-Control: no-store`;
- server-side authorization on every request;
- audit events containing operation, status, count and timing only;
- DPIA/RGPD review, retention policy and incident response;
- independent penetration test before enabling the feature by default.

## Fail-closed behavior

Missing aggregates, malformed JSON, oversized responses, redirects, HTTP/TLS
errors and unknown session states are mapped to the existing safe application
error taxonomy. They are never silently converted to zero. The feature flag
remains disabled by default.

## Android runtime validation (2026-08-31)

The experimental Android build completed the real read-only path through
Flutter, the HTTPS backend and the existing Portal reader. The normalized
overview reached Flutter and rendered five invoices pending validation, matching
the independently observed account summary. Opening the pending list rendered
real invoice tiles without exposing taxpayer NIFs, document identifiers or raw
upstream responses in the UI diagnostics.

This validates the backend bridge, session lifecycle and pending-invoice mapping.
It does not yet validate the full overview contract: the current Portal reader
does not provide the provisional-benefit aggregate or sector summary. The
compatibility response currently renders these unavailable aggregates as zero;
those zeros are not runtime-confirmed account values. The fields must be sourced
explicitly, and their unavailable state represented separately, before the
corresponding UI values can be treated as real data. No write
operation was implemented or invoked, and the experimental feature flag remains
disabled by default.
