# Validation changelog

Registo append-only de alterações motivadas por evidência fiscal. Cada entrada
futura deve incluir data, caso anónimo, classificação, causa, ficheiros/regras
afetados, testes adicionados, revisor e decisão. Nunca incluir dados pessoais.

## 0.6.0 — infraestrutura de intake e triage

- audit trace tipado; o runner deixou de ler labels de UI;
- schema oficial v3 com conceitos de quociente separados;
- falhas com esperado, atual, diferença, etapa provável e notas;
- helper `ValidationChangelogFormatter` para gerar o formato abaixo;
- bugs confirmados por liquidações oficiais nesta release: **0**;
- liquidações oficiais incluídas: **0**.

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
Case:
AT-YYYY-CASE-NNN

Field:
fieldNameCents

Expected:
123456

Actual:
123454

Difference:
-2 cents

Cause:
ROUNDING_ERROR

Root cause:
...

Fix:
...

Regression test:
...

Rules version before:
...

Rules version after:
...
```

O bloco é adicionado apenas depois de a divergência ter sido confirmada com um
caso real anónimo. O template acima não representa uma liquidação existente.
