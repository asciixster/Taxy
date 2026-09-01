# First external beta scope

## Included

- Short onboarding and Home launcher.
- Local IRS simulation for the documented supported scope, clearly marked estimate.
- Saved local draft/resume flow.
- PT-PT experience. English remains included only after the app-wide translation
  gate passes.
- Settings language and sanitized build diagnostics.
- Read-only e-Fatura pending invoice access only after its external feature and
  operational security gates are explicitly enabled.

## Excluded

- Fiscal writes of any kind.
- Official filing, validation or submission.
- Provisional e-Fatura benefit and sectors without an official semantically
  equivalent source; document sums are not a substitute.
- Individualized obligations/deadlines, full income/expense ledgers and document
  management.
- Unsupported tax situations outside `SUPPORTED_SCOPE.md`.

Normal network flow is exclusively `https://api.taxy.pt`. No direct FactIntWS,
localhost, IP address or contabilidades host is an external-beta route.

## Release blockers

Production signing credentials and signed artifact, proof that the exposed
Cloudflare key was rotated, full Android smoke, archive secret scan, app-wide EN,
accessibility/responsiveness/offline verification, and closure of the e-Fatura
aggregate provenance policy.

