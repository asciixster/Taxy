# Official assessment fixtures

Esta pasta recebe liquidações oficiais anonimizadas. Não contém casos oficiais inventados.

1. Remover todos os identificadores pessoais e da declaração.
2. Confirmar que o caso está em `SUPPORTED_SCOPE.md`.
3. Copiar `schema.example.json` para `<ano>-<id-anonimo>.json`.
4. Colar o `TaxSimulation.toJson()` completo em `inputs`.
5. Transcrever os seis resultados oficiais em cêntimos.
6. Registar a versão exata das regras e notas de revisão.
7. Executar `flutter test test/official_assessment_fixture_test.dart`.

O loader descobre automaticamente todos os `.json`, exceto o exemplo. A diferença permitida é zero cêntimos. Se uma regra legal de arredondamento justificar diferença, declarar apenas esse campo em `documentedRoundingCents` e explicar em `notes`; nunca aumentar uma tolerância global.
