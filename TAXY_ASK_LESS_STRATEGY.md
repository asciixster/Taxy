# Taxy Ask Less strategy — DM3IRS impact

Baseline: the current guided interview has 16 questions. The figures below describe the future authorized state, not present capability. A question “disappears” only when current-year official data is present, complete and semantically unambiguous.

| Section | Current | Disappear | Confirm-only | Remain manual | Decision |
|---|---:|---:|---:|---:|---|
| Sobre ti | 3 | 0 | 2 | 1 | residence/region confirm; age stays manual because no birth-date field was confirmed |
| Família | 3 | 0 | 3 | 0 | civil status, joint/separate context and dependant count confirm |
| Trabalho e rendimentos | 3 | 2 | 1 | 0 | employment/self-employment presence may hide; employment amount confirms |
| Outros rendimentos | 3 | 1 | 0 | 2 | pension presence may hide; foreign and rental income remain manual |
| Despesas | 1 | 0 | 1 | 0 | official expense availability still requires review |
| Retenções e pagamentos | 2 | 0 | 2 | 0 | withholding and Social Security confirm |
| Revisão | 1 | 0 | 0 | 1 | final user review remains mandatory |
| **Total** | **16** | **3** | **9** | **4** |  |

## Per-question strategy

| Question | Authorized-data strategy | Reason |
|---|---|---|
| `residentPortugal` | PREFILL_CONFIRM | residence is year-sensitive |
| `region` | PREFILL_CONFIRM | map only recognized official residence codes |
| `age` | ASK_ALWAYS | no confirmed date-of-birth field |
| `civilStatus` | PREFILL_CONFIRM | family status affects calculation |
| `jointTaxation` | PREFILL_CONFIRM | never infer a current choice solely from spouse presence |
| `dependentCount` | PREFILL_CONFIRM | derived from returned records; detailed differences need review |
| `employmentIncome` | HIDE_IF_OFFICIAL | only with complete current-year income group |
| `employmentGrossCents` | PREFILL_CONFIRM | financial amount must be visible before use |
| `selfEmploymentIncome` | HIDE_IF_OFFICIAL | revenue evidence is required; activity registration alone is insufficient |
| `pensionIncome` | HIDE_IF_OFFICIAL | only with complete current-year income group |
| `foreignIncome` | ASK_ALWAYS | no confirmed mobile field safely proves absence |
| `rentalIncome` | ASK_ALWAYS | no confirmed mobile field safely proves absence |
| `expensesReviewed` | PREFILL_CONFIRM | official availability is evidence, not user review |
| `withholdingCents` | PREFILL_CONFIRM | reconcile category details and total |
| `socialSecurityCents` | PREFILL_CONFIRM | fiscal meaning and period must be confirmed |
| `reviewConfirmed` | ASK_ALWAYS | explicit user control is a product safety boundary |

DM3IRS authorization is currently unknown, so actual present-state reduction remains zero. Existing e-Fatura read-only behavior remains independent and available through its current sanctioned path.
