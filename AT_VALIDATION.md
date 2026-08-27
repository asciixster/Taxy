# Validação com liquidações oficiais da AT

A Taxy separa rigorosamente três níveis de evidência:

1. **testes unitários** — verificam fórmulas, invariantes e fronteiras;
2. **cálculos de referência manual** — casos auditados pela equipa, sempre
   identificados como `MANUALLY_AUDITED_REFERENCE`;
3. **liquidações oficiais anonimizadas** — resultados transcritos de documentos
   da Autoridade Tributária e identificados como `OFFICIAL_AT_ASSESSMENT`.

Só o terceiro nível conta como validação oficial. O número absoluto de casos e
correspondências está em [AT_VALIDATION_REPORT.md](AT_VALIDATION_REPORT.md). A
ausência de casos é mostrada como zero, nunca convertida numa alegação de
precisão.

## Schema e comparação

O schema v3 guarda metadados explícitos (`taxYear`, jurisdição, estado civil,
modo de tributação e `rulesVersion`), os `TaxSimulation` completos e resultados
AT em cêntimos inteiros. Suporta um ou dois titulares, dependentes, deduções,
IRS Jovem, tributação separada/conjunta e as jurisdições/anos que o motor já
suporta.

O loader recusa fixtures v2: o antigo `quotientCents` não distinguia quociente
conjugal de quociente para determinação da taxa. Como não existem fixtures
oficiais no repositório, não há migração automática potencialmente ambígua. Um
caso v2 deve ser retranscrito/revisto para v3 com o documento original.

O runner compara, quando presentes:

- rendimento bruto, dedução específica, rendimento líquido e mínimo de
  existência;
- rendimento coletável, divisor conjugal, rendimento para taxa e quociente para
  taxa como conceitos independentes;
- detalhe dos escalões, coleta antes da isenção, rendimento isento, coleta
  imputada à isenção e coleta após a isenção;
- cada categoria de dedução tipada, limite global, solidariedade, imposto,
  retenções e saldo.

Rendimento coletável, coleta, deduções, imposto, retenções e saldo são
obrigatórios. A tolerância é sempre zero cêntimos. Não existe correção automática
do motor, da fixture ou das regras.

## Workflow de auditoria

1. Introduzir a fixture em `test/fixtures/official_assessments/` através do
   fluxo manual do **Tax Validation Lab**.
2. Correr a suite e confirmar a divergência exata por campo.
3. Validar primeiro o input mapping com [AT_FIELD_MAPPING.md](AT_FIELD_MAPPING.md).
4. Validar a legislação e a versão das regras aplicável ao documento.
5. Identificar se existe bug de arredondamento, regra, fixture ou scope.
6. Corrigir o motor apenas depois de a causa estar confirmada.
7. Criar um teste de regressão mínimo que reproduza o bug.
8. Atualizar `rulesVersion` apenas quando uma regra fiscal tiver sido alterada.
9. Atualizar [VALIDATION_CHANGELOG.md](VALIDATION_CHANGELOG.md) com o helper
   estruturado e a evidência anónima.
10. Gerar novamente o relatório, executar `flutter analyze` e toda a suite.

Não existe correção automática, gravação automática no Git nem aumento de
tolerância global.

## Privacidade

Fixtures com NIF, IBAN, email, telefone, morada, nomes/identificadores pessoais
ou números de declaração/liquidação são rejeitadas. O identificador do caso deve
seguir `AT-<ano>-<id-anónimo>`. A validação é deliberadamente conservadora, mas
não substitui revisão humana: nomes livres não podem ser detetados com segurança.

A aplicação não anonimiza automaticamente. A fixture insegura é recusada e o
ficheiro original não é alterado.

## Classificação de diferenças

- `RULE_ERROR` — regra, parâmetro ou lógica fiscal errada;
- `ROUNDING_ERROR` — fase/arredondamento legal divergente;
- `INPUT_MAPPING_ERROR` — transcrição ou transformação dos inputs;
- `FIXTURE_ERROR` — metadados, fonte ou valor esperado incoerente;
- `UNSUPPORTED_SCENARIO` — a liquidação contém matéria fora do scope;
- `UNKNOWN` — estado inicial obrigatório até análise humana.

Ver também [ROUNDING_POLICY.md](ROUNDING_POLICY.md) e
[VALIDATION_CHANGELOG.md](VALIDATION_CHANGELOG.md). O `FixtureFailure` guarda
campo, esperado, atual, diferença, etapa provável e notas; a categoria inicial
de qualquer divergência continua a ser `UNKNOWN` até triage humano.
