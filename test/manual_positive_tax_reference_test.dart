import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/domain/models.dart';
import 'package:taxy_pt/domain/money.dart';
import 'package:taxy_pt/tax_engine/tax_engine.dart';
import 'package:taxy_pt/tax_engine/tax_rules.dart';

void main() {
  final file = File(
    'test/fixtures/reference_calculations/'
    'single_2025_continent_positive_tax.json',
  );
  final document = (jsonDecode(file.readAsStringSync()) as Map)
      .cast<String, Object?>();
  final fixture = ((document['cases'] as List).single as Map)
      .cast<String, Object?>();
  final input = (fixture['input'] as Map).cast<String, Object?>();
  final expected = (fixture['expected'] as Map).cast<String, Object?>();

  test('positive-tax reference is manual and never official AT evidence', () {
    expect(document['source'], 'MANUALLY_AUDITED_REFERENCE');
    expect(document['source'], isNot('OFFICIAL_AT_ASSESSMENT'));
    expect(file.path, contains('reference_calculations'));
    expect(file.path, isNot(contains('official_assessments')));
    expect(
      document['disclaimer'],
      'Este caso valida consistência matemática e regressão interna. '
      'Não constitui validação contra liquidação oficial da AT.',
    );
    expect((fixture['audit'] as Map).keys, hasLength(greaterThanOrEqualTo(12)));
    expect(
      (fixture['candidateCorrection'] as Map)['classification'],
      'REFERENCE_ERROR',
    );
  });

  test('positive-tax reference matches Taxy at zero cents tolerance', () async {
    final repository = TaxRuleRepository((path) => File(path).readAsString());
    final rules = await repository.load(2025, 'CONTINENT');
    final result = TaxEngine(rules).calculate(_simulation(input));

    expect(result.available, isTrue);
    final actual = <String, int>{
      'grossIncomeCents': result.grossIncome.cents,
      'specificDeductionCents': result.specificDeduction.cents,
      'taxableIncomeCents': result.taxableIncome.cents,
      'grossTaxCents': result.grossTax.cents,
      'generalExpenseCreditCents': result.trace.generalExpenseCredit.cents,
      'healthCreditCents': result.trace.healthCredit.cents,
      'totalTaxCreditsCents': result.taxCredits.cents,
      'finalTaxDueCents': result.taxDue.cents,
      'withholdingCents': result.withholding.cents,
      'balanceCents': result.balance.cents,
    };

    for (final entry in expected.entries) {
      expect(
        actual[entry.key],
        entry.value,
        reason: '${fixture['id']} ${entry.key}; tolerance is 0 cents',
      );
    }
  });
}

TaxSimulation _simulation(Map<String, Object?> input) {
  Money money(String key) => Money.fromCents(input[key] as int);
  final timestamp = DateTime.utc(2026);
  return TaxSimulation(
    id: 'manual-positive-tax-2025-001',
    name: 'Manual positive-tax reference',
    createdAt: timestamp,
    updatedAt: timestamp,
    profile: TaxpayerProfile(
      taxYear: 2025,
      age: input['age'] as int,
      civilStatus: CivilStatus.single,
      dependentAges: const [],
      fullYearResident: true,
      region: TaxRegion.continent,
      filingMode: FilingMode.separate,
    ),
    income: EmploymentIncome(
      entryMode: IncomeEntryMode.annual,
      gross: money('grossIncomeCents'),
      withholding: money('withholdingCents'),
      socialSecurity: money('mandatoryContributionsCents'),
    ),
    deductions: DeductionInput(
      general: money('generalExpensesCents'),
      health: money('healthExpensesCents'),
      education: money('educationExpensesCents'),
      rent: money('rentExpensesCents'),
      careHomes: money('careHomeExpensesCents'),
      invoiceVat15: money('invoiceVat15Cents'),
      invoiceVat30: money('invoiceVat30Cents'),
      invoiceVat35: money('invoiceVat35Cents'),
      invoiceVat100: money('invoiceVat100Cents'),
      ppr: money('pprCents'),
    ),
  );
}
