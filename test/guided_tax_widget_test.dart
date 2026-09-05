import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/guided_tax/guided_tax_screen.dart';
import 'package:taxy_pt/guided_tax/tax_interview_repository.dart';
import 'package:taxy_pt/l10n/app_localizations.dart';
import 'package:taxy_pt/product/product_models.dart';
import 'package:taxy_pt/product/product_repository.dart';
import 'package:taxy_pt/state/providers.dart';
import 'package:taxy_pt/domain/models.dart';
import 'package:taxy_pt/domain/money.dart';

void main() {
  testWidgets('guided flow is localized and usable at 200% text scale', (
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
            MemoryProductRepository(ProductState.initial(2026)),
          ),
          taxInterviewRepositoryProvider.overrideWithValue(
            MemoryTaxInterviewRepository(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('pt', 'PT'),
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            GlobalMaterialLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const GuidedTaxScreen(taxYear: 2026),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Foste residente fiscal em Portugal durante todo o ano de 2026?',
      ),
      findsOneWidget,
    );
    expect(find.text('Porque perguntamos isto'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English flow uses plain language and dark mode', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(
            MemoryProductRepository(ProductState.initial(2026)),
          ),
          taxInterviewRepositoryProvider.overrideWithValue(
            MemoryTaxInterviewRepository(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          theme: ThemeData.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const GuidedTaxScreen(taxYear: 2026),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Were you a Portuguese tax resident throughout 2026?'),
      findsOneWidget,
    );
    expect(find.text('Why we ask this'), findsOneWidget);
  });

  testWidgets('numeric input keeps every typed character across rebuilds', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(
            MemoryProductRepository(ProductState.initial(2026)),
          ),
          taxInterviewRepositoryProvider.overrideWithValue(
            MemoryTaxInterviewRepository(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('pt', 'PT'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const GuidedTaxScreen(taxYear: 2026),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sim'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Portugal continental'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '35');
    await tester.pump();

    expect(find.text('35'), findsOneWidget);
  });

  testWidgets(
    'same-year profile and ledger prefill reduce repeated questions',
    (tester) async {
      final state = ProductState(
        profile: const FiscalProfile(
          activeTaxYear: 2026,
          region: TaxRegion.continent,
          civilStatus: CivilStatus.married,
          dependentCount: 2,
          hasEmployment: true,
          hasSelfEmployment: false,
        ),
        incomes: const [
          IncomeEntry(
            id: 'known-income',
            category: IncomeCategory.employment,
            amount: Money.fromCents(3200000),
            year: 2026,
            provenance: EntryProvenance.imported,
            status: EntryStatus.confirmed,
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productRepositoryProvider.overrideWithValue(
              MemoryProductRepository(state),
            ),
            taxInterviewRepositoryProvider.overrideWithValue(
              MemoryTaxInterviewRepository(),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const GuidedTaxScreen(taxYear: 2026),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('We already found this information. You can review it.'),
        findsNothing,
      );
      await tester.tap(find.text('Yes'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('How old were you at the end of 2026?'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '35');
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(
        find.text('Would you like to see joint taxation first?'),
        findsOneWidget,
      );
      expect(
        find.text('What was your family situation at the end of 2026?'),
        findsNothing,
      );
    },
  );
}
