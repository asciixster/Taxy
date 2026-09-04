import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taxy_pt/data/simulation_repository.dart';
import 'package:taxy_pt/domain/models.dart';
import 'package:taxy_pt/domain/money.dart';
import 'package:taxy_pt/main.dart';
import 'package:taxy_pt/l10n/app_localizations.dart';
import 'package:taxy_pt/question_engine/question_engine.dart';
import 'package:taxy_pt/tax_engine/tax_rules.dart';
import 'package:taxy_pt/product/product_repository.dart';

void main() {
  testWidgets('a aplicação arranca', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(MemorySimulationRepository()),
          productRepositoryProvider.overrideWithValue(
            MemoryProductRepository(),
          ),
        ],
        child: const TaxyApp(),
      ),
    );
    await _pumpAsyncFrames(tester);
    expect(find.byType(TaxyApp), findsOneWidget);
    expect(find.text('Começar análise guiada'), findsOneWidget);
  });

  testWidgets('home identifica e retoma um rascunho guardado', (tester) async {
    final repository = MemorySimulationRepository();
    final rules = TaxRuleSet.fromJsonString(
      File('assets/tax_rules/2026.json').readAsStringSync(),
    );
    await repository.saveDraft({
      'schemaVersion': 1,
      'stepIndex': 1,
      'draft': TaxDraft().toJson(),
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repository),
          rulesProvider.overrideWith((ref) async => rules),
          simulationsProvider.overrideWith((ref) async => const []),
          simulationDraftProvider.overrideWith(
            (ref) async => repository.loadDraft(),
          ),
        ],
        child: const TaxyApp(),
      ),
    );
    await _pumpAsyncFrames(tester);

    expect(find.text('Continuar de onde ficaste'), findsOneWidget);
  });

  testWidgets('wizard recupera o passo validado após reabrir', (tester) async {
    final repository = MemorySimulationRepository();
    final rules = TaxRuleSet.fromJsonString(
      File('assets/tax_rules/2026.json').readAsStringSync(),
    );
    await repository.saveDraft({
      'schemaVersion': 1,
      'stepIndex': 1,
      'draft': (TaxDraft()..taxYear = 2025).toJson(),
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(home: WizardScreen(rules: rules)),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Viveste fiscalmente em Portugal todo o ano?'),
      findsOneWidget,
    );
    expect(find.textContaining('2/'), findsOneWidget);
  });

  testWidgets('UI oferece casado e união de facto no scope check', (
    tester,
  ) async {
    await _pumpWizard(tester);
    await _continue(tester, 3);
    expect(find.text('Não casado/a nem unido/a de facto'), findsOneWidget);
    expect(find.text('Casado/a'), findsOneWidget);
    expect(find.text('União de facto'), findsOneWidget);
  });

  testWidgets('residência parcial é bloqueada antes do cálculo', (
    tester,
  ) async {
    await _pumpWizard(tester);
    await _continue(tester, 1);
    await tester.tap(find.text('Não'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(
      find.text('Ainda não suportado: residência fiscal parcial.'),
      findsOneWidget,
    );
  });

  for (final region in ['Madeira', 'Açores']) {
    testWidgets('$region 2025 é bloqueado antes do cálculo', (tester) async {
      await _pumpWizard(tester);
      await tester.tap(find.text('2025'));
      await _continue(tester, 2);
      await tester.tap(find.text(region));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Ainda não suportado: Madeira e Açores em 2025 permanecem NEEDS_VERIFICATION.',
        ),
        findsOneWidget,
      );
    });
  }

  testWidgets('resultado conjugal mostra os dois valores e linguagem neutra', (
    tester,
  ) async {
    final rules = TaxRuleSet.fromJsonString(
      File('assets/tax_rules/2026.json').readAsStringSync(),
    );
    final now = DateTime.utc(2026);
    final simulation = TaxSimulation(
      id: 'ui-couple',
      name: 'UI couple',
      createdAt: now,
      updatedAt: now,
      profile: const TaxpayerProfile(
        taxYear: 2026,
        age: 40,
        civilStatus: CivilStatus.married,
        dependentAges: [],
        fullYearResident: true,
        region: TaxRegion.continent,
        filingMode: FilingMode.joint,
      ),
      income: const EmploymentIncome(
        entryMode: IncomeEntryMode.annual,
        gross: Money.fromCents(8000000),
        withholding: Money.fromCents(1000000),
        socialSecurity: Money.fromCents(880000),
      ),
      deductions: const DeductionInput(),
      secondaryTaxpayer: const TaxpayerInput(
        id: 'B',
        age: 42,
        income: EmploymentIncome(
          entryMode: IncomeEntryMode.annual,
          gross: Money.fromCents(2000000),
          withholding: Money.fromCents(200000),
          socialSecurity: Money.fromCents(220000),
        ),
        deductions: DeductionInput(),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'PT'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: ResultScreen(simulation: simulation, rules: rules),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Comparação de tributação'), findsOneWidget);
    expect(find.text('Tributação separada'), findsOneWidget);
    expect(find.text('Tributação conjunta'), findsWidgets);
    expect(find.text('Diferença'), findsOneWidget);
    expect(find.text('Opção estimada mais favorável'), findsOneWidget);
    expect(find.textContaining('menor imposto estimado'), findsOneWidget);
    expect(
      find.textContaining('não substitui a liquidação oficial'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Ver cálculo detalhado'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Ver cálculo detalhado'), findsOneWidget);
  });

  testWidgets('home compacta funciona em ecrã pequeno e dark mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final rules = TaxRuleSet.fromJsonString(
      File('assets/tax_rules/2026.json').readAsStringSync(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(MemorySimulationRepository()),
          rulesProvider.overrideWith((ref) async => rules),
          simulationsProvider.overrideWith((ref) async => const []),
          simulationDraftProvider.overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          locale: const Locale('pt', 'PT'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: ThemeData.dark(useMaterial3: true),
          home: const HomeScreen(),
        ),
      ),
    );
    await _pumpAsyncFrames(tester);

    expect(find.text('Outros simuladores · Em breve'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpWizard(WidgetTester tester) async {
  final rules = TaxRuleSet.fromJsonString(
    File('assets/tax_rules/2026.json').readAsStringSync(),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(MemorySimulationRepository()),
      ],
      child: MaterialApp(home: WizardScreen(rules: rules)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpAsyncFrames(WidgetTester tester) async {
  for (var index = 0; index < 10; index++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _continue(WidgetTester tester, int times) async {
  for (var i = 0; i < times; i++) {
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
  }
}
