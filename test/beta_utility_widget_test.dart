import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/l10n/app_localizations.dart';
import 'package:taxy_pt/product/product_repository.dart';
import 'package:taxy_pt/product/snapshots_screen.dart';
import 'package:taxy_pt/state/providers.dart';

void main() {
  testWidgets('saved estimates empty state supports English dark large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(
            MemoryProductRepository(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          theme: ThemeData.dark(useMaterial3: true),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const SnapshotsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Saved estimates'), findsOneWidget);
    expect(find.text('No saved estimates'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
