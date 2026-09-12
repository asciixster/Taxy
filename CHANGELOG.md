# Changelog

## 0.9.0-beta.1 — Release candidate

- Consolidates the guided interview, supported Category A calculation, IRS
  Jovem, document capture, Guided Review and read-only e-Fatura experience.
- Includes confirm-only assistance from the validated 2024 IRS declaration;
  historical evidence never changes current-year facts silently.
- Keeps Category B and other unsupported income scenarios fail-closed and out
  of the final estimate.
- Produces build 22 as the first external 0.9 beta candidate.

## 0.8.6 — IRS history assisted prefill

- Adds a fail-closed, read-only DM3IRS flow for the runtime-confirmed 2024 declaration template.
- Reads the official PDF only in memory and exposes a narrow set of exact historical suggestions.
- Requires explicit confirmation before mapped suggestions can affect the current tax interview.
- Keeps Category B calculations, field 603, unknown templates, automatic imports and all AT writes out of scope.
