import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/domain/models.dart';
import 'package:taxy_pt/domain/money.dart';
import 'package:taxy_pt/tax_engine/household_tax_engine.dart';
import 'package:taxy_pt/tax_engine/tax_rules.dart';

void main() {
  late HouseholdTaxEngine engine;

  setUpAll(() async {
    final repository = TaxRuleRepository((path) => File(path).readAsString());
    engine = HouseholdTaxEngine(await repository.load(2026, 'continent'));
  });

  for (final status in [CivilStatus.married, CivilStatus.deFacto]) {
    for (final incomes in [
      (3000000, 0),
      (0, 3000000),
      (3000000, 3000000),
      (8000000, 1000000),
      (2500000, 4000000),
    ]) {
      test(
        '${status.name} A=${incomes.$1} B=${incomes.$2} compara dois modos',
        () {
          final result = engine.compare(
            _simulation(status: status, grossA: incomes.$1, grossB: incomes.$2),
          );
          expect(result.available, isTrue);
          expect(result.joint!.available, isTrue);
          expect(result.separate!.available, isTrue);
          expect(result.recommendedMode, isNotNull);
          expect(result.difference.cents, greaterThanOrEqualTo(0));
        },
      );
    }
  }

  test('rendimentos iguais sem despesas produzem coleta igual', () {
    final result = engine.compare(
      _simulation(grossA: 5000000, grossB: 5000000),
    );
    expect(result.joint!.taxDue, result.separate!.taxDue);
    expect(result.difference, Money.zero);
  });

  test('rendimentos muito diferentes favorecem conjunta', () {
    final result = engine.compare(
      _simulation(grossA: 9000000, grossB: 1000000),
    );
    expect(result.recommendedMode, FilingMode.joint);
    expect(result.joint!.taxDue.cents, lessThan(result.separate!.taxDue.cents));
  });

  for (final ages in [
    <int>[],
    [2],
    [10],
    [5, 2],
    [12, 5, 2],
    [16, 8, 4, 1],
  ]) {
    test('dependentes $ages são calculados nos dois modos', () {
      final result = engine.compare(_simulation(dependentAges: ages));
      expect(result.available, isTrue);
      expect(result.joint!.taxCredits.cents, greaterThanOrEqualTo(0));
      expect(result.separate!.taxCredits.cents, greaterThanOrEqualTo(0));
    });
  }

  test('ordem dos dependentes não altera conjunta nem separada', () {
    final first = engine.compare(_simulation(dependentAges: const [10, 5, 2]));
    final second = engine.compare(_simulation(dependentAges: const [2, 10, 5]));
    expect(first.joint!.taxDue, second.joint!.taxDue);
    expect(first.separate!.taxDue, second.separate!.taxDue);
  });

  for (final deduction in [
    'general',
    'health',
    'education',
    'rent',
    'care',
    'ppr',
  ]) {
    test('$deduction do titular B entra na comparação', () {
      final baseline = engine.compare(_simulation());
      final changed = engine.compare(
        _simulation(deductionB: deduction, deductionAmount: 100000),
      );
      expect(
        changed.joint!.taxDue.cents,
        lessThanOrEqualTo(baseline.joint!.taxDue.cents),
      );
      expect(
        changed.separate!.taxDue.cents,
        lessThanOrEqualTo(baseline.separate!.taxDue.cents),
      );
    });
  }

  test('despesas dos dependentes são repartidas 50/50 na separada', () {
    final result = engine.compare(
      _simulation(
        dependentAges: const [10],
        dependentDeductions: const DeductionInput(
          health: Money.fromCents(100000),
        ),
      ),
    );
    final healthLines = result.separate!.creditBreakdown
        .where((row) => row.label == 'Saúde')
        .toList();
    expect(healthLines, hasLength(2));
    expect(healthLines[0].amount, const Money.fromCents(7500));
    expect(healthLines[1].amount, const Money.fromCents(7500));
  });

  test('guarda partilhada falha fechado', () {
    final simulation = _simulation().copyWith(
      dependents: const [
        Dependent(id: 'd', ageAtYearEnd: 8, sharedCustody: true),
      ],
      profile: _simulation().profile.copyWith(dependentAges: const [8]),
    );
    expect(engine.compare(simulation).available, isFalse);
  });

  test('casal sem segundo titular falha fechado', () {
    final simulation = _simulation().copyWith(clearSecondaryTaxpayer: true);
    expect(engine.compare(simulation).available, isFalse);
  });

  test('single não entra no comparador conjugal', () {
    final simulation = _simulation().copyWith(
      profile: _simulation().profile.copyWith(civilStatus: CivilStatus.single),
      clearSecondaryTaxpayer: true,
    );
    expect(engine.compare(simulation).available, isFalse);
  });
}

TaxSimulation _simulation({
  CivilStatus status = CivilStatus.married,
  int grossA = 4000000,
  int grossB = 3000000,
  List<int> dependentAges = const [],
  String? deductionB,
  int deductionAmount = 0,
  DeductionInput dependentDeductions = const DeductionInput(),
}) {
  Money amount(String name) =>
      Money.fromCents(deductionB == name ? deductionAmount : 0);
  final now = DateTime.utc(2026);
  return TaxSimulation(
    id: 'household',
    name: 'Household',
    createdAt: now,
    updatedAt: now,
    profile: TaxpayerProfile(
      taxYear: 2026,
      age: 40,
      civilStatus: status,
      dependentAges: dependentAges,
      fullYearResident: true,
      region: TaxRegion.continent,
      filingMode: FilingMode.joint,
    ),
    income: EmploymentIncome(
      entryMode: IncomeEntryMode.annual,
      gross: Money.fromCents(grossA),
      withholding: Money.zero,
      socialSecurity: Money.fromCents(Money.mulDiv(grossA, 11, 100)),
    ),
    deductions: const DeductionInput(),
    secondaryTaxpayer: TaxpayerInput(
      id: 'B',
      age: 42,
      income: EmploymentIncome(
        entryMode: IncomeEntryMode.annual,
        gross: Money.fromCents(grossB),
        withholding: Money.zero,
        socialSecurity: Money.fromCents(Money.mulDiv(grossB, 11, 100)),
      ),
      deductions: DeductionInput(
        general: amount('general'),
        health: amount('health'),
        education: amount('education'),
        rent: amount('rent'),
        careHomes: amount('care'),
        ppr: amount('ppr'),
      ),
    ),
    dependents: [
      for (var i = 0; i < dependentAges.length; i++)
        Dependent(id: 'd-$i', ageAtYearEnd: dependentAges[i]),
    ],
    dependentDeductions: dependentDeductions,
  );
}
