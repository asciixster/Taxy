import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/guided_tax/tax_interview_models.dart';
import 'package:taxy_pt/l10n/app_localizations.dart';
import 'package:taxy_pt/modules/dm3irs/domain/historical_tax_evidence.dart';
import 'package:taxy_pt/modules/dm3irs/infrastructure/dm3irs_history_bridge.dart';
import 'package:taxy_pt/modules/dm3irs/infrastructure/historical_tax_confirmation_repository.dart';
import 'package:taxy_pt/modules/dm3irs/screens/irs_history_prefill_screen.dart';

void main() {
  const native = <Object?, Object?>{
    'available': true,
    'taxYear': 2024,
    'annexes': ['A', 'C', 'H', 'SS'],
    'incomeCategories': ['A', 'B'],
    'categoryBRegime': 'CONTABILIDADE_ORGANIZADA',
    'activityCode': '4015',
    'taxableProfitCents': 12345,
    'withholdingCents': 23456,
    'templateVersion': 'MODELO3_2024_V1',
    'templateFingerprint': 'known-fingerprint',
    'confidence': 'EXACT',
  };

  test('native result creates separate historical evidence', () {
    final evidence = HistoricalTaxEvidence.fromNative(native);
    expect(evidence.taxYear, 2024);
    expect(evidence.suggestions, hasLength(6));
    expect(evidence.source, HistoricalTaxSource.dm3irsOfficialDeclaration);
  });

  test('unknown template fails closed', () {
    expect(
      () => HistoricalTaxEvidence.fromNative({
        ...native,
        'templateVersion': 'UNKNOWN',
      }),
      throwsFormatException,
    );
  });

  test('historical evidence never changes TaxFact without confirmation', () {
    final before = <String, TaxAnswer>{};
    final after = applyHistoricalConfirmations(
      current: before,
      targetYear: 2026,
      confirmations: const [],
    );
    expect(after, isEmpty);
  });

  test('explicit confirmation updates only mapped current-year facts', () {
    final now = DateTime.utc(2026, 9, 10);
    HistoricalTaxConfirmation confirmation(
      HistoricalSuggestionField field,
      Object value,
    ) => HistoricalTaxConfirmation(
      field: field,
      value: value,
      sourceYear: 2024,
      targetYear: 2026,
      userConfirmedAt: now,
      templateFingerprint: 'known-fingerprint',
    );
    final after = applyHistoricalConfirmations(
      current: const {},
      targetYear: 2026,
      confirmations: [
        confirmation(HistoricalSuggestionField.categoryA, true),
        confirmation(HistoricalSuggestionField.categoryB, true),
        confirmation(HistoricalSuggestionField.activityCode, '4015'),
      ],
    );
    expect(
      after.keys,
      containsAll(['employmentIncome', 'selfEmploymentIncome']),
    );
    expect(after, isNot(contains('activityCode')));
    expect(
      after.values.every(
        (item) => item.provenance == TaxFactProvenance.official,
      ),
      isTrue,
    );
  });

  test('year isolation rejects a confirmation for another target year', () {
    final confirmation = HistoricalTaxConfirmation(
      field: HistoricalSuggestionField.categoryA,
      value: true,
      sourceYear: 2024,
      targetYear: 2025,
      userConfirmedAt: DateTime.utc(2026, 9, 10),
      templateFingerprint: 'known-fingerprint',
    );
    expect(
      applyHistoricalConfirmations(
        current: const {},
        targetYear: 2026,
        confirmations: [confirmation],
      ),
      isEmpty,
    );
  });

  test('persisted confirmation contains no raw PDF XML or identifiers', () {
    final confirmation = HistoricalTaxConfirmation(
      field: HistoricalSuggestionField.withholding,
      value: 23456,
      sourceYear: 2024,
      targetYear: 2026,
      userConfirmedAt: DateTime.utc(2026, 9, 10),
      templateFingerprint: 'known-fingerprint',
    );
    final encoded = jsonEncode(confirmation.toJson());
    expect(encoded, isNot(contains('pdf')));
    expect(encoded, isNot(contains('xml')));
    expect(encoded, isNot(contains('declaracao')));
    expect(encoded, isNot(contains('nif')));
    expect(encoded, isNot(contains('603')));
  });

  test('bridge exposes only one history read and no write method', () async {
    const channel = MethodChannel('pt.taxy.test/dm3irs');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'loadHistory') return native;
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final gateway = AndroidDm3IrsHistoryGateway(
      channel: channel,
      enforceAndroid: false,
    );
    final result = await gateway.loadHistory(sourceYear: 2024);
    expect(result?.taxYear, 2024);
    expect(calls.single.method, 'loadHistory');
    expect(
      calls.map((call) => call.method),
      isNot(contains('submeterDeclaracaoMobileRequest')),
    );
  });

  testWidgets(
    'review requires explicit selection and ignore persists nothing',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = MemoryHistoricalTaxConfirmationRepository();
      await _pump(tester, _FakeGateway(), repository);
      await tester.tap(find.byKey(const Key('irs-history-load')));
      await tester.pumpAndSettle();
      final confirm = tester.widget<FilledButton>(
        find.byKey(const Key('irs-history-confirm')),
      );
      expect(confirm.onPressed, isNull);
      await tester.scrollUntilVisible(
        find.byKey(const Key('irs-history-ignore')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('irs-history-ignore')));
      await tester.pumpAndSettle();
      expect(await repository.load(2026), isEmpty);
    },
  );

  testWidgets('review exposes every structurally detected annex', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(
      tester,
      _FakeGateway(),
      MemoryHistoricalTaxConfirmationRepository(),
    );
    await tester.tap(find.byKey(const Key('irs-history-load')));
    await tester.pumpAndSettle();
    expect(find.text('Anexos encontrados'), findsOneWidget);
    for (final annex in ['a', 'c', 'h', 'ss']) {
      expect(find.byKey(Key('irs-history-annex-$annex')), findsOneWidget);
    }
    expect(find.text('Anexo A'), findsOneWidget);
    expect(find.text('Anexo C'), findsOneWidget);
    expect(find.text('Anexo H'), findsOneWidget);
    expect(find.text('Anexo SS'), findsOneWidget);
  });

  testWidgets('selected facts are confirmed with source and target years', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = MemoryHistoricalTaxConfirmationRepository();
    await _pump(tester, _FakeGateway(), repository);
    await tester.tap(find.byKey(const Key('irs-history-load')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('irs-history-categoryA')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('irs-history-confirm')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('irs-history-confirm')));
    await tester.pumpAndSettle();
    final saved = await repository.load(2026);
    expect(saved, hasLength(1));
    expect(saved.single.sourceYear, 2024);
    expect(saved.single.targetYear, 2026);
  });

  testWidgets('screen remains usable at 200 percent text in dark mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 1280);
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(
      tester,
      _FakeGateway(),
      MemoryHistoricalTaxConfirmationRepository(),
      dark: true,
    );
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('irs-history-prefill')), findsOneWidget);
  });

  testWidgets(
    'edited suggestion is the only value persisted after confirmation',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = MemoryHistoricalTaxConfirmationRepository();
      await _pump(tester, _FakeGateway(), repository);
      await tester.tap(find.byKey(const Key('irs-history-load')));
      await tester.pumpAndSettle();
      final withholdingTile = find.byKey(const Key('irs-history-withholding'));
      await tester.scrollUntilVisible(
        withholdingTile,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.descendant(of: withholdingTile, matching: find.byType(Checkbox)),
      );
      final input = find.descendant(
        of: withholdingTile,
        matching: find.byType(TextField),
      );
      await tester.enterText(input, '300,00');
      await tester.scrollUntilVisible(
        find.byKey(const Key('irs-history-confirm')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('irs-history-confirm')));
      await tester.pumpAndSettle();
      final saved = await repository.load(2026);
      expect(saved, hasLength(1));
      expect(saved.single.field, HistoricalSuggestionField.withholding);
      expect(saved.single.value, 30000);
    },
  );

  testWidgets('safe failure category replaces the generic fallback', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeGateway(failure: Dm3IrsFailureKind.network),
      MemoryHistoricalTaxConfirmationRepository(),
    );
    await tester.tap(find.byKey(const Key('irs-history-load')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Não foi possível estabelecer uma ligação segura ao Portal das Finanças. Verifica a rede e tenta novamente.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Não foi possível consultar o IRS anterior. A entrevista manual continua disponível.',
      ),
      findsNothing,
    );
  });

  testWidgets('rejected credentials return focus to editable login', (
    tester,
  ) async {
    final gateway = _FakeGateway(failure: Dm3IrsFailureKind.authentication);
    await _pump(tester, gateway, MemoryHistoricalTaxConfirmationRepository());
    await tester.tap(find.byKey(const Key('irs-history-load')));
    await tester.pumpAndSettle();
    expect(gateway.cleared, isTrue);
    expect(find.byKey(const Key('irs-history-nif')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('irs-history-nif')))
          .focusNode
          ?.hasFocus,
      isTrue,
    );
  });

  testWidgets('stored credentials can be replaced without clearing profile', (
    tester,
  ) async {
    final gateway = _FakeGateway();
    await _pump(tester, gateway, MemoryHistoricalTaxConfirmationRepository());
    await tester.tap(find.byKey(const Key('irs-history-change-login')));
    await tester.pumpAndSettle();
    expect(gateway.cleared, isTrue);
    expect(find.byKey(const Key('irs-history-nif')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('irs-history-nif')))
          .focusNode
          ?.hasFocus,
      isTrue,
    );
  });

  testWidgets('configured client identity can be replaced', (tester) async {
    await _pump(
      tester,
      _FakeGateway(),
      MemoryHistoricalTaxConfirmationRepository(),
    );
    expect(
      find.byKey(const Key('irs-history-client-identity')),
      findsOneWidget,
    );
  });
}

Future<void> _pump(
  WidgetTester tester,
  Dm3IrsHistoryGateway gateway,
  HistoricalTaxConfirmationRepository repository, {
  bool dark = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt', 'PT'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: IrsHistoryPrefillScreen(
        targetYear: 2026,
        gateway: gateway,
        repository: repository,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final class _FakeGateway implements Dm3IrsHistoryGateway {
  _FakeGateway({this.failure});

  final Dm3IrsFailureKind? failure;
  bool secure = false;
  bool cleared = false;

  @override
  Future<void> clear() async => cleared = true;

  @override
  Future<HistoricalTaxEvidence?> loadHistory({required int sourceYear}) async {
    if (failure != null) throw Dm3IrsException(failure!, 'safe failure');
    return HistoricalTaxEvidence.fromNative(const {
      'available': true,
      'taxYear': 2024,
      'annexes': ['A', 'C', 'H', 'SS'],
      'incomeCategories': ['A', 'B'],
      'categoryBRegime': 'CONTABILIDADE_ORGANIZADA',
      'activityCode': '4015',
      'taxableProfitCents': 12345,
      'withholdingCents': 23456,
      'templateVersion': 'MODELO3_2024_V1',
      'templateFingerprint': 'known-fingerprint',
      'confidence': 'EXACT',
    });
  }

  @override
  Future<Dm3IrsReadiness> readiness() async => const Dm3IrsReadiness(
    hasCredentials: true,
    hasClientIdentity: true,
    hasCipherCertificate: true,
  );

  @override
  Future<void> saveCredentials(String nif, String password) async {}

  @override
  Future<bool> selectCipherCertificate() async => true;

  @override
  Future<bool> selectClientIdentity() async => true;

  @override
  Future<void> setScreenSecure(bool enabled) async => secure = enabled;
}
