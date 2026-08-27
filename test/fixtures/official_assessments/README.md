# Official assessment fixtures

Esta pasta recebe exclusivamente liquidações oficiais da Autoridade Tributária
anonimizadas. A Taxy não inclui casos oficiais inventados: a contagem atual é
publicada, em número absoluto, em `AT_VALIDATION_REPORT.md`.

1. Configurar a simulação completa no Validation Lab e rever o audit trace.
2. Introduzir os valores visíveis da demonstração AT na comparação manual.
3. Usar **Export official fixture template** ou copiar
   `schema.example.json`.
4. Remover NIF, nomes, moradas, IBAN, email, telefone e identificadores da
   declaração/liquidação. O loader rejeita esses dados e nunca os anonimiza
   automaticamente.
5. Usar um `anonymousCaseId` como `AT-2026-CASE-001` e indicar o tipo de
   documento oficial.
6. Confirmar a coerência entre ano, região, estado civil, modo de tributação,
   segundo titular, IRS Jovem e os `inputs` completos.
7. Transcrever em cêntimos inteiros todos os campos apresentados pelo documento.
   Os seis campos de acerto fiscal definidos no schema são obrigatórios; os
   restantes são comparados quando existirem.
8. Usar `sourceNotes` apenas para indicar linhas/áreas do documento, sem dados
   identificativos. Consultar `AT_FIELD_MAPPING.md`; não preencher campos
   marcados `NO_DIRECT_AT_FIELD` por inferência.
9. Guardar manualmente o JSON nesta pasta. O Lab nunca escreve no Git.
10. Executar `dart run tool/generate_at_validation_report.dart` e depois
   `flutter test test/official_assessment_fixture_test.dart`.

Cada campo exige igualdade exata: diferença permitida = **0 cêntimos**. Uma
diferença nunca autoriza uma correção automática do motor. Deve ser investigada
e classificada como `RULE_ERROR`, `ROUNDING_ERROR`, `INPUT_MAPPING_ERROR`,
`FIXTURE_ERROR`, `UNSUPPORTED_SCENARIO` ou `UNKNOWN`.

O schema atual é o v3. `maritalQuotient` é o divisor estrutural `1` ou `2`;
`taxableIncomeCents`, `rateDeterminingIncomeCents` e
`rateDeterminingQuotientCents` são valores monetários distintos.
