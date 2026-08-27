import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/domain/models.dart';
import 'package:taxy_pt/domain/money.dart';
import 'package:taxy_pt/tax_engine/household_tax_engine.dart';
import 'package:taxy_pt/tax_engine/irs_jovem_tax_engine.dart';
import 'package:taxy_pt/tax_engine/tax_rules.dart';

void main() {
  final file = File(
    'test/fixtures/reference_calculations/irs_jovem/cases_2025_continent.json',
  );
  late Map<String, Object?> document;
  late TaxRuleSet rules;

  setUpAll(() async {
    document = (jsonDecode(file.readAsStringSync()) as Map)
        .cast<String, Object?>();
    rules = await TaxRuleRepository((path) => File(path).readAsString())
        .load(document['year'] as int, document['region'] as String);
  });

  test('reference fixture has audited provenance and current rules', () {
    expect(document['source'], 'MANUALLY_AUDITED_REFERENCE');
    expect(document['rulesVersion'], rules.rulesVersion);
    expect((document['cases'] as List), hasLength(greaterThanOrEqualTo(11)));
  });

  test('all manually audited IRS Jovem reference cases match exact cents', () {
    for (final raw in document['cases'] as List) {
      final fixture = (raw as Map).cast<String, Object?>();
      final expected = (fixture['expected'] as Map).cast<String, int>();
      final simulation = _simulation(fixture);
      if (fixture['grossB'] == null) {
        final comparison = IrsJovemTaxEngine(rules).compare(simulation);
        expect(
          comparison.normal.taxDue.cents,
          expected['normalTax'],
          reason: fixture['id'] as String,
        );
        expect(comparison.adjustment!.exemptIncome.cents, expected['exempt']);
        expect(
          comparison.withIrsJovem!.taxableIncome.cents,
          expected['taxable'],
        );
        expect(
          comparison.adjustment!.rateDeterminingIncome.cents,
          expected['rateIncome'],
        );
        expect(comparison.withIrsJovem!.taxDue.cents, expected['jovemTax']);
      } else {
        final comparison = HouseholdTaxEngine(rules)
            .compareWithIrsJovem(simulation);
        expect(
          comparison.normal.separate!.taxDue.cents,
          expected['normalSeparateTax'],
        );
        expect(
          comparison.normal.joint!.taxDue.cents,
          expected['normalJointTax'],
        );
        expect(
          comparison.withIrsJovem!.separate!.taxDue.cents,
          expected['jovemSeparateTax'],
        );
        expect(
          comparison.withIrsJovem!.joint!.taxDue.cents,
          expected['jovemJointTax'],
        );
        expect(comparison.estimatedBenefit.cents, expected['benefit']);
      }
    }
  });
}

TaxSimulation _simulation(Map<String, Object?> fixture) {
  IrsJovemAnswers answers(String suffix) {
    final regimeYear = fixture['regimeYear$suffix'] as int?;
    if (regimeYear == null) return const IrsJovemAnswers();
    return IrsJovemAnswers(
      requested: true,
      taxSituationRegularized: true,
      historyConfirmedComplete: true,
      incomeHistory: [
        for (var year = 2025 - regimeYear + 1; year <= 2025; year++)
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

  final isCouple = fixture['grossB'] != null;
  final now = DateTime.utc(2025);
  return TaxSimulation(
    id: fixture['id'] as String,
    name: fixture['id'] as String,
    createdAt: now,
    updatedAt: now,
    profile: TaxpayerProfile(
      taxYear: 2025,
      age: 30,
      civilStatus: isCouple ? CivilStatus.married : CivilStatus.single,
      dependentAges: const [],
      fullYearResident: true,
      region: TaxRegion.continent,
      filingMode: isCouple ? FilingMode.joint : FilingMode.separate,
    ),
    income: EmploymentIncome(
      entryMode: IncomeEntryMode.annual,
      gross: Money.fromCents(fixture['grossA'] as int),
      withholding: Money.zero,
      socialSecurity: Money.fromCents(fixture['socialSecurityA'] as int),
    ),
    deductions: const DeductionInput(),
    primaryIrsJovem: answers('A'),
    secondaryTaxpayer: !isCouple
        ? null
        : TaxpayerInput(
            id: 'B',
            age: 30,
            income: EmploymentIncome(
              entryMode: IncomeEntryMode.annual,
              gross: Money.fromCents(fixture['grossB'] as int),
              withholding: Money.zero,
              socialSecurity: Money.fromCents(
                fixture['socialSecurityB'] as int,
              ),
            ),
            deductions: const DeductionInput(),
            irsJovem: answers('B'),
          ),
  );
}
