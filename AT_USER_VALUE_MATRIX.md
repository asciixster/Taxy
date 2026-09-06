# Matriz de valor para o utilizador

| Priority | Capability | Value | Feasibility | Stability | Minimal data | Cache |
|---|---|---|---|---|---|---|
| P1 | perfil de atividade, CAE/CIRS, regimes | VERY_HIGH | AUTH_UNKNOWN | MOBILE_PRIVATE_CONTEXT (ATGo) | estado, códigos, datas, regime | SHORT_CACHE/PERSIST_WITH_CONSENT |
| P1 | faturas recebidas | VERY_HIGH | RUNTIME_READ_CONFIRMED | PORTAL_WEB_FRAGILE | data, valor, IVA, setor/status | SHORT_CACHE/PERSIST_WITH_CONSENT |
| P1 | rendimentos comunicados | VERY_HIGH | NOT_AVAILABLE | UNKNOWN | categoria, período, montante agregado | PERSIST_WITH_CONSENT |
| P1 | retenções/pagamentos por conta | VERY_HIGH | NOT_AVAILABLE | UNKNOWN | tipo, período, montante | PERSIST_WITH_CONSENT |
| P2 | faturas emitidas | VERY_HIGH | SCHEMA_CONFIRMED/AUTH_UNKNOWN | OFFICIAL_API_LEGACY | data, tipo, líquido/IVA/bruto, retenção se existir | PERSIST_WITH_CONSENT |
| P2 | liquidação IRS | VERY_HIGH | NOT_AVAILABLE | PORTAL_WEB_FRAGILE | ano, estado, linhas necessárias, saldo | PERSIST_WITH_CONSENT |
| P2 | declaração IRS vigente | HIGH | NOT_AVAILABLE | PORTAL_WEB_FRAGILE | ano, estado, anexos presentes | SHORT_CACHE |
| P3 | obrigações pendentes | VERY_HIGH | NOT_AVAILABLE | PORTAL_WEB_FRAGILE | tipo, período, estado, data oficial | SHORT_CACHE |
| P3 | pagamentos/dívida | HIGH | NOT_AVAILABLE | PORTAL_WEB_FRAGILE | estado e montantes mínimos; excluir referências até necessidade | NO_STORE/SESSION_ONLY |
| P3 | novas faturas por validar | HIGH | RUNTIME_READ_CONFIRMED | PORTAL_WEB_FRAGILE | count e itens mínimos | SHORT_CACHE |
| P4 | séries/ATCUD | MEDIUM | AUTH_UNKNOWN | OFFICIAL_API_STABLE | série, tipo, estado | SHORT_CACHE |
| P4 | VIES | MEDIUM | SCHEMA_CONFIRMED | OFFICIAL_API_STABLE (UE) | país, número submetido, válido/data | NO_STORE/SHORT_CACHE |

Score recomendado (0–5 por eixo) está refletido no ranking de `TAXY_TOP_10_AT_AUTOMATIONS.md`: maximizar valor/estabilidade/auth e minimizar esforço/privacy risk.
