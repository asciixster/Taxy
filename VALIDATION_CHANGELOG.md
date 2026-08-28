# Validation changelog

Registo append-only de alterações motivadas por evidência fiscal. Cada entrada
futura deve incluir data, caso anónimo, classificação, causa, ficheiros/regras
afetados, testes adicionados, revisor e decisão. Nunca incluir dados pessoais.

## 0.8.0 — expansão de validação

- sete referências manuais 2025 Continente adicionadas, todas com provenance e
  audit trail; nenhuma foi classificada como evidência oficial;
- trace alargado com créditos potenciais e efetivos, sem alteração de fórmula;
- fronteiras 2025, arredondamentos e fail-closed reforçados;
- divergências nos novos casos: **0**; bugs fiscais confirmados: **0**;
- alterações de `rulesVersion`: **0**; scope fiscal novo: **0**.

## 0.7.0 — primeiro caso oficial real

- adicionados estados `EXACT`, `PARTIAL_EXACT`, `DIFFERENCE`,
  `INVALID_FIXTURE` e `UNSUPPORTED`;
- caso anónimo `AT-2025-JOINT-A-001`, Categoria A, Continente, casamento,
  tributação conjunta e um dependente standard;
- liquidações oficiais incluídas: **1**;
- resultado: `PARTIAL_EXACT`, com **13/13** campos diretamente comparáveis a
  zero cêntimos de diferença;
- diferenças iniciais em créditos individuais classificadas como
  `INPUT_MAPPING_ERROR`: o trace Taxy expõe o crédito potencial antes do limite
  pela coleta, enquanto o documento mostra a dedução efetivamente utilizada;
- o mapping foi corrigido para `NO_DIRECT_AT_FIELD`; o total das deduções
  efetivamente aplicado continua comparado diretamente;
- divergência confirmada na taxa auditável para rendimento coletável zero:
  AT `125000 ppm`, Taxy antes da correção `0 ppm`;
- classificação: `RULE_ERROR`; causa: o ramo de coletável zero descartava a
  taxa do primeiro escalão apesar de manter corretamente a coleta em zero;
- correção: preservar no resultado e no trace a taxa configurada do primeiro
  escalão; regression test em `test/tax_engine_test.dart`;
- bugs fiscais confirmados e corrigidos: **1**;
- alterações de `rulesVersion`: **0**;
- nenhuma taxa ou fórmula de imposto foi alterada; coleta e saldo permanecem
  inalterados.

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
