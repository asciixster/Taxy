# Official AT prefill

Taxy can now read the official IRS prefilled declaration through a one-shot,
read-only backend connector.

## User flow

1. The user chooses **Import from AT**.
2. Taxy sends the credentials over HTTPS to `api.taxy.pt` for that request.
3. The isolated worker authenticates on the official Portal flow and reads the
   prefilled declaration.
4. The worker returns only a normalized, identifier-free model.
5. Taxy shows the values as candidates.
6. Only fields explicitly selected and confirmed by the user become current
   year answers with official provenance.

## Current normalized scope

- annex presence: A, C and H;
- household member count (context only);
- Category A rows and exact-cent totals for gross income, IRS withholding,
  Social Security contributions and union dues;
- Category B presence, organized-accounting regime and fields 601–604 when
  populated.

Category B detection makes the estimate fail closed. It does not enable the
Category B calculation engine.

## Security boundary

- read-only endpoint: `POST /v1/irs/prefill`;
- no AT write route exists in the dedicated worker allowlist;
- credentials are not returned to Flutter or stored as a reusable session;
- raw official payloads and taxpayer identifiers are not returned;
- the app rejects responses containing identifier or credential-like keys;
- the screen is protected from screenshots on Android;
- every fiscal candidate requires explicit confirmation.
