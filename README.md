# taxy.pt — 0.7 First Official AT Validation

Taxy is a multi-module Portuguese tax and personal finance application. IRS is the first production module.

A aplicação é Android-first, determinística e privada: guarda simulações no dispositivo, não submete declarações e não acede ao Portal das Finanças. Casos fora do contrato validado falham fechados, sem ignorar rendimentos nem aplicar aproximações silenciosas.

## AT connector test harness

Taxy 0.7.1 includes a developer-only, test-environment AT connectivity harness isolated from Flutter and the IRS engine. See [AT_CONNECTOR.md](AT_CONNECTOR.md), [AT_CONNECTOR_SECURITY.md](AT_CONNECTOR_SECURITY.md) and [AT_PROTOCOL_EVIDENCE.md](AT_PROTOCOL_EVIDENCE.md). It proves mTLS/SOAP connectivity only and deliberately blocks production and authenticated calls while critical official protocol details remain unconfirmed.

FactIntWS is researched as a separate protocol. Its offline reconstruction,
evidence levels and live-readiness gates are summarized in
[FACTINTWS_EVIDENCE_MATRIX.md](FACTINTWS_EVIDENCE_MATRIX.md). Tests and CI never
contact FactIntWS, and Taxy never uses the official app's private identity.

## Estado da 0.7

O primeiro caso real anonimizado da AT está integrado como
`AT-2025-JOINT-A-001`: Categoria A, Continente, casal em tributação conjunta e
um dependente standard. Os 13 campos documentalmente comparáveis coincidem a
zero cêntimos e o runner classifica o caso como `PARTIAL_EXACT`. A validação não
alterou o motor nem as regras fiscais.

## Base de validação preservada da 0.6

- schema v3 robusto para liquidações oficiais AT anonimizadas;
- `TaxCalculationTrace` tipado, independente de labels de UI;
- rendimento coletável, divisor conjugal, rendimento para taxa e quociente
  para taxa auditados separadamente;
- comparação exata campo a campo e classificação auditável de diferenças;
- validação de privacidade fail-closed, sem anonimização automática;
- relatório com contagens absolutas: **1 caso oficial** e **22 cálculos de
  referência manual** nesta versão;
- política explícita de arredondamentos e changelog de validação;
- Validation Lab com Taxy / AT / diferença e export de fixture oficial;
- intake developer-only, `sourceNotes`, triage estruturado e mapeamento de
  campos AT, sem alargar as regras fiscais suportadas.

## Base funcional preservada da 0.5

- shell multi-módulo com registo explícito `TaxyModule`; só IRS está ativo;
- IRS 2025 Continente e IRS 2026 Continente, Madeira e Açores;
- seleção central de regras por `ano + região` em `TaxRuleRepository`;
- dois titulares explícitos para casados e unidos de facto;
- comparação determinística entre tributação separada e conjunta;
- despesas próprias por titular e despesas dos dependentes repartidas 50/50 na separada;
- dependentes tipados e elegibilidade IRS Jovem por histórico anual objetivo;
- liquidação com/sem IRS Jovem, incluindo artigo 22.º, retenções e deduções;
- comparação IRS Jovem nos quatro cenários conjugais (A, B, ambos, nenhum),
  em tributação separada e conjunta;
- scope check inicial, badge de âmbito e Validation Lab com exportação JSON;
- runner automático para futuras liquidações oficiais anonimizadas;
- suite determinística e 22 referências manuais auditadas.

O IRS Jovem continua dentro do módulo IRS. A liquidação normal permanece
disponível quando o titular não é elegível; dados insuficientes nunca originam
uma isenção aproximada. Consulte [IRS_JOVEM.md](IRS_JOVEM.md) e
[SUPPORTED_SCOPE.md](SUPPORTED_SCOPE.md).

## Arquitetura

```text
lib/
  app/home/              shell e home modular
  app/modules/           TaxyModule e registry
  modules/irs/           fronteira pública do módulo IRS
  domain/                modelos fiscais legados em migração incremental
  tax_engine/            motores determinísticos e rule repository
  question_engine/       fluxo guiado e scope check
  screens/               resultados e Validation Lab
  state/ navigation/     providers e navegação
  data/                  persistência local atómica
assets/tax_rules/
  2025/base.json
  2025/continent.json
  2026.json
  2026/continent.json
  2026/madeira.json
  2026/azores.json
```

`lib/modules/irs/irs_module.dart` é a fronteira pública. A migração física do código anterior continua incrementalmente para não introduzir um refactor massivo no motor fiscal. Dinheiro é sempre `Money` em cêntimos inteiros e taxas são `ppm`.

## Executar e verificar

```text
flutter pub get
flutter run
flutter analyze
flutter test
```

A única GitHub Action executa `flutter pub get`, regenera o relatório AT,
`flutter analyze` e `flutter test`. Não gera APK nem AAB.

## Adicionar ano ou região

1. Criar `assets/tax_rules/<ano>/<região>.json`.
2. Registar schema, versão, data, jurisdição, fontes e apenas overrides permitidos.
3. Adicionar o asset ao `pubspec.yaml`.
4. Acrescentar testes de fronteira e scope.
5. Só usar `status: VERIFIED` após revisão fiscal.

## Liquidações oficiais

O loader em `test/official_assessment_fixture_test.dart` descobre os JSON em
`test/fixtures/official_assessments/`. A tolerância é sempre zero cêntimos. Não
foram inventadas liquidações oficiais. O relatório é regenerado com:

```text
dart run tool/generate_at_validation_report.dart
```

Os casos em `test/fixtures/reference_calculations/` são referências manuais independentes, identificadas como tal, e não liquidações da AT. A subpasta `irs_jovem/` contém casos com cálculos e expectativas fixas ao cêntimo. Não existem liquidações oficiais reais incluídas nesta release.

Consulte [AT_VALIDATION.md](AT_VALIDATION.md),
[AT_FIELD_MAPPING.md](AT_FIELD_MAPPING.md),
[AT_VALIDATION_REPORT.md](AT_VALIDATION_REPORT.md),
[ROUNDING_POLICY.md](ROUNDING_POLICY.md), [SUPPORTED_SCOPE.md](SUPPORTED_SCOPE.md)
e [ROADMAP.md](ROADMAP.md). Esta tarefa não gera APK ou AAB.
