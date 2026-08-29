import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/l10n/app_localizations.dart';
import 'package:taxy_pt/l10n/language_controller.dart';
import 'package:taxy_pt/l10n/taxy_formatters.dart';
import 'package:taxy_pt/screens/settings_screen.dart';

void main() {
  test('PT, PT-PT and EN ARB files expose identical key sets', () {
    final pt = _arbKeys('lib/l10n/app_pt.arb');
    final ptPt = _arbKeys('lib/l10n/app_pt_PT.arb');
    final en = _arbKeys('lib/l10n/app_en.arb');
    expect(ptPt, pt);
    expect(en, pt);
    expect(pt, isNot(contains('missing_key')));
  });

  test('unknown system locale falls back safely to pt-PT', () {
    expect(
      resolveTaxyLocale(const Locale('fr'), AppLocalizations.supportedLocales),
      const Locale('pt', 'PT'),
    );
    expect(
      resolveTaxyLocale(
        const Locale('en', 'US'),
        AppLocalizations.supportedLocales,
      ),
      const Locale('en'),
    );
  });

  test('language preference persists without secure storage', () async {
    final store = MemoryLanguagePreferenceStore();
    final first = LanguageController(store);
    await first.select(LanguagePreference.english);
    final restored = LanguageController(store);
    await restored.load();
    expect(restored.preference, LanguagePreference.english);
    expect(restored.locale, const Locale('en'));
  });

  test('local preference store persists only the language choice', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final directory = await Directory.systemTemp.createTemp('taxy-language-');
    const channel = MethodChannel('pt.taxy.app/storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async =>
              call.method == 'getAppDataPath' ? directory.path : null,
        );
    addTearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      await directory.delete(recursive: true);
    });
    final store = LocalLanguagePreferenceStore();
    await store.save(LanguagePreference.english);
    expect(
      await LocalLanguagePreferenceStore().load(),
      LanguagePreference.english,
    );
    expect(directory.listSync(), hasLength(1));
  });

  testWidgets('language selector switches PT, EN and automatic immediately', (
    tester,
  ) async {
    final store = MemoryLanguagePreferenceStore(LanguagePreference.portuguese);
    final controller = LanguageController(store);
    await controller.load();
    await tester.pumpWidget(_settingsApp(controller));
    expect(find.text('Definições'), findsOneWidget);

    await tester.tap(find.byKey(const Key('language-english')));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(store.preference, LanguagePreference.english);

    await tester.tap(find.byKey(const Key('language-portuguese')));
    await tester.pumpAndSettle();
    expect(find.text('Definições'), findsOneWidget);

    tester.binding.platformDispatcher.localeTestValue = const Locale('en');
    await tester.tap(find.byKey(const Key('language-automatic')));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
  });

  testWidgets('plural, EUR and dates follow pt-PT', (tester) async {
    await tester.pumpWidget(
      _probe(
        const Locale('pt', 'PT'),
        (context) => Text(
          '${AppLocalizations.of(context).invoiceCount(2)}|'
          '${TaxyFormatters.euros(context, 123456)}|'
          '${TaxyFormatters.date(context, '2026-08-29')}',
        ),
      ),
    );
    final text = tester.widget<Text>(find.byType(Text)).data!;
    expect(text, contains('2 faturas'));
    expect(text, contains('1 234,56'));
    expect(text, contains('29/08/2026'));
  });

  testWidgets('plural, EUR and dates follow English', (tester) async {
    await tester.pumpWidget(
      _probe(
        const Locale('en'),
        (context) => Text(
          '${AppLocalizations.of(context).invoiceCount(1)}|'
          '${TaxyFormatters.euros(context, 123456)}|'
          '${TaxyFormatters.date(context, '2026-08-29')}',
        ),
      ),
    );
    final text = tester.widget<Text>(find.byType(Text)).data!;
    expect(text, contains('1 invoice'));
    expect(text, contains('€1,234.56'));
    expect(text, contains('Aug 29, 2026'));
  });
}

Set<String> _arbKeys(String path) {
  final json =
      jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
  return json.keys.where((key) => !key.startsWith('@')).toSet();
}

Widget _settingsApp(LanguageController controller) => LanguageScope(
  controller: controller,
  child: ListenableBuilder(
    listenable: controller,
    builder: (context, _) => MaterialApp(
      locale: controller.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeResolutionCallback: resolveTaxyLocale,
      home: SettingsScreen(languageController: controller),
    ),
  ),
);

Widget _probe(Locale locale, WidgetBuilder builder) => MaterialApp(
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: Builder(builder: builder),
);
