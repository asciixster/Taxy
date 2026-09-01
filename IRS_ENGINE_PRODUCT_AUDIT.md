# IRS engine product audit

## Inputs and provenance

The engine consumes user-entered tax year, territory, filing/household facts,
dependants, gross income, withholding and supported deductions. Repository drafts
are local. e-Fatura data is not silently substituted for IRS inputs. Input
provenance is therefore `USER_ENTERED`; rules are versioned project data; outputs
are `ESTIMATED`.

## Engine and outputs

The deterministic engine covers the scope recorded in `SUPPORTED_SCOPE.md` and
produces taxable income, collection, deductions, withholding and an estimated
refund/amount due. The result breakdown and calculation trace explain the major
steps without claiming to reproduce an official AT assessment.

## Assumptions and gates

- Unsupported situations are blocked or warned by the supported-scope layer.
- Missing required values must not become zero silently.
- IRS Jovem and household paths have dedicated eligibility/reference tests.
- Rounding follows `ROUNDING_POLICY.md`.
- Official assessment fixtures are validation evidence, not production data.

## Product risks and gaps

| Risk | Status | Required action |
|---|---|---|
| Estimate shown as official | Mitigated, audit remains | Keep an explicit estimate label and context near every final amount. |
| Missing data precision | Partial | Consolidate a localized missing-information checklist. |
| Coverage beyond supported scope | Fail-closed | Expand only with sourced rules and reference cases. |
| Duplicate profile facts | Open | Introduce a shared fiscal profile before adding new modules. |
| Imported income provenance | Not implemented | Do not advertise importing. |
| English completeness | Open | Migrate remaining result/wizard strings before English beta. |

No fiscal formulas, expected values or official fixtures were changed in 0.7.11.

