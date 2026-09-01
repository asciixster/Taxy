import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/domain/models.dart';
import 'package:taxy_pt/domain/money.dart';
import 'package:taxy_pt/modules/efatura/domain/efatura_models.dart';
import 'package:taxy_pt/modules/efatura/domain/invoice_explorer.dart';
import 'package:taxy_pt/product/app_failure.dart';
import 'package:taxy_pt/product/irs_scenario_models.dart';
import 'package:taxy_pt/product/product_models.dart';

void main() {
  group('scenario overlays', () {
    test('change supported values without mutating the base simulation', () {
      final base = _simulation();
      const overrides = ScenarioOverrides(
        grossIncomeCents: 4200000,
        withholdingCents: 700000,
        healthExpensesCents: 90000,
      );

      final alternative = overrides.applyTo(base);

      expect(base.income.gross.cents, 3600000);
      expect(alternative.income.gross.cents, 4200000);
      expect(alternative.income.withholding.cents, 700000);
      expect(alternative.deductions.health.cents, 90000);
      expect(overrides.changesFrom(base), hasLength(3));
    });

    test('serialize exactly as explicit overrides', () {
      const value = ScenarioOverrides(pprCents: 200000);
      final restored = ScenarioOverrides.fromJson(value.toJson());
      expect(restored.pprCents, 200000);
      expect(restored.grossIncomeCents, isNull);
    });
  });

  test('saved estimate is versioned and round-trips without recalculation', () {
    final snapshot = IrsSnapshot(
      id: 'synthetic-snapshot',
      label: 'Synthetic estimate',
      createdAt: DateTime.utc(2026, 9, 1),
      taxYear: 2026,
      calculationModelVersion: '2026.1',
      inputSchemaVersion: 1,
      simulation: _simulation(),
      balanceCents: 12345,
      grossIncomeCents: 3600000,
      withholdingCents: 600000,
      taxCreditsCents: 120000,
    );
    final restored = IrsSnapshot.fromJson(snapshot.toJson());
    expect(restored.balanceCents, 12345);
    expect(restored.calculationModelVersion, '2026.1');
    expect(restored.inputSchemaVersion, 1);
    expect(restored.simulation.income.gross.cents, 3600000);
  });

  test('product schema migrates v1 and persists v2 snapshots', () {
    final v1 = ProductState.initial().toJson()
      ..['schemaVersion'] = 1
      ..remove('snapshots');
    expect(ProductState.fromJson(v1).snapshots, isEmpty);

    final snapshot = IrsSnapshot(
      id: 'snapshot',
      label: 'Estimate',
      createdAt: DateTime.utc(2026),
      taxYear: 2026,
      calculationModelVersion: 'rules',
      inputSchemaVersion: 1,
      simulation: _simulation(),
      balanceCents: 0,
      grossIncomeCents: 3600000,
      withholdingCents: 600000,
      taxCreditsCents: 0,
    );
    final state = ProductState.initial().copyWith(snapshots: [snapshot]);
    expect(state.toJson()['schemaVersion'], 2);
    expect(ProductState.fromJson(state.toJson()).snapshots, hasLength(1));
  });

  group('invoice explorer', () {
    test('searches, filters value/date and sorts locally', () {
      final invoices = [
        _invoice('2026-01-10', 1000, 'Alpha'),
        _invoice('2026-02-10', 5000, 'Beta'),
        _invoice('2026-03-10', 3000, 'Alpha Shop'),
      ];
      final result = filterInvoices(
        invoices,
        InvoiceFilter(
          query: 'alpha',
          from: DateTime(2026, 2),
          minimumCents: 2000,
          sort: InvoiceSort.highestValue,
        ),
      );
      expect(result, hasLength(1));
      expect(result.single.issuerDisplayName, 'Alpha Shop');
    });

    test('monthly summary uses document totals and integer averages', () {
      final summary = summarizeInvoicesByMonth([
        _invoice('2026-02-01', 100, 'A'),
        _invoice('2026-02-02', 201, 'B'),
        _invoice('2026-01-02', 500, 'C'),
      ]);
      expect(summary, hasLength(2));
      expect(summary.first.month, 2);
      expect(summary.first.documentCount, 2);
      expect(summary.first.totalCents, 301);
      expect(summary.first.averageCents, 150);
    });

    test('500 invoice dataset remains a local linear operation', () {
      final invoices = List.generate(
        500,
        (index) => _invoice(
          '2026-${(index % 12 + 1).toString().padLeft(2, '0')}-01',
          index * 100,
          'Issuer $index',
        ),
      );
      final stopwatch = Stopwatch()..start();
      final filtered = filterInvoices(
        invoices,
        const InvoiceFilter(query: 'issuer 49'),
      );
      final summary = summarizeInvoicesByMonth(invoices);
      stopwatch.stop();
      expect(filtered, isNotEmpty);
      expect(summary, hasLength(12));
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });

  test('profile checklist reports objective completeness, not accuracy', () {
    final empty = ProductState.initial();
    expect(empty.completedChecklistItems, 1);
    expect(empty.checklist, hasLength(6));
    final complete = empty.copyWith(
      profile: const FiscalProfile(
        activeTaxYear: 2026,
        region: TaxRegion.continent,
        civilStatus: CivilStatus.single,
        dependentCount: 0,
        hasEmployment: true,
        hasSelfEmployment: false,
      ),
      incomes: [
        IncomeEntry(
          id: 'income',
          category: IncomeCategory.employment,
          amount: Money.fromCents(100),
          year: 2026,
          provenance: EntryProvenance.manual,
          status: EntryStatus.confirmed,
        ),
      ],
    );
    expect(complete.completedChecklistItems, complete.checklist.length);
  });

  test('shared failures expose only stable diagnostic codes', () {
    for (final kind in AppFailureKind.values) {
      final failure = AppFailure(kind, correlationId: 'opaque-correlation');
      expect(failure.diagnosticCode, isNotEmpty);
      expect(failure.diagnosticCode, isNot(contains('opaque-correlation')));
    }
  });

  test('offline state model distinguishes stale from unavailable', () {
    expect(AppDataState.values, contains(AppDataState.offline));
    expect(AppDataState.stale, isNot(AppDataState.unavailable));
  });
}

TaxSimulation _simulation() => TaxSimulation(
  id: 'synthetic',
  name: 'Synthetic simulation',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  profile: const TaxpayerProfile(
    taxYear: 2026,
    age: 35,
    civilStatus: CivilStatus.single,
    dependentAges: [],
    fullYearResident: true,
    region: TaxRegion.continent,
    filingMode: FilingMode.separate,
  ),
  income: const EmploymentIncome(
    entryMode: IncomeEntryMode.annual,
    gross: Money.fromCents(3600000),
    withholding: Money.fromCents(600000),
    socialSecurity: Money.fromCents(396000),
  ),
  deductions: const DeductionInput(health: Money.fromCents(30000)),
);

EfaturaInvoice _invoice(String date, int cents, String issuer) =>
    EfaturaInvoice(date: date, totalCents: cents, issuerDisplayName: issuer);
