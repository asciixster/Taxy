import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/domain/models.dart';
import 'package:taxy_pt/domain/money.dart';
import 'package:taxy_pt/tax_engine/household_tax_engine.dart';
import 'package:taxy_pt/tax_engine/tax_engine.dart';
import 'package:taxy_pt/tax_engine/tax_rules.dart';

void main() {
  late TaxRuleSet rules;
  late TaxEngine engine;

  setUpAll(() async {
    final repository = TaxRuleRepository((path) => File(path).readAsString());
    rules = await repository.load(2025, 'CONTINENT');
    engine = TaxEngine(rules);
  });

  group('2025 Continente bracket boundaries', () {
    test('zero and one cent taxable income', () {
      expect(engine.grossTaxForTaxableIncome(Money.zero).cents, 0);
      expect(
        engine.grossTaxForTaxableIncome(const Money.fromCents(1)).cents,
        0,
      );
    });

    for (var index = 0; index < 8; index++) {
      for (final delta in const [-1, 0, 1]) {
        test(
          'bracket ${index + 1} boundary ${delta >= 0 ? '+' : ''}$delta',
          () {
            final taxable = rules.brackets[index].upperCents! + delta;
            expect(
              engine.grossTaxForTaxableIncome(Money.fromCents(taxable)).cents,
              _independentBracketTax(rules, taxable),
            );
          },
        );
      }
    }
  });

  group('credit caps and collection availability', () {
    test('PPR deduction exactly at individual cap', () {
      final result = engine.calculate(_single(ppr: 175000, age: 40));
      expect(result.trace.pprCredit.cents, 35000);
    });

    test('PPR potential one cent above cap remains capped', () {
      final result = engine.calculate(_single(ppr: 175005, age: 40));
      expect(result.trace.pprCredit.cents, 35000);
    });

    test('credits exactly equal gross collection', () {
      final calculation = engine.creditsForSimulation(
        _single(general: 100000),
        const Money.fromCents(2000000),
        const Money.fromCents(25000),
        [],
      );
      expect(calculation.potentialTotal.cents, 25000);
      expect(calculation.total.cents, 25000);
    });

    test('collection one cent below credits reduces effective only', () {
      final calculation = engine.creditsForSimulation(
        _single(general: 100000),
        const Money.fromCents(2000000),
        const Money.fromCents(24999),
        [],
      );
      expect(calculation.potentialTotal.cents, 25000);
      expect(calculation.total.cents, 24999);
    });
  });

  group('rounding regression 2025', () {
    test('ppm multiplication is half-up on exact halves', () {
      expect(Money.mulDiv(1, 500000, 1000000), 1);
      expect(Money.mulDiv(3, 500000, 1000000), 2);
      expect(Money.mulDiv(-1, 500000, 1000000), -1);
    });

    test('odd joint taxable income is divided half-up before brackets', () {
      final comparison = HouseholdTaxEngine(rules)
          .compare(_couple(grossA: 5200000, grossB: 2900000));
      expect(comparison.available, isTrue);
      expect(comparison.joint!.trace.rateDeterminingQuotient.cents, 3540893);
    });

    test('trace distinguishes potential and effective credits', () {
      final result = engine.calculate(
        _single(
          gross: 5500000,
          socialSecurity: 605000,
          general: 600000,
          health: 800000,
          rent: 600000,
        ),
      );
      expect(result.trace.potentialTaxCredits.cents, 195000);
      expect(result.trace.effectiveTaxCredits.cents, 189741);
      expect(result.trace.totalTaxCredits, result.trace.effectiveTaxCredits);
    });
  });

  group('fail closed regressions', () {
    for (final entry in <String, TaxSimulation>{
      'Category B': _single(incomeTypes: const {IncomeType.selfEmployment}),
      'Category H': _single(incomeTypes: const {IncomeType.pensions}),
      'foreign income': _single(
        situations: const TaxSituationFlags(foreignIncome: true),
      ),
      'partial residence': _single(fullYearResident: false),
      'disability': _single(
        situations: const TaxSituationFlags(disability: true),
      ),
      'unknown special regime': _single(
        situations: const TaxSituationFlags(otherSpecialSituation: true),
      ),
    }.entries) {
      test('${entry.key} is unavailable before calculation', () {
        expect(engine.calculate(entry.value).available, isFalse);
      });
    }

    test('shared custody is unavailable before household calculation', () {
      final simulation = _couple(grossA: 3000000, grossB: 2500000).copyWith(
        profile: _couple(
          grossA: 3000000,
          grossB: 2500000,
        ).profile.copyWith(dependentAges: const [9]),
        dependents: const [
          Dependent(id: 'dependent-1', ageAtYearEnd: 9, sharedCustody: true),
        ],
      );
      expect(HouseholdTaxEngine(rules).compare(simulation).available, isFalse);
    });

    test('unsupported year fails rule resolution', () async {
      final repository = TaxRuleRepository((path) => File(path).readAsString());
      await expectLater(repository.load(2024, 'CONTINENT'), throwsA(anything));
    });
  });
}

int _independentBracketTax(TaxRuleSet rules, int taxable) {
  if (taxable <= 0) return 0;
  for (var index = 0; index < rules.brackets.length; index++) {
    final bracket = rules.brackets[index];
    if (bracket.upperCents == null || taxable <= bracket.upperCents!) {
      if (index == 0) {
        return Money.mulDiv(taxable, bracket.marginalRatePpm, 1000000);
      }
      final previous = rules.brackets[index - 1];
      return Money.mulDiv(
            previous.upperCents!,
            previous.averageRatePpm!,
            1000000,
          ) +
          Money.mulDiv(
            taxable - previous.upperCents!,
            bracket.marginalRatePpm,
            1000000,
          );
    }
  }
  throw StateError('Incomplete test table');
}

TaxSimulation _single({
  int gross = 3000000,
  int socialSecurity = 330000,
  int age = 40,
  int general = 0,
  int health = 0,
  int rent = 0,
  int ppr = 0,
  bool fullYearResident = true,
  Set<IncomeType> incomeTypes = const {IncomeType.employment},
  TaxSituationFlags situations = const TaxSituationFlags(),
}) {
  final now = DateTime.utc(2026, 8, 28);
  return TaxSimulation(
    id: 'boundary',
    name: 'Boundary',
    createdAt: now,
    updatedAt: now,
    profile: TaxpayerProfile(
      taxYear: 2025,
      age: age,
      civilStatus: CivilStatus.single,
      dependentAges: const [],
      fullYearResident: fullYearResident,
      region: TaxRegion.continent,
      filingMode: FilingMode.separate,
    ),
    income: EmploymentIncome(
      entryMode: IncomeEntryMode.annual,
      gross: Money.fromCents(gross),
      withholding: Money.zero,
      socialSecurity: Money.fromCents(socialSecurity),
    ),
    deductions: DeductionInput(
      general: Money.fromCents(general),
      health: Money.fromCents(health),
      rent: Money.fromCents(rent),
      ppr: Money.fromCents(ppr),
    ),
    situations: situations,
    incomeTypes: incomeTypes,
  );
}

TaxSimulation _couple({required int grossA, required int grossB}) {
  final base = _single(gross: grossA, socialSecurity: grossA * 11 ~/ 100);
  return base.copyWith(
    profile: base.profile.copyWith(
      civilStatus: CivilStatus.married,
      filingMode: FilingMode.joint,
    ),
    secondaryTaxpayer: TaxpayerInput(
      id: 'B',
      age: 42,
      income: EmploymentIncome(
        entryMode: IncomeEntryMode.annual,
        gross: Money.fromCents(grossB),
        withholding: Money.zero,
        socialSecurity: Money.fromCents(grossB * 11 ~/ 100),
      ),
      deductions: const DeductionInput(),
    ),
  );
}
