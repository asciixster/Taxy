# DM3IRS official calculation outputs

## Provenance boundary

| Classification | Fields/groups | Evidence | Use |
|---|---|---|---|
| INPUT | household records, income totals/details, withholdings, contributions, payments on account, activity expenses, IRS Jovem/SS choices | serialized request and response models | prefill/reconciliation; never golden output by itself |
| SERVER_CALCULATED | `rendimentoGlobal`, `rendColetavel`, `rendDetTaxas`, `deducoesEspecificas`, `deducoesColeta`, `coletaTotal`, `coletaLiquida`, `importanciaApurada`, `parcelaAbater`, `quocienteFamiliar`, `taxa`, `taxaAdicional`, `taxaEfetiva`, `beneficioMunicipal`, `abatimentoMinimoExistencia`, `usaRegraAntigaMinExistencia`, `impostoPagar`, `impostoReceber`, calculation variants | parsed directly from `infoAgregadoMobileResponse` by the official client | possible official comparison/golden fields after authorized runtime capture |
| CLIENT_CALCULATED | none identified in the IRS result path | no local fiscal-formula engine found upstream of these models | do not attribute UI formatting/selection to AT calculation |
| UNKNOWN | exact Category B coefficient result, 403/404 chosen box, Article 31 expense gap, SS excess adjustment, intermediate rounding | no dedicated response fields located | remain blockers |

## Golden-reference mapping

Seven current Category B harness expected outputs have a direct server-side candidate:

| Harness official output | DM3IRS candidate | Acceptance condition |
|---|---|---|
| `globalTaxableIncomeCents` | `rendColetavel` | exact semantic/unit confirmation |
| `minimumExistenceAdjustmentCents` | `abatimentoMinimoExistencia` | scenario proves rule is active |
| `taxBeforeCreditsCents` | `coletaTotal` | verify whether “before credits” aligns with harness stage |
| `taxAfterCreditsCents` | `coletaLiquida` | exact semantic alignment |
| `totalWithholdingCents` | `retFonte` | reconcile A+B component totals |
| `finalPayableCents` | `impostoPagar` | mutually exclusive with refund |
| `finalRefundableCents` | `impostoReceber` | mutually exclusive with payable |

Additional trace fields such as `rendimentoGlobal`, `deducoesEspecificas`, `deducoesColeta`, `pagConta` and rates can identify the first divergent stage, but they are not direct fields in the current harness schema.

## Safety

Static discovery proves server-response provenance, not a usable golden case. A golden requires an authorized read, known synthetic/fully anonymized inputs, tax-year match and zero-cent reconciliation. Raw SOAP, taxpayer identifiers and official PDF documents must not enter fixtures.
