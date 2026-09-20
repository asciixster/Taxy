# Capacidade de retenções e pagamentos por conta

## Resultado

`withholding read available = PARTIAL`.

Há formatos oficiais para declarar retenções e comunicações de pagadores, mas não foi localizado endpoint oficial público que permita ao titular consultar retenções Categoria A/B ou pagamentos por conta. Retenções podem surgir incidentalmente em documentos/declarações, mas não devem ser inferidas de IVA ou total de fatura.

| Tipo | Read source | Estado | Regra Taxy |
|---|---|---|---|
| Categoria A | IRS official prefill Annex A | RUNTIME_READ_CONFIRMED | reviewed official candidate |
| Categoria B | IRS official prefill Annex C field 602 | RUNTIME_READ_CONFIRMED when present | never assume retention for every receipt |
| múltiplos pagadores | nenhum read API | NOT_AVAILABLE | linhas separadas, aggregate only after confirmation |
| pagamentos por conta | Annex C field 603 is mapped but not observed in the tested runtime data | SCHEMA_CONFIRMED | confirm before use |

Prefill futuro exige proveniência `OFFICIAL`, ano/período, tipo e cents; conflito com valor manual deve abrir Review e nunca fazer silent override.
