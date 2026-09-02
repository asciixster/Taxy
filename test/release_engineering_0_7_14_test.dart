import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/l10n/app_localizations.dart';
import 'package:taxy_pt/l10n/language_controller.dart';
import 'package:taxy_pt/l10n/theme_controller.dart';
import 'package:taxy_pt/modules/efatura/application/efatura_read_only_service.dart';
import 'package:taxy_pt/product/app_failure.dart';
import 'package:taxy_pt/product/ledger_screens.dart';
import 'package:taxy_pt/product/product_repository.dart';
import 'package:taxy_pt/product/snapshots_screen.dart';
import 'package:taxy_pt/screens/settings_screen.dart';
import 'package:taxy_pt/state/providers.dart';

void main() {
  test('0.7.14 release identity is consistent', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final diagnostics = File('lib/core/internal_beta_build_info.dart')
        .readAsStringSync();
    expect(pubspec, contains('version: 0.7.14+14'));
    expect(diagnostics, contains("defaultValue: '0.7.14'"));
    expect(diagnostics, contains("defaultValue: '14'"));
  });

  test('production Android registers no direct FactIntWS bridge', () {
    final activity = File(
      'android/app/src/main/kotlin/pt/taxy/app/MainActivity.kt',
    ).readAsStringSync();
    expect(activity, isNot(contains('EfaturaRuntimeBridge')));
    expect(activity, isNot(contains('FactIntWs')));
    expect(activity, contains('setScreenSecure'));
    expect(activity, contains('FLAG_SECURE'));
  });

  test('normal Flutter path is api.taxy.pt-only and read-only', () {
    final sources = <String>[
      'lib/main.dart',
      'lib/modules/efatura/infrastructure/efatura_backend_bridge.dart',
      'lib/modules/efatura/infrastructure/efatura_api_configuration.dart',
    ].map((path) => File(path).readAsStringSync()).join('\n');
    expect(sources, contains('https://api.taxy.pt/'));
    expect(sources, isNot(contains('servicos.portaldasfinancas.gov.pt')));
    expect(sources, isNot(contains('localhost')));
    expect(sources, isNot(contains('clientes.contabilidades.pt')));
    for (final operation in <String>[
      'classificarFaturas',
      'registarFaturaQrCode',
      'eliminarFaturaQrCode',
      'associarReceita',
    ]) {
      expect(sources.toLowerCase(), isNot(contains(operation.toLowerCase())));
    }
  });

  test('experimental feature remains disabled by default', () {
    expect(EfaturaFeatureFlags.experimental, isFalse);
    final source = File(
      'lib/modules/efatura/application/efatura_read_only_service.dart',
    ).readAsStringSync();
    expect(source, contains("defaultValue: false"));
  });

  test('shared error taxonomy covers the release contract', () {
    expect(
      AppFailureKind.values.toSet(),
      containsAll(<AppFailureKind>{
        AppFailureKind.networkOffline,
        AppFailureKind.timeout,
        AppFailureKind.authenticationRequired,
        AppFailureKind.authorizationDenied,
        AppFailureKind.serviceUnavailable,
        AppFailureKind.serverError,
        AppFailureKind.malformedData,
        AppFailureKind.localDataError,
        AppFailureKind.unknown,
      }),
    );
    expect(
      AppFailureKind.values
          .map((kind) => AppFailure(kind).diagnosticCode)
          .toSet()
          .length,
      AppFailureKind.values.length,
    );
  });

  test('tracked release inputs contain no private-key or token material', () {
    const forbiddenExtensions = <String>{
      '.pfx',
      '.p12',
      '.pkcs12',
      '.key',
      '.jks',
      '.keystore',
    };
    final roots = <Directory>[
      Directory('lib'),
      Directory('android/app/src'),
      Directory('assets'),
    ];
    final files = roots
        .where((root) => root.existsSync())
        .expand((root) => root.listSync(recursive: true))
        .whereType<File>();
    for (final file in files) {
      final normalized = file.path.toLowerCase();
      expect(
        forbiddenExtensions.any(normalized.endsWith),
        isFalse,
        reason: 'Private release material: ${file.path}',
      );
      if (normalized.endsWith('.dart') ||
          normalized.endsWith('.kt') ||
          normalized.endsWith('.xml')) {
        final text = file.readAsStringSync();
        expect(text, isNot(contains('BEGIN PRIVATE KEY')));
        expect(text, isNot(matches(RegExp(r'cfk_[A-Za-z0-9]{24,}'))));
      }
    }
  });

  for (final screen in <(String, Widget)>[
    ('Income', const IncomeScreen()),
    ('Expenses', const ExpensesScreen()),
    ('Snapshots', const SnapshotsScreen()),
  ]) {
    testWidgets('${screen.$1} fits 320x640 at 200% text in dark mode', (
      tester,
    ) async {
      await _compactSurface(tester);
      await tester.pumpWidget(_productApp(screen.$2));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Settings fits 320x640 at 200% text and remains operable', (
    tester,
  ) async {
    await _compactSurface(tester);
    final language = LanguageController(
      MemoryLanguagePreferenceStore(LanguagePreference.english),
      initial: LanguagePreference.english,
    );
    final theme = ThemeController(
      MemoryThemePreferenceStore(ThemePreference.dark),
      initial: ThemePreference.dark,
    );
    addTearDown(language.dispose);
    addTearDown(theme.dispose);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData.dark(useMaterial3: true),
        builder: _largeText,
        home: SettingsScreen(
          languageController: language,
          themeController: theme,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _compactSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(320, 640));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Widget _productApp(Widget home) => ProviderScope(
  overrides: [
    productRepositoryProvider.overrideWithValue(MemoryProductRepository()),
  ],
  child: MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData.dark(useMaterial3: true),
    builder: _largeText,
    home: home,
  ),
);

Widget _largeText(BuildContext context, Widget? child) => MediaQuery(
  data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
  child: child!,
);
