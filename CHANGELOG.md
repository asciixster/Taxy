# Changelog

## 0.8.6 — IRS history assisted prefill

- Adds a fail-closed, read-only DM3IRS flow for the runtime-confirmed 2024 declaration template.
- Reads the official PDF only in memory and exposes a narrow set of exact historical suggestions.
- Requires explicit confirmation before mapped suggestions can affect the current tax interview.
- Keeps Category B calculations, field 603, unknown templates, automatic imports and all AT writes out of scope.
