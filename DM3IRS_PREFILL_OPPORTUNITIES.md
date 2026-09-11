# DM3IRS conditional prefill opportunities

Static analysis now confirms the named response fields and their consumers. These remain product mappings to apply **only if** Taxy entitlement, runtime behavior and year semantics are confirmed. They do not represent currently readable Taxy data.

| # | Conditional DM3IRS concept | Taxy destination | Provenance if imported | Confirmation | Interview impact |
|---:|---|---|---|---|---|
| 1 | fiscal year/context | active tax year | `OFFICIAL_AT` | YES before switching year | reduce year mismatch |
| 2 | residence status/year | FiscalProfile residence | `OFFICIAL_AT` | YES | prefill residence |
| 3 | marital status | FiscalProfile civil status | `OFFICIAL_AT` | YES | prefill family status |
| 4 | joint/separate declaration choice | FiscalProfile taxation choice | `OFFICIAL_AT` | YES | prefill choice, never force current-year choice |
| 5 | household/dependant count | FiscalProfile dependants | `OFFICIAL_AT` | YES | prefill family composition |
| 6 | Category A presence/gross | Income components | `OFFICIAL_AT` | YES | reduce employee-income questions |
| 7 | Category A withholding | Withholding component A | `OFFICIAL_AT` | YES | reduce withholding entry |
| 8 | Category B presence | `selfEmploymentPresent` | `OFFICIAL_AT` | YES | reduce independent-work question |
| 9 | Article 151/activity code | activity classification candidate | `OFFICIAL_AT` | YES | reduce activity classification |
| 10 | Category B declared revenue by nature | Category B revenue lines | `OFFICIAL_AT` | YES | reduce revenue entry |
| 11 | Category B withholding | Withholding component B | `OFFICIAL_AT` | YES | reduce withholding entry |
| 12 | mandatory contributions | contribution fact | `OFFICIAL_AT` | YES | reduce contribution entry |
| 13 | payments on account | payment component | `OFFICIAL_AT` | YES | reduce payment entry |

Conflict handling remains mandatory: official import must not silently overwrite user- or document-confirmed facts. Prior-year declaration data is historical evidence, not proof of the current-year situation.

The richer static map in `DM3IRS_PREFILL_MAP.md` records 14 mappings. Current result remains 0 runtime-confirmed opportunities and 0 immediately removable questions.
