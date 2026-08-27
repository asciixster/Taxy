# Validation changelog

Registo append-only de alterações motivadas por evidência fiscal. Cada entrada
futura deve incluir data, caso anónimo, classificação, causa, ficheiros/regras
afetados, testes adicionados, revisor e decisão. Nunca incluir dados pessoais.

## 0.5.0 — 2026-08-27

- criado schema oficial v2 com metadados, coerência e resultados por fase;
- imposta igualdade exata de zero cêntimos, sem tolerância global ou por campo;
- adicionada rejeição fail-closed de dados pessoais e fontes não oficiais;
- adicionadas categorias formais de falha e estado inicial `UNKNOWN`;
- criado relatório automático com contagens absolutas de fixtures oficiais e
  cálculos de referência;
- integrado o comparador e export de template no Tax Validation Lab;
- documentada a política de arredondamentos e incertezas abertas;
- nenhuma fórmula ou regra fiscal foi alterada por falta de fixtures oficiais;
- liquidações oficiais incluídas: **0**.

## Modelo para futuras entradas

```text
YYYY-MM-DD · AT-YYYY-CASE-NNN · CATEGORY
Causa:
Alteração:
Regras/ficheiros:
Teste de regressão:
Revisor:
Decisão:
```
