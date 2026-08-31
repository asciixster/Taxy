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
--dart-define=TAXY_EFATURA_BACKEND_URL=https://<taxy-backend>/api/
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

This is the source the backend API must wrap. The mobile application must not
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

Authenticated calls use `Authorization: Bearer <opaque token>`. Tokens must have
a short idle and absolute TTL, be stored as hashes server-side, be bound to one
taxpayer and be revoked on logout. No endpoint for classifying, registering,
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
