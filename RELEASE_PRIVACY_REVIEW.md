# Release privacy review — 0.9.0-beta.1

Status: PASS for the implemented application boundary.

## What stays on the device

- interview answers, normalized fiscal profile, saved estimates and explicit
  evidence confirmations;
- document-extraction temporary data in encrypted app-private storage;
- Portal credentials protected by Android Keystore-backed storage;
- minimal confirmed historical fields, source/target year and provenance.

## What reaches the Taxy backend

The e-Fatura flow sends credentials over HTTPS to `api.taxy.pt` only during
connection. Flutter receives an opaque session capability, never the returned
credentials. Fiscal responses are not implemented as a persistent Flutter
cache. The backend was not changed in this release.

## What reaches the AT

- e-Fatura read-only requests through the Taxy backend;
- the DM3IRS 2024 historical flow through an explicit three-operation read
  allowlist and a user-selected legitimate client identity.

AT write operations are absent from the product transport: total writes in the
release verification is zero.

## Ephemeral data

- raw captured documents are deleted after confirmation/cancellation/expiry;
- the historical IRS SOAP payload, declaration identifiers, PDF bytes and OCR
  text remain in memory only and are cleared after parsing;
- the historical PDF is never stored as an application file;
- sensitive screens use `FLAG_SECURE`.

## Logging and analytics

No fiscal amounts, NIF, credentials, tokens, filenames, document content,
historical identifiers or OCR text are allowed in logs, analytics or crash
payloads. Events are limited to sanitized operational categories.

## External security action

`SECURITY_ACTION_REQUIRED`: confirm outside this repository that the previously
exposed Cloudflare global API key was revoked/rotated. The old credential is not
used and no matching credential may be present in source or release artifacts.
