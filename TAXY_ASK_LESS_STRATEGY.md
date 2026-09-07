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

## DM3IRS Mobile discovery addendum

The DM3IRS static analysis creates **no immediate reduction** because entitlement and runtime access remain unconfirmed. It confirms fields for the following ten question groups, which would become reducible after authorization, runtime and product-review gates:

| Question group | Conditional strategy | Required evidence |
|---|---|---|
| residence | PREFILL_AND_CONFIRM | exact field + tax-year semantics |
| civil status / taxation choice | PREFILL_AND_CONFIRM | exact declaration/user field + current-year relevance |
| dependants/household | PREFILL_AND_CONFIRM | exact household response fields |
| employee income | PREFILL_AND_CONFIRM | declaration group returned and field semantics mapped |
| Category A withholding | PREFILL_AND_CONFIRM | exact withholding source and year |
| independent-work presence | PREFILL_AND_CONFIRM | Anexo B presence returned, not merely activity registration |
| activity code/nature | PREFILL_AND_CONFIRM | exact code + reconciliation with curated 90-code mapping |
| Category B revenue | PREFILL_AND_CONFIRM | exact box/amount mapping and user confirmation |
| Category B withholding/contributions/payments | PREFILL_AND_CONFIRM | exact independent components, never a blended total |
| IRS Jovem context | PREFILL_AND_CONFIRM | exact eligibility/option semantics for the selected year |

Counts for this spike: 14 conditional prefill mappings, 10 potentially reducible question groups, **0 newly reducible now**. The existing two e-Fatura reductions remain the only runtime-confirmed ones.
