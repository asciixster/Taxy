import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/domain/models.dart';
import 'package:taxy_pt/domain/money.dart';
import 'package:taxy_pt/tax_engine/tax_rules.dart';
import 'package:taxy_pt/validation/at_validation.dart';

void main() {
  late TaxRuleSet rules;

  setUpAll(() async {
    rules = await TaxRuleRepository((path) => File(path).readAsString())
        .load(2025, 'continent');
  });

  test('single normal trace has no exemption and divisor one', () {
    final trace = const AtValidationEngine().calculateTrace(
      _single(jovem: false),
      rules,
    );

    expect(trace.maritalQuotient, 1);
    expect(trace.rateDeterminingIncome, trace.taxableIncome);
    expect(trace.rateDeterminingQuotient, trace.taxableIncome);
    expect(trace.exemptIncome, Money.zero);
    expect(trace.taxAllocatedToExemptIncome, Money.zero);
    expect(trace.taxBeforeExemption, trace.grossTaxAfterExemption);
  });

  test('single IRS Jovem trace separates rate and exemption stages', () {
    final trace = const AtValidationEngine().calculateTrace(
      _single(jovem: true),
      rules,
    );

    expect(trace.maritalQuotient, 1);
    expect(trace.exemptIncome.cents, greaterThan(0));
    expect(
      trace.rateDeterminingIncome.cents,
      greaterThan(trace.taxableIncome.cents),
    );
    expect(trace.rateDeterminingQuotient, trace.rateDeterminingIncome);
    expect(trace.taxAllocatedToExemptIncome.cents, greaterThan(0));
    expect(
      trace.grossTaxAfterExemption,
      trace.taxBeforeExemption - trace.taxAllocatedToExemptIncome,
    );
  });

  test('couple separate trace aggregates two individual calculations', () {
    final trace = const AtValidationEngine().calculateTrace(
      _couple(FilingMode.separate),
      rules,
    );

    expect(trace.maritalQuotient, 1);
    expect(trace.rateDeterminingIncome, trace.taxableIncome);
    expect(trace.rateDeterminingQuotient, trace.rateDeterminingIncome);
    expect(trace.grossIncome.cents, 7500000);
  });

  test('couple joint trace separates marital and rate quotients', () {
    final trace = const AtValidationEngine().calculateTrace(
      _couple(FilingMode.joint),
      rules,
    );

    expect(trace.maritalQuotient, 2);
    expect(trace.rateDeterminingIncome, trace.taxableIncome);
    expect(
      trace.rateDeterminingQuotient.cents,
      Money.mulDiv(trace.rateDeterminingIncome.cents, 1, 2),
    );
  });

  test('couple joint plus IRS Jovem keeps all four concepts distinct', () {
    final trace = const AtValidationEngine().calculateTrace(
      _couple(FilingMode.joint, jovemA: true),
      rules,
    );

    expect(trace.maritalQuotient, 2);
    expect(trace.exemptIncome.cents, greaterThan(0));
    expect(
      trace.rateDeterminingIncome.cents,
      greaterThan(trace.taxableIncome.cents),
    );
    expect(
      trace.rateDeterminingQuotient.cents,
      Money.mulDiv(trace.rateDeterminingIncome.cents, 1, 2),
    );
    expect(trace.taxAllocatedToExemptIncome.cents, greaterThan(0));
  });

  test('typed credit fields reconcile with the applied credit total', () {
    final trace = const AtValidationEngine().calculateTrace(
      _single(jovem: false),
      rules,
    );
    final rawCredits =
        trace.dependentCredits +
        trace.generalExpenseCredit +
        trace.healthCredit +
        trace.educationCredit +
        trace.careHomeCredit +
        trace.rentCredit +
        trace.invoiceVatCredit +
        trace.pprCredit;

    expect(rawCredits.cents, greaterThanOrEqualTo(trace.totalTaxCredits.cents));
    expect(
      trace.finalTaxDue,
      trace.grossTaxAfterExemption - trace.totalTaxCredits,
    );
  });
}

TaxSimulation _single({required bool jovem}) => TaxSimulation(
  id: 'trace-single',
  name: 'Trace single',
  createdAt: DateTime.utc(2025),
  updatedAt: DateTime.utc(2025),
  profile: const TaxpayerProfile(
    taxYear: 2025,
    age: 30,
    civilStatus: CivilStatus.single,
    dependentAges: [],
    fullYearResident: true,
    region: TaxRegion.continent,
    filingMode: FilingMode.separate,
  ),
  income: const EmploymentIncome(
    entryMode: IncomeEntryMode.annual,
    gross: Money.fromCents(3000000),
    withholding: Money.fromCents(400000),
    socialSecurity: Money.fromCents(330000),
  ),
  deductions: const DeductionInput(
    general: Money.fromCents(100000),
    health: Money.fromCents(30000),
  ),
  primaryIrsJovem: jovem ? _jovemAnswers : const IrsJovemAnswers(),
);

TaxSimulation _couple(FilingMode mode, {bool jovemA = false}) => TaxSimulation(
  id: 'trace-couple',
  name: 'Trace couple',
  createdAt: DateTime.utc(2025),
  updatedAt: DateTime.utc(2025),
  profile: TaxpayerProfile(
    taxYear: 2025,
    age: 30,
    civilStatus: CivilStatus.married,
    dependentAges: const [],
    fullYearResident: true,
    region: TaxRegion.continent,
    filingMode: mode,
  ),
  income: const EmploymentIncome(
    entryMode: IncomeEntryMode.annual,
    gross: Money.fromCents(5000000),
    withholding: Money.fromCents(800000),
    socialSecurity: Money.fromCents(550000),
  ),
  deductions: const DeductionInput(general: Money.fromCents(90000)),
  primaryIrsJovem: jovemA ? _jovemAnswers : const IrsJovemAnswers(),
  secondaryTaxpayer: const TaxpayerInput(
    id: 'B',
    age: 40,
    income: EmploymentIncome(
      entryMode: IncomeEntryMode.annual,
      gross: Money.fromCents(2500000),
      withholding: Money.fromCents(250000),
      socialSecurity: Money.fromCents(275000),
    ),
    deductions: DeductionInput(general: Money.fromCents(60000)),
  ),
);

const _jovemAnswers = IrsJovemAnswers(
  requested: true,
  wasDependentAtYearEnd: false,
  taxSituationRegularized: true,
  historyConfirmedComplete: true,
  incomeHistory: [
    IrsJovemIncomeYear(
      year: 2025,
      hadCategoryAIncome: true,
      hadCategoryBIncome: false,
      wasDependent: false,
      residentInPortugal: true,
    ),
  ],
);
