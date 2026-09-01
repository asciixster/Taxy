# Product completion evidence

0.7.12 introduces a persisted product-state schema separate from the tax engine.
The global fiscal profile and active year are the source for initial rule selection
and local ledgers. Completing an IRS simulation synchronizes only factual profile
attributes; ledger values are never injected into the calculation automatically.

Income and expense entries are local supporting records with explicit provenance
and status. Duplicate identities are flagged for review and never auto-deleted.
e-Fatura evidence remains separate and read-only.

Settings now include persisted appearance, a plain-language privacy centre,
sanitized diagnostics and a payload-free feedback template. Normal API flow remains
restricted to `https://api.taxy.pt` contract v1.

The pass deliberately does not add documents, obligations, tax rules, external
writes, derived e-Fatura aggregates or a release artifact. Full legacy IRS/Home
localization and real-device accessibility/offline smoke remain RC blockers.
