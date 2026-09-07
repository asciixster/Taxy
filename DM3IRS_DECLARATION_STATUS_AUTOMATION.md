# DM3IRS declaration-status automation

## Proposed read-only flow

`scheduled/user refresh -> checkEntregaDeclMobileRequest(year, taxpayer session) -> normalized declaration state -> compare sanitized state token -> action`

- unchanged: update freshness only; no notification and no further call;
- changed: show a generic local notification (“Your IRS declaration status changed”) and fetch details only after the user opens Taxy;
- declaration reference appears: offer receipt lookup on demand;
- authorization/session failure: stop monitoring and request re-authentication without exposing upstream codes.

## Data minimization

Persist only tax year, normalized state, last-checked time and a one-way/opaque change token if needed. The declaration reference remains session-only until an on-demand receipt request. Do not persist taxpayer identifier, raw status message or SOAP.

## Operating policy

No polling is implemented here. A future implementation needs an AT rate limit, user opt-in, conservative interval, backoff, foreground refresh preference and a kill switch. Status checks must never call submission or mutate declaration state.
