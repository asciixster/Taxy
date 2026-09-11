# DM3IRS Category B static map

## Fields confirmed in server responses

| Static field | Role | Origin | Category B research value |
|---|---|---|---|
| `codAtividadeIRS` | activity code on user/profile | server response | classification input; reconcile with the curated 90-code table |
| `rendimentoTIndependente` | independent-work gross/aggregate | server response | input/prefill, not coefficient proof |
| `impostoRetidoTIndpendente` | independent-work withholding | server response | withholding input |
| `contribuicoesObgSegSocial` | mandatory Social Security contributions | server response | Article 31/SS input candidate |
| `pagamentosPorConta` / `pagConta` | payments on account | response/calculation breakdown | input and reconciliation candidate |
| `despesasAtividade` | activity expenses | server response | expense-justification input candidate |
| `detalheRendimentos` | detailed income list | server response | component-level trace candidate |
| `codigoRendimentos` | income nature/code | nested response | classification input |
| `rendimentoTableList` | income detail table | nested response | evidence of multiple components |
| `contribuicoesTableList` | contribution detail table | nested response | contribution trace |

Ten Category B-relevant field families were confirmed. The response does not expose a field explicitly named coefficient, Anexo B field 403/404, or an Article 31 adjustment sequence. It is highly useful for prefill, but only medium-useful for the Category B golden harness.

## Product and validation disposition

| Field family | Official role | Current Taxy/harness equivalent | Prefill | Validation | Golden-suitable |
|---|---|---|---|---|---|
| `codAtividadeIRS` | INPUT | `activityCode` | HIGH | coefficient-classification input | NO — does not prove selected coefficient |
| `rendimentoTIndependente` | INPUT/aggregate | Category B gross total | HIGH | reconciles declared gross | NO — not taxable B output |
| `impostoRetidoTIndpendente` | INPUT | Category B withholding | HIGH | withholding reconciliation | YES as official input, not calculation output |
| `contribuicoesObgSegSocial` | INPUT | `socialSecurityPaidCents` | HIGH | contribution input | NO — does not expose adjustment order |
| `pagamentosPorConta` / `pagConta` | INPUT plus calculation trace | payments on account | HIGH | aggregate reconciliation | YES for total payment stage |
| `despesasAtividade` | INPUT | `eligibleExpenseCents` candidate | MEDIUM | expense input | NO — eligible subset semantics need mapping |
| `detalheRendimentos` | INPUT collection | `incomeComponents[]` | HIGH | component trace | NO by itself |
| `codigoRendimentos` | INPUT classification | `nature` / `annexBField` candidate | HIGH | classification bridge | NO until code-to-box mapping is reconciled |
| `rendimentoTableList` | INPUT detail | component gross lines | HIGH | mixed-nature aggregation input | NO by itself |
| `contribuicoesTableList` | INPUT detail | contribution evidence lines | MEDIUM | total/detail reconciliation | NO by itself |

## Official calculation outputs

`infoAgregado` parses server-returned `rendimentoGlobal`, `rendColetavel`, `deducoesEspecificas`, `deducoesColeta`, `coletaTotal`, `coletaLiquida`, `retFonte`, `pagConta`, `impostoPagar`, `impostoReceber`, rates and minimum-existence indicators. The AOT call path shows these are parsed from the SOAP response rather than calculated by a Dart IRS engine.

They are official server-side outputs for the submitted household/input context, but static fixtures cannot establish the exact Category B intermediate coefficient/rounding path. A future authorized, synthetic/sanitized comparison is still required before treating them as golden vectors.

## Mapping safety

The mobile code is an official input signal, not permission to replace the existing 90-code mapping. Code `1519` remains mapped to field 404/coefficient 0.35 in the research harness unless reconciled official evidence proves otherwise. Production code and the Category B worktree were not changed.
