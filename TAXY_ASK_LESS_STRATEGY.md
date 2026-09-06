# Estratégia Ask Less

Audit às áreas de perguntas atuais, agrupado por facto. **11 perguntas/grupos podem ser removidos ou reduzidos** se as fontes correspondentes passarem o gate; 2 já são reduzíveis com e-Fatura recebido.

| Pergunta/facto | Strategy | Redução | Gate |
|---|---|---:|---|
| tens despesas/faturas e-Fatura? | AUTO_IMPORT_READONLY | 1 | current runtime |
| existem faturas pendentes? | AUTO_IMPORT_READONLY | 1 | current runtime |
| trabalhas por conta própria? | PREFILL_AND_CONFIRM | 1 | taxpayer profile auth |
| quando iniciou/cessou atividade? | PREFILL_AND_CONFIRM | 1 | taxpayer profile auth |
| tipo/código de atividade | PREFILL_AND_CONFIRM | 1 | CAE/CIRS auth + mapping |
| regime simplificado/organizada | PREFILL_AND_CONFIRM | 1 | IRS regime auth |
| enquadramento IVA | PREFILL_AND_CONFIRM | 1 | VAT profile auth |
| faturação bruta independente | PREFILL_AND_CONFIRM | 1 | issued documents auth + complete interval |
| rendimentos de trabalho | PREFILL_AND_CONFIRM | 1 | reported-income source |
| retenção Categoria A | PREFILL_AND_CONFIRM | 1 | withholding source |
| retenção Categoria B | PREFILL_AND_CONFIRM | 1 | withholding/source semantics |
| estado civil/dependentes | ASK_IF_AT_UNKNOWN | 0 | no source discovered |
| residência fiscal | ASK_ALWAYS initially | 0 | high-risk/year-specific |
| rendimentos estrangeiros | ASK_ALWAYS | 0 | no supported source |
| contabilidade organizada/complexidade | ASK_IF_AT_UNKNOWN | 0 | never infer solely from invoices |

`PREFILL_AND_CONFIRM` is the default for facts that affect tax rules. `AUTO_IMPORT_READONLY` is limited to observational data whose meaning is stable and conflict-safe.
