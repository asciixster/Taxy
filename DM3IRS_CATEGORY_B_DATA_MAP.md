# DM3IRS / Category B data map

## Result

Category B validation usefulness is **MEDIUM** at the offline-discovery stage. The public 2026 Modelo 3 XSD gives a strong official input/form mapping, but zero DM3IRS response fields and zero official calculation outputs are confirmed. It cannot yet close coefficient execution, A+B aggregation, contributions, minimum existence or rounding golden cases.

## Public XSD to research-harness mapping

These eight groups are present in the public declaration schema. They are candidates for reconciliation if `obterDeclaracaoMobileRequest` is later proven to return the same structure.

| Public XSD field/group | Meaning boundary | Category B harness target | Current status |
|---|---|---|---|
| `AnexoBq03C07` | Article 151 activity code | `activityCode` | PUBLIC_XSD_CONFIRMED only |
| Anexo B income field identifiers (401–482) | declared income nature/box | `declarativeField`, `coefficientClass` via official mapping | PUBLIC_XSD_CONFIRMED only |
| `ValorRendimentoPCI` / `RendimentosPCI` | professional/commercial/industrial income values | revenue line cents after exact hierarchy mapping | PUBLIC_XSD_CONFIRMED only |
| `ValorRendimentoASP` / `RendimentosASP` | agricultural/silvicultural income values | out of initial MVP unless explicitly supported | PUBLIC_XSD_CONFIRMED only |
| `RetencoesFonte` | withholding groups | `selfEmploymentWithholdingCents` | PUBLIC_XSD_CONFIRMED only |
| `DespesasEncargos` | expenses/charges groups | expense-justification inputs after exact box mapping | PUBLIC_XSD_CONFIRMED only |
| `AnoRendimentos` | income year | `taxYear` | PUBLIC_XSD_CONFIRMED only |
| `Contribuicoes` | contribution elements occur in the full Modelo 3 schema | no Category B mapping until hierarchy and semantics are proven | PARTIAL / do not import |

## Catalog comparison

`types.xsd` confirms the official type `Cat_M3V2026_CodigoAtividadeArt151CIRS` and Anexo B catalog types. The separate Category B research fixture contains 90 official-form choices and the explicit 1519 → field 404 / coefficient 0.35 regression.

No mobile catalog payload was available, so no value-by-value comparison was performed and the 90-code fixture remains unchanged. A future comparison must report additions, removals, description changes and the 1519 exception; it must never replace the curated mapping silently.

## Input versus official output

| Candidate | Type | Golden-result eligibility |
|---|---|---|
| activity code, box and declared amount | INPUT DATA | useful for fixture prefill, not expected calculation output |
| withholding/contributions/payments on account | INPUT DATA unless response explicitly labels assessed values | not a golden result by itself |
| taxable Category B after adjustments | OFFICIAL CALCULATION OUTPUT only if returned as such | potential golden intermediate |
| global/collectable income, tax, minimum-existence adjustment, final payable/refund | OFFICIAL CALCULATION OUTPUT | potential golden result |

No official calculation output was discovered in this spike.

## Conditional value

- Prefill prior-year Category B facts: high product value, user confirmation required.
- Validate 90-code catalog/version: medium value.
- Close coefficient and expense rules: low until assessed intermediate outputs exist.
- Close A+B/minimum-existence/rounding: impossible from declaration inputs alone.

Production code and the Category B research worktree remain untouched.
