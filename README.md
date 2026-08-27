# taxy.pt — 0.3 IRS Expansion + Multi-Module Foundation

Taxy is a multi-module Portuguese tax and personal finance application. IRS is the first production module.

A aplicação é Android-first, determinística e privada: guarda simulações no dispositivo, não submete declarações e não acede ao Portal das Finanças. Casos fora do contrato validado falham fechados, sem ignorar rendimentos nem aplicar aproximações silenciosas.

## O que a 0.3 entrega

- shell multi-módulo com registo explícito `TaxyModule`; só IRS está ativo;
- IRS 2025 Continente e IRS 2026 Continente, Madeira e Açores;
- seleção central de regras por `ano + região` em `TaxRuleRepository`;
- dois titulares explícitos para casados e unidos de facto;
- comparação determinística entre tributação separada e conjunta;
- despesas próprias por titular e despesas dos dependentes repartidas 50/50 na separada;
- dependentes tipados e motor separado de elegibilidade IRS Jovem;
- scope check inicial, badge de âmbito e Validation Lab com exportação JSON;
- runner automático para futuras liquidações oficiais anonimizadas;
- mais de 200 testes determinísticos.

O cálculo da isenção IRS Jovem ainda não é aplicado à liquidação. A elegibilidade está implementada, mas o englobamento e a imputação da dedução específica ficam `NEEDS_VERIFICATION` até existirem fixtures oficiais. Consulte [SUPPORTED_SCOPE.md](SUPPORTED_SCOPE.md).

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

A única GitHub Action executa `flutter pub get`, `flutter analyze` e `flutter test`. Não gera APK nem AAB.

## Adicionar ano ou região

1. Criar `assets/tax_rules/<ano>/<região>.json`.
2. Registar schema, versão, data, jurisdição, fontes e apenas overrides permitidos.
3. Adicionar o asset ao `pubspec.yaml`.
4. Acrescentar testes de fronteira e scope.
5. Só usar `status: VERIFIED` após revisão fiscal.

## Liquidações oficiais

O loader em `test/official_assessment_fixture_test.dart` descobre os JSON em `test/fixtures/official_assessments/`. A tolerância é zero cêntimos por defeito. Não foram inventadas liquidações oficiais.

Os casos em `test/fixtures/reference_calculations/` são referências manuais independentes, identificadas como tal, e não liquidações da AT. Incluem nove agregados de dois titulares e impedem que os testes se limitem a recalcular expectativas com o próprio motor.

Esta tarefa não gera APK ou AAB. Consulte [ROADMAP.md](ROADMAP.md).
