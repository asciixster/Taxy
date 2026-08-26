# Official assessment fixtures

Esta pasta recebe, no futuro, liquidações oficiais anonimizadas. A release 0.2
não inclui exemplos inventados.

## Como adicionar um caso real

1. Remover NIF, nome, morada, número de declaração e qualquer identificador.
2. Confirmar que o caso está integralmente dentro de `SUPPORTED_SCOPE.md`.
3. Copiar `schema.example.json` para `<ano>-<id-anonimo>.json`.
4. Preencher inputs exatamente como declarados e outputs exatamente como na
   demonstração de liquidação oficial.
5. Registar a versão de `assets/tax_rules/2026.json` usada na comparação.
6. Acrescentar um teste que carregue o fixture e compare todos os cêntimos.

Um caso sem documento oficial verificável não deve ser colocado nesta pasta.
