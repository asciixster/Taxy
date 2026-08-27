# Official assessment fixtures

Esta pasta recebe liquidações oficiais anonimizadas. Não contém casos oficiais inventados.

1. Remover todos os identificadores pessoais e da declaração.
2. Confirmar que o caso está em `SUPPORTED_SCOPE.md`.
3. Copiar `schema.example.json` para `<ano>-<id-anonimo>-<modo>.json`.
4. Colar o `TaxSimulation.toJson()` completo em `inputs`, incluindo região,
   `filingMode`, segundo titular, dependentes e IRS Jovem quando aplicável.
5. Transcrever os sete resultados oficiais em cêntimos, incluindo
   `exemptIncomeCents` (zero quando IRS Jovem não foi aplicado).
6. Registar a versão exata das regras e notas de revisão.
7. Executar `flutter test test/official_assessment_fixture_test.dart`.

O loader descobre automaticamente todos os `.json`, exceto o exemplo. Casais
com resultados oficiais nos dois modos usam dois fixtures, um por `filingMode`.
`source` tem obrigatoriamente o valor `OFFICIAL_AT_ASSESSMENT`; referências
manuais pertencem a `../reference_calculations/`.

A diferença permitida é zero cêntimos. Se uma regra legal de arredondamento
justificar diferença, declarar apenas esse campo em `documentedRoundingCents` e
explicar em `notes`; nunca aumentar uma tolerância global.
