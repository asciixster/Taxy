# Known limitations — 0.7.15

- Documents and obligations are planned product work, outside this RC scope.
- e-Fatura is strictly read-only and requires network access to `api.taxy.pt`.
- The official provisional-benefit aggregate may remain unavailable when the
  backend cannot provide a semantically equivalent value; unavailable is never
  displayed as a fabricated zero.
- e-Fatura payloads are not retained for stale offline display. Local fiscal
  profile, IRS estimates, income, expenses, scenarios and snapshots continue to
  work offline.
- External distribution remains blocked until Cloudflare key rotation is
  confirmed and the legitimate production Android signing identity is supplied.
