# Capacidade IVA/VIES

## Resultado

- regime e periodicidade IVA do próprio contribuinte: `UNKNOWN` para Taxy;
- declarações periódicas, saldos, pagamentos e alterações de enquadramento: `UNKNOWN`;
- VIES basic VAT-number validation: `YES`, via serviço oficial da Comissão Europeia, não via identidade AT Taxy.

ATGo afirma consultar o regime IVA no perfil oficial, mas não publica o endpoint/entitlement. A página técnica IVA publica um WSDL para **submissão** de declaração periódica, não consulta. OSS e recapitulativas são formatos de entrega.

VIES apenas confirma se um número está válido para transações intracomunitárias. Não prova regime art. 53.º, periodicidade, OSS, obrigações ou ausência de dívida. Deve ser uma capability separada, conservativamente throttled, sem guardar nome/morada e com tratamento de indisponibilidade nacional/global.
