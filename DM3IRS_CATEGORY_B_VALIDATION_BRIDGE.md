# DM3IRS → Category B validation bridge

This document reads the Category B harness at its current worktree commit without changing it.

| DM3IRS server field | Harness expected/input field | What it can validate | Limitation |
|---|---|---|---|
| `codAtividadeIRS`, `codigoRendimentos` | input `activityCode`, `annexBField` candidate | classification setup | no explicit 403/404 result; coefficient remains unproven |
| `rendimentoTIndependente`, detail list | input gross/components | gross aggregation | no separate taxable B result |
| `contribuicoesObgSegSocial` | input `socialSecurityPaidCents` | input equality | cannot validate SS excess/order alone |
| `despesasAtividade` | input `eligibleExpenseCents` candidate | expense presence/total | eligible-expense semantics need exact code mapping |
| `retFonte` plus withholding details | `totalWithholdingCents` | A+B withholding consolidation | category totals must reconcile |
| `rendColetavel` | `globalTaxableIncomeCents` | global taxable income | cannot isolate Category B coefficient stage |
| `abatimentoMinimoExistencia` | `minimumExistenceAdjustmentCents` | minimum-existence effect | eligibility/order still needs discriminating case |
| `coletaTotal` | `taxBeforeCreditsCents` candidate | pre-credit tax stage | semantic label must be runtime-confirmed |
| `coletaLiquida` | `taxAfterCreditsCents` | post-credit tax | exact stage must be confirmed |
| `impostoPagar` / `impostoReceber` | final payable/refundable | final result | can hide offsetting intermediate errors |
| calculation rates and variants | future intermediate trace | first-divergence diagnosis/rounding | no explicit per-line rounding trace |

## Coverage decision

- coefficient: PARTIAL; inputs only, no direct official coefficient output.
- taxable Category B: NOT DIRECTLY VALIDATABLE; only global taxable income is exposed.
- contributions: PARTIAL; input confirmed, adjustment/order absent.
- minimum existence: DIRECT CANDIDATE, subject to authorized discriminating case.
- withholding: DIRECT CANDIDATE.
- final result: DIRECT CANDIDATE.
- rounding: PARTIAL; deltas can be detected, exact first rounding stage cannot always be located.

The bridge makes 7 current harness expected outputs potentially usable. It does not satisfy the Category B implementation gate until authorized official cases reconcile at zero cents.
