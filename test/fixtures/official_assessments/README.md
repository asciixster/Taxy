# Official assessment fixtures

Esta pasta recebe exclusivamente liquidações oficiais da Autoridade Tributária
anonimizadas. A Taxy não inclui casos oficiais inventados: a contagem atual é
publicada, em número absoluto, em `AT_VALIDATION_REPORT.md`.

1. Usar no Validation Lab **Export official fixture template** ou copiar
   `schema.example.json`.
2. Remover NIF, nomes, moradas, IBAN, email, telefone e identificadores da
   declaração/liquidação. O loader rejeita esses dados e nunca os anonimiza
   automaticamente.
3. Usar um `anonymousCaseId` como `AT-2026-CASE-001` e indicar o tipo de
   documento oficial.
4. Confirmar a coerência entre ano, região, estado civil, modo de tributação,
   segundo titular, IRS Jovem e os `inputs` completos.
5. Transcrever em cêntimos inteiros todos os campos apresentados pelo documento.
   Os seis campos de acerto fiscal definidos no schema são obrigatórios; os
   restantes são comparados quando existirem.
6. Executar `dart run tool/generate_at_validation_report.dart` e depois
   `flutter test test/official_assessment_fixture_test.dart`.

Cada campo exige igualdade exata: diferença permitida = **0 cêntimos**. Uma
diferença nunca autoriza uma correção automática do motor. Deve ser investigada
e classificada como `RULE_ERROR`, `ROUNDING_ERROR`, `INPUT_MAPPING_ERROR`,
`FIXTURE_ERROR`, `UNSUPPORTED_SCENARIO` ou `UNKNOWN`.
