import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/domain/money.dart';
import 'package:taxy_pt/domain/models.dart';
import 'package:taxy_pt/l10n/app_localizations.dart';
import 'package:taxy_pt/l10n/theme_controller.dart';
import 'package:taxy_pt/product/app_failure.dart';
import 'package:taxy_pt/product/product_models.dart';
import 'package:taxy_pt/product/product_repository.dart';
import 'package:taxy_pt/product/profile_screen.dart';
import 'package:taxy_pt/state/providers.dart';

void main() {
  test('global fiscal profile preserves unknown values and active year', () {
    final profile = FiscalProfile.fromJson(
      const FiscalProfile(activeTaxYear: 2026).toJson(),
    );
    expect(profile.activeTaxYear, 2026);
    expect(profile.region, isNull);
    expect(profile.isComplete, isFalse);
    expect(profile.missingFields, contains('civilStatus'));
  });

  test('complete profile and entries survive schema round trip', () {
    final state = ProductState(
      profile: const FiscalProfile(
        activeTaxYear: 2025,
        region: TaxRegion.madeira,
        civilStatus: CivilStatus.single,
        dependentCount: 0,
        hasEmployment: true,
        hasSelfEmployment: false,
      ),
      incomes: const [
        IncomeEntry(
          id: 'income-1',
          category: IncomeCategory.employment,
          amount: Money.fromCents(12345),
          year: 2025,
          provenance: EntryProvenance.manual,
          status: EntryStatus.confirmed,
        ),
      ],
      expenses: const [
        ExpenseEntry(
          id: 'expense-1',
          category: ExpenseCategory.health,
          amount: Money.fromCents(2500),
          vat: Money.fromCents(575),
          year: 2025,
          provenance: EntryProvenance.imported,
          status: EntryStatus.confirmed,
        ),
      ],
    );
    final decoded = ProductState.fromJson(state.toJson());
    expect(decoded.profile.isComplete, isTrue);
    expect(decoded.incomeTotal.cents, 12345);
    expect(decoded.expenseTotal.cents, 2500);
    expect(decoded.expenses.single.provenance, EntryProvenance.imported);
  });

  test('income deduplication flags but never removes candidates', () {
    const first = IncomeEntry(
      id: 'a',
      category: IncomeCategory.employment,
      amount: Money.fromCents(10000),
      year: 2026,
      provenance: EntryProvenance.manual,
      status: EntryStatus.confirmed,
      deduplicationIdentity: 'same-source-reference',
    );
    const second = IncomeEntry(
      id: 'b',
      category: IncomeCategory.employment,
      amount: Money.fromCents(10000),
      year: 2026,
      provenance: EntryProvenance.imported,
      status: EntryStatus.confirmed,
      deduplicationIdentity: 'same-source-reference',
    );
    final values = flagPossibleIncomeDuplicates([first, second]);
    expect(values, hasLength(2));
    expect(
      values.every((entry) => entry.status == EntryStatus.possibleDuplicate),
      isTrue,
    );
  });

  test('shared error taxonomy has stable non-technical codes', () {
    expect(
      const AppFailure(AppFailureKind.networkOffline).diagnosticCode,
      'NETWORK_OFFLINE',
    );
    expect(
      const AppFailure(AppFailureKind.missingRequiredData).diagnosticCode,
      'MISSING_REQUIRED_DATA',
    );
    expect(AppFailureKind.values, hasLength(8));
  });

  test('diagnostic implementation cannot export fiscal secrets', () {
    final source = File('lib/screens/settings_screen.dart').readAsStringSync();
    expect(source, contains('InternalBetaBuildInfo.appVersion'));
    expect(source, isNot(contains('sessionToken')));
    expect(source, isNot(contains('passwordController')));
    expect(source, isNot(contains('invoiceId')));
    expect(source, isNot(contains('taxpayerNif')));
  });

  test('theme preference switches immediately and persists', () async {
    final store = MemoryThemePreferenceStore();
    final controller = ThemeController(store);
    await controller.select(ThemePreference.dark);
    expect(controller.mode, ThemeMode.dark);
    expect(store.value, ThemePreference.dark);
  });

  testWidgets('profile is responsive in English, dark mode and 200% text', (
    tester,
  ) async {
    final repository = MemoryProductRepository();
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [productRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const FiscalProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tax profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
