# Capacidade de retenções e pagamentos por conta

## Resultado

`withholding read available = UNKNOWN`.

Há formatos oficiais para declarar retenções e comunicações de pagadores, mas não foi localizado endpoint oficial público que permita ao titular consultar retenções Categoria A/B ou pagamentos por conta. Retenções podem surgir incidentalmente em documentos/declarações, mas não devem ser inferidas de IVA ou total de fatura.

| Tipo | Read source | Estado | Regra Taxy |
|---|---|---|---|
| Categoria A | nenhum endpoint público encontrado | NOT_AVAILABLE | manual/document confirmed |
| Categoria B | eventualmente documento emitido ou declaração; campo fatshare não confirmado | UNKNOWN | não assumir retenção em cada recibo |
| múltiplos pagadores | nenhum read API | NOT_AVAILABLE | linhas separadas, aggregate only after confirmation |
| pagamentos por conta | Portal pessoal, rota não mapeada | UNKNOWN | não automatizar nesta fase |

Prefill futuro exige proveniência `OFFICIAL`, ano/período, tipo e cents; conflito com valor manual deve abrir Review e nunca fazer silent override.
