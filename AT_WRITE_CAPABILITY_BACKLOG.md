# Backlog de operações write — documentação apenas

Total: **17 operações write** no catálogo; existem ainda 2 `MIXED` e 1 `UNKNOWN` que também ficam bloqueadas. Esta discovery executou **0 writes**.

| Família/operação | User value | Risk | Confirmation/legal/security | Status |
|---|---|---|---|---|
| fatcore register/change/delete | comunicar/corrigir documentos | HIGH | confirmação explícita, idempotência, certificação, audit | BACKLOG_ONLY |
| FactInt classify invoice | validar setor | HIGH | confirmação item a item e entitlement oficial | BLOCKED |
| FactInt register/delete QR invoice | gerir fatura | HIGH | identidade app não utilizável | BLOCKED |
| FactInt associate revenue | associar receita | HIGH | impacto fiscal direto | BLOCKED |
| Series register/finish/cancel | ATCUD lifecycle | HIGH | software certificado/business workflow | BACKLOG_ONLY |
| Lease register/issue receipt | contrato/recibo | HIGH | efeitos legais e dados de terceiros | BACKLOG_ONLY |
| Transport submit | guia transporte | HIGH | efeito legal/operacional | OUT_OF_SCOPE |
| IES submit | entrega declaração | CRITICAL | signing, confirmation, professional scope | OUT_OF_SCOPE |
| IRC submit | entrega Modelo 22 | CRITICAL | idem | OUT_OF_SCOPE |
| IVA periodic submit | entrega declaração | CRITICAL | idem | OUT_OF_SCOPE |
| ancillary obligations communicate | DMR/modelos | CRITICAL | idem | OUT_OF_SCOPE |

As operações `validate` de IES/IRC são `MIXED`: mesmo que não persistam uma declaração, processam payload de submissão e não são leitura de dados existentes. `obterRecibo` permanece `UNKNOWN` até se provar que não cria/atualiza estado.
