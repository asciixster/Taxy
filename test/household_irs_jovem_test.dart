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
    engine = HouseholdTaxEngine(await repository.load(2025, 'continent'));
  });

  for (final eligibility in const [
    (
      name: 'nenhum',
      a: false,
      b: false,
      sep: 2072879,
      joint: 1953712,
      benefit: 0,
    ),
    (
      name: 'apenas A',
      a: true,
      b: false,
      sep: 1226797,
      joint: 1242459,
      benefit: 726915,
    ),
    (
      name: 'apenas B',
      a: false,
      b: true,
      sep: 1778792,
      joint: 1582462,
      benefit: 371250,
    ),
    (
      name: 'ambos',
      a: true,
      b: true,
      sep: 932710,
      joint: 871209,
      benefit: 1082503,
    ),
  ]) {
    test('casal IRS Jovem: ${eligibility.name}', () {
      final result = engine.compareWithIrsJovem(
        _simulation(eligibleA: eligibility.a, eligibleB: eligibility.b),
      );
      expect(result.available, isTrue);
      expect(result.withIrsJovem, isNotNull);
      expect(result.normal.separate!.taxDue.cents, 2072879);
      expect(result.normal.joint!.taxDue.cents, 1953712);
      expect(result.withIrsJovem!.separate!.taxDue.cents, eligibility.sep);
      expect(result.withIrsJovem!.joint!.taxDue.cents, eligibility.joint);
      expect(result.estimatedBenefit.cents, eligibility.benefit);
    });
  }
}

TaxSimulation _simulation({required bool eligibleA, required bool eligibleB}) {
  IrsJovemAnswers answers(bool eligible, int regimeYear) {
    if (!eligible) return const IrsJovemAnswers();
    final first = 2025 - regimeYear + 1;
    return IrsJovemAnswers(
      requested: true,
      taxSituationRegularized: true,
      historyConfirmedComplete: true,
      incomeHistory: [
        for (var year = first; year <= 2025; year++)
          IrsJovemIncomeYear(
            year: year,
            hadCategoryAIncome: true,
            hadCategoryBIncome: false,
            wasDependent: false,
            residentInPortugal: true,
          ),
      ],
    );
  }

  final now = DateTime.utc(2025);
  return TaxSimulation(
    id: 'couple-jovem-$eligibleA-$eligibleB',
    name: 'Casal IRS Jovem',
    createdAt: now,
    updatedAt: now,
    profile: const TaxpayerProfile(
      taxYear: 2025,
      age: 30,
      civilStatus: CivilStatus.married,
      dependentAges: [],
      fullYearResident: true,
      region: TaxRegion.continent,
      filingMode: FilingMode.joint,
    ),
    income: const EmploymentIncome(
      entryMode: IncomeEntryMode.annual,
      gross: Money.fromCents(6000000),
      withholding: Money.zero,
      socialSecurity: Money.fromCents(660000),
    ),
    deductions: const DeductionInput(),
    primaryIrsJovem: answers(eligibleA, 1),
    secondaryTaxpayer: TaxpayerInput(
      id: 'B',
      age: 30,
      income: const EmploymentIncome(
        entryMode: IncomeEntryMode.annual,
        gross: Money.fromCents(3000000),
        withholding: Money.zero,
        socialSecurity: Money.fromCents(330000),
      ),
      deductions: const DeductionInput(),
      irsJovem: answers(eligibleB, 5),
    ),
  );
}
