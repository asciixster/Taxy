# Capacidade de perfil do contribuinte/atividade

## Resultado

`taxpayer profile = PARTIAL`; `atividade/CAE/CIRS = YES`; `regime IVA = YES`
through the authenticated Portal read flow.

A página oficial ATGo prova que a AT disponibiliza no seu produto oficial consulta de perfil de atividade, incluindo regime IVA/IRS, CAE/CIRS e datas de início. Isto é evidência de capacidade do ecossistema AT, não de um endpoint público ou entitlement reutilizável por Taxy. Não foi encontrado WSDL/XSD de consulta cadastral pessoal no hub técnico.

| Dado desejado | Evidência | Feasibility | Taxy mapping | Confirmação humana |
|---|---|---|---|---|
| atividade aberta/cessada | Portal integrated profile | RUNTIME_READ_CONFIRMED | `selfEmploymentPresent`, activity state | YES initially |
| data início | table column `Data de Início` | RUNTIME_READ_CONFIRMED | activity start context | YES if it affects an annual rule |
| CAE/CIRS | table columns `Tipo`, `Código`, `Descrição` | RUNTIME_READ_CONFIRMED | activity classification candidate | YES; fiscal classification may still be ambiguous |
| regime IRS simplificado/organizada | integrated-profile section | RUNTIME_READ_CONFIRMED | self-employment regime | YES required |
| regime/periodicidade IVA | integrated-profile sections | RUNTIME_READ_CONFIRMED | FiscalProfile VAT context | YES |
| retenção na fonte/enquadramento | não encontrado como read API | NOT_AVAILABLE | withholding context | ASK_IF_AT_UNKNOWN |

## Gate

Use only the authenticated Portal read flow with consent. Normalize minimum
fields in the backend, require confirmation for current-year facts, and keep
the Portal-specific parser outside Flutter.
