# Top 10 automações AT para a Taxy

Ranking combina valor, estabilidade, confiança de autorização, esforço e risco de privacidade. “Release” é recomendação condicional ao gate.

| # | Automation | Source/read-write/runtime | Effort/risk | Recommended release |
|---:|---|---|---|---|
| 1 | sincronizar faturas recebidas e pendentes | Portal acquired-documents; READ; runtime confirmed | LOW-MEDIUM / MEDIUM (web fragile) | current/next hardening |
| 2 | preencher atividade, CAE/CIRS e data de início | ATGo capability; READ semantics; auth unknown | MEDIUM / MEDIUM | after AT authorization discovery |
| 3 | preencher rendimentos comunicados Categoria A | no public read API found | HIGH / HIGH | after official source exists |
| 4 | preencher retenções A/B e pagamentos por conta | no public read API found | HIGH / HIGH | same income release |
| 5 | importar faturação emitida para Categoria B | fatshare issuer query; READ; schema confirmed/auth unknown | MEDIUM / HIGH | first new connector after entitlement |
| 6 | acompanhar liquidação IRS e reembolso/pagamento | Portal only; no mapped contract | HIGH / HIGH | assessment read release |
| 7 | acompanhar estado da Modelo 3/divergências | Portal only | HIGH / HIGH | declaration status release |
| 8 | alertar obrigações pendentes | Portal only; published WS is write | HIGH / CRITICAL wording | obligations release after legal review |
| 9 | acompanhar regime/periodicidade IVA | ATGo regime capability; auth unknown | MEDIUM / MEDIUM | taxpayer profile release |
| 10 | validar estado VIES | official EU VIES; READ; schema confirmed | LOW / LOW-MEDIUM | optional business-profile release |

## Endpoint score summary (5 = best)

| Source | User value | Stability | Auth confidence | Implementation ease | Privacy safety |
|---|---:|---:|---:|---:|---:|
| api.taxy.pt + Portal received reader | 5 | 2 | 5 | 5 | 4 |
| fatshare issued query | 5 | 3 | 2 | 4 | 3 |
| ATGo taxpayer profile | 5 | 1 | 1 | 1 | 4 |
| VIES | 3 | 5 | 5 | 5 | 4 |
| FactIntWS | 4 | 1 | 2 | 3 | 3 |
| personal Portal declaration/assessment | 5 | 2 | 2 | 2 | 2 |

## Primeiro automation pack confirmado

`Received invoices + pending count + normalized invoice explorer + explicit unavailable aggregates`, já através de `api.taxy.pt`. Não incluir perfil, income, withholding, assessment ou obligations até runtime/auth/schema gates. O próximo pacote provável é `Taxpayer profile + issued documents`, mas depende de confirmação formal da AT.
