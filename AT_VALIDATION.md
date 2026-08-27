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

O schema v2 guarda metadados explícitos (`taxYear`, jurisdição, estado civil,
modo de tributação e `rulesVersion`), os `TaxSimulation` completos e resultados
AT em cêntimos inteiros. Suporta um ou dois titulares, dependentes, deduções,
IRS Jovem, tributação separada/conjunta e as jurisdições/anos que o motor já
suporta.

O runner compara, quando presentes:

- rendimento bruto, dedução específica, rendimento líquido e mínimo de
  existência;
- rendimento coletável e quociente;
- coleta, rendimento/coleta isenta e solidariedade;
- deduções à coleta, imposto, retenções e saldo.

Rendimento coletável, coleta, deduções, imposto, retenções e saldo são
obrigatórios. A tolerância é sempre zero cêntimos. Não existe correção automática
do motor, da fixture ou das regras.

## Workflow de auditoria

1. Configurar o caso no **Tax Validation Lab**.
2. Transcrever manualmente os valores AT já anonimizados.
3. Rever Taxy / AT / diferença campo a campo.
4. Exportar `official fixture template` para o clipboard.
5. Rever novamente privacidade, metadados, inputs e fonte.
6. Guardar em `test/fixtures/official_assessments/`.
7. Executar `dart run tool/generate_at_validation_report.dart`.
8. Executar `flutter test test/official_assessment_fixture_test.dart`.
9. Se houver diferença, abrir investigação e classificá-la; nunca ajustar uma
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
[VALIDATION_CHANGELOG.md](VALIDATION_CHANGELOG.md).
