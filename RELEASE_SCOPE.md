# Taxy 0.9.0-beta.1 release scope

Release identity: `0.9.0-beta.1+22`. This is the fixed version for this
candidate.

## Feature classification

| Capability | Status | Release boundary |
|---|---|---|
| First-run onboarding and Home | READY | Manual use starts without an AT login. |
| Guided Tax Interview | READY | Branching, persistence, resume and PT/EN included. |
| Category A calculation | READY | Only scenarios admitted by the year-specific supported-scope gate. |
| IRS Jovem | READY | 2025/2026 Category A flow with complete-history and incompatibility gates. |
| Household/dependants | READY | Standard individual, single-parent and complete two-holder cases only. |
| Regional rules | READY | Mainland 2025; Mainland, Madeira and Azores 2026. |
| Guided Review and explainability | READY | Included, excluded, missing and next action are explicit. |
| Reviewed document extraction | BETA | On-device OCR; extracted candidate requires explicit confirmation. |
| e-Fatura | BETA | `api.taxy.pt` read-only flow; unavailable remains unavailable. |
| Historical IRS assistance | BETA | Validated 2024 template only; exact candidates and explicit confirmation. |
| Category B identification | BETA | Identification/history/review only. No Category B calculation. |
| Category B calculation | UNSUPPORTED | Research gate remains `CATEGORY_B_IMPLEMENTATION_READY = NO`. |
| Pensions, foreign, rental, capital and capital-gain income | UNSUPPORTED | Identification makes the estimate unavailable; never silently omitted. |
| IRS submission and all AT writes | UNSUPPORTED | No write transport is exposed. |
| Broader DM3IRS coverage and obscure historical annexes | INTERNAL_ONLY | Research material is not a production promise. |

## Release audit

- Application ID: `pt.taxy.app`.
- Android: minimum API 24, target API 35, compile API 36.
- Manifest: Internet only; no camera or broad-storage permission;
  `allowBackup=false`; FileProvider is non-exported and scoped to capture paths.
- Fiscal engine: production formulas and rule assets are unchanged by this
  release baseline. Existing official/reference fixtures retain zero-cent
  tolerance.
- Localization: PT, PT-PT and EN use an identical ARB key set.
- Backend: not changed in this repository. The app contract remains HTTPS to
  `api.taxy.pt`, with opaque session handling and no fiscal response cache.
- e-Fatura: read-only backend path; no direct FactIntWS normal-flow fallback.
- Historical IRS: three-operation read allowlist, 2024 template only, in-memory
  PDF parsing, no silent current-year import.
- Distribution signing: fail-closed. A signed release artifact requires the
  four `TAXY_ANDROID_*` secrets outside Git; debug signing is never substituted.

## Release persona matrix

| Persona | Expected release result |
|---|---|
| P1 single employee with withholding | Supported estimate |
| P2 married couple, joint taxation | Supported estimate |
| P3 employee with standard dependants | Supported estimate |
| P4 eligible IRS Jovem case | Supported estimate and comparison |
| P5 non-eligible IRS Jovem case | Supported normal estimate |
| P6 Category B identified | Unsupported, no final estimate |
| P7 foreign income identified | Unsupported, no final estimate |
| P8 historical IRS context | Confirm-only candidates |
| P9 document OCR | Reviewed evidence only after confirmation |
| P10 e-Fatura unavailable | Unavailable state, never synthetic zero |

## Release blockers

Only defects matching the explicit release-blocker policy block this branch.
Missing unsupported-category calculations and incomplete optional historical
coverage do not. Operational signing and physical-device evidence are recorded
in `BETA_RELEASE_CHECKLIST.md` rather than bypassed.
