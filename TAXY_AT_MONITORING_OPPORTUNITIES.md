# Oportunidades de monitoring AT

Total: **10**.

| # | Monitor | Availability | Source/stability | Safe cadence |
|---:|---|---|---|---|
| 1 | novas faturas recebidas | possible now | Portal web fragile | manual refresh; later daily max with consent |
| 2 | faturas pendentes por validar | possible now | Portal web fragile | manual refresh; no aggressive polling |
| 3 | alteração de atividade/CAE/CIRS | possible later | ATGo capability, auth unknown | weekly/monthly after official support |
| 4 | alteração de regime IVA/IRS | possible later | ATGo capability, auth unknown | monthly/event-based if source exists |
| 5 | nova fatura emitida/receita | possible later | fatshare issuer, auth unknown | manual/daily after entitlement |
| 6 | nova declaração IRS/estado | possible later | Portal only | daily during filing period only |
| 7 | divergência IRS | possible later | Portal only | conservative, user-triggered |
| 8 | nova liquidação/reembolso | possible later | Portal only | daily after submission, with consent |
| 9 | obrigação pendente | possible later | Portal only; high wording risk | daily/weekly, official timestamp only |
| 10 | pagamento/dívida em falta | possible later | Portal only; sensitive | user-triggered/short cache |

Nenhuma oportunidade justifica background login persistente hoje. Cache e notificações exigem consentimento explícito, revogação simples, deduplicação e ausência de detalhes fiscais no push.
