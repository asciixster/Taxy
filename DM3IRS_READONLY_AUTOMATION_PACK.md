# DM3IRS read-only automation pack

## Priority and value ranking

Scores are 1 (low) to 5 (high). Privacy risk 5 is highest risk.

| Rank | Capability | User value | Question reduction | Engine validation | Monitoring | Effort | Privacy risk | Phase |
|---:|---|---:|---:|---:|---:|---:|---:|---|
| 1 | taxpayer + household (`infoUtilizador`, `infoAgregado`) | 5 | 5 | 4 | 1 | 4 | 5 | P1 |
| 2 | official calculation comparison from `infoAgregado` | 5 | 1 | 5 | 2 | 4 | 5 | P3 after safe P1 runtime |
| 3 | declaration status | 4 | 0 | 1 | 5 | 2 | 3 | P2 |
| 4 | receipt metadata | 4 | 0 | 2 | 4 | 3 | 5 | P2 |
| 5 | catalogs | 3 | 1 | 2 | 1 | 2 | 1 | P1, first transport probe |
| 6 | declaration PDF | 2 | 0 | 1 | 2 | 4 | 5 | on-demand only |

## Proposed package

- P1: prove entitlement using catalogs, then profile, then household; project only allow-listed fields into confirmation UI.
- P2: status-change monitoring and on-demand receipt metadata.
- P3: opt-in official-vs-Taxy calculation comparison and sanitized research validation.

No phase depends on a write operation.

## Privacy matrix

| Capability | Minimum fields | Policy |
|---|---|---|
| catalogs | type, normalized entries, version/hash | SHORT_CACHE |
| taxpayer profile | year, residence code, civil status, activity code, safe eligibility flags | USER_CONFIRMED_PERSIST |
| household | year, relationship roles, count, calculation-relevant flags | USER_CONFIRMED_PERSIST; identifiers SESSION_ONLY |
| income/expenses | supported amounts, category/nature, availability, year | USER_CONFIRMED_PERSIST after reconciliation |
| official calculation | seven aligned outputs plus required trace, year and retrieval time | NO_STORE by default; explicit snapshot consent |
| declaration status | normalized state, year, freshness | SHORT_CACHE |
| receipt | availability/status/dates | SHORT_CACHE; identifiers/amount NO_STORE |
| PDF | bytes while user is viewing | NO_STORE |

## Fallback if DM3IRS is unavailable

The product remains functional through the guided manual interview, existing Portal/e-Fatura read-only backend, reviewed document evidence and the local IRS engine. DM3IRS improves effort and validation; it must not become an authentication or availability dependency for the core Taxy experience.

## Implementation gate

`DM3IRS_IMPLEMENTATION_READY = YES` only after explicit entitlement, authorized quality/production path, first read runtime confirmation, terms/privacy review, schema versioning and proof that the product flow has no write dependency. Current state: **NO**.
