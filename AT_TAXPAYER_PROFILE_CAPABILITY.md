# Capacidade de perfil do contribuinte/atividade

## Resultado

`taxpayer profile = UNKNOWN`; `atividade/CAE/CIRS = UNKNOWN`; `regime IVA = UNKNOWN` para a Taxy.

A página oficial ATGo prova que a AT disponibiliza no seu produto oficial consulta de perfil de atividade, incluindo regime IVA/IRS, CAE/CIRS e datas de início. Isto é evidência de capacidade do ecossistema AT, não de um endpoint público ou entitlement reutilizável por Taxy. Não foi encontrado WSDL/XSD de consulta cadastral pessoal no hub técnico.

| Dado desejado | Evidência | Feasibility | Taxy mapping | Confirmação humana |
|---|---|---|---|---|
| atividade aberta/cessada | ATGo public product | AUTH_UNKNOWN | `selfEmploymentPresent`, activity state | YES inicialmente |
| data início/cessação | ATGo public product | AUTH_UNKNOWN | activity start context | YES se afeta regra anual |
| CAE/CIRS | ATGo public product | AUTH_UNKNOWN | activity classification candidate | YES; classificação fiscal pode ser ambígua |
| regime IRS simplificado/organizada | ATGo wording “regime IRS” sem schema | AUTH_UNKNOWN | self-employment regime | YES obrigatório |
| regime/periodicidade IVA | regime IVA publicamente descrito; periodicidade não confirmada | AUTH_UNKNOWN | FiscalProfile VAT context | YES |
| retenção na fonte/enquadramento | não encontrado como read API | NOT_AVAILABLE | withholding context | ASK_IF_AT_UNKNOWN |

## Gate

Não automatizar tráfego ATGo nem reproduzir contexto móvel. Próximo passo legítimo: solicitar à AT documentação/entitlement de consulta cadastral para software do próprio contribuinte, ou mapear uma página Portal estritamente read-only com consentimento e uma só prova controlada.
