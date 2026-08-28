# Taxy 0.8 — Validation Coverage Matrix

`Official evidence` só indica liquidações AT reais anonimizadas. Uma referência
manual nunca é promovida a evidência oficial e usa quality gate `PASS`/`FAIL`.

| Scenario | Official evidence | Manual reference | Status | Known gaps |
|---|---|---|---|---|
| Single Cat A | No | Yes | PASS | Sem liquidação AT real |
| Single Cat A positive tax | No | Yes (2) | PASS | Sem liquidação AT real |
| Married joint | Yes, partial fields (1) | Yes | Official PARTIAL_EXACT; manual PASS | Fases AT não documentadas |
| Married separate | No | Yes | PASS | Sem liquidação AT real |
| Dependents | Yes, one standard dependent | Yes | PARTIAL_EXACT / PASS | Guarda partilhada fora do scope |
| General expenses | AT mostra dedução efetiva zero no caso oficial | Yes | PASS | Sem caso oficial com coleta utilizável |
| Health | AT mostra dedução efetiva zero no caso oficial | Yes | PASS | Sem caso oficial com coleta utilizável |
| Rent | No | Yes | PASS | Sem liquidação AT real |
| PPR | No | Yes | PASS | Sem liquidação AT real |
| Minimum existence | Official case has zero abatimento | Yes | PASS | Fórmula sem caso oficial material |
| IRS Jovem | No | Yes | PASS | Sem liquidação AT real |
| Madeira 2026 | No | Legacy manual/unit boundaries | PASS in suite | Sem liquidação AT real |
| Açores 2026 | No | Legacy manual/unit boundaries | PASS in suite | Sem liquidação AT real |

## Absolute evidence counts

- Official executable cases: 1
- Official EXACT: 0
- Official PARTIAL_EXACT: 1
- Official DIFFERENCE: 0
- Official field comparisons: 13/13 exact
- Manual references: 29 total; 8 use the structured 0.8 runner and 21 remain
  executable through existing dedicated regression suites

Tolerance is always zero cents.
