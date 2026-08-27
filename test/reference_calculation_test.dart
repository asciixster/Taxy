import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/domain/models.dart';
import 'package:taxy_pt/domain/money.dart';
import 'package:taxy_pt/tax_engine/household_tax_engine.dart';
import 'package:taxy_pt/tax_engine/tax_rules.dart';

void main() {
  final file = File(
    'test/fixtures/reference_calculations/couples_2026_continent.json',
  );
  final document = (jsonDecode(file.readAsStringSync()) as Map)
      .cast<String, Object?>();
  final cases = (document['cases'] as List)
      .map((value) => (value as Map).cast<String, Object?>())
      .toList(growable: false);

  test('reference fixtures are manual, documented and versioned', () {
    expect(document['origin'], 'MANUALLY_AUDITED_REFERENCE');
    expect(document['taxYear'], 2026);
    expect(document['region'], 'CONTINENT');
    expect(document['civilStatus'], 'MARRIED');
    expect(document['rulesVersion'], '2026.4.0');
    expect((document['sources'] as List), hasLength(greaterThanOrEqualTo(4)));
    expect(cases, hasLength(9));
    for (final fixture in cases) {
      expect(fixture['description'], isNotEmpty);
      expect(fixture['calculationNotes'], isNotEmpty);
    }
  });

  for (final fixture in cases) {
    test('manual reference: ${fixture['id']}', () async {
      final repository = TaxRuleRepository((path) => File(path).readAsString());
      final rules = await repository.load(
        document['taxYear'] as int,
        document['region'] as String,
      );
      final comparison = HouseholdTaxEngine(rules)
          .compare(_simulation(fixture));
      expect(comparison.available, isTrue);
      final expected = (fixture['expected'] as Map).cast<String, Object?>();
      _expectResult(
        comparison.separate!,
        (expected['separate'] as Map).cast<String, Object?>(),
        '${fixture['id']} separate',
      );
      _expectResult(
        comparison.joint!,
        (expected['joint'] as Map).cast<String, Object?>(),
        '${fixture['id']} joint',
      );
      expect(comparison.difference.cents, expected['differenceCents']);
      final expectedMode = expected['recommendedMode'] as String;
      if (expectedMode == 'TIE') {
        expect(comparison.difference, Money.zero);
      } else {
        expect(comparison.recommendedMode?.name.toUpperCase(), expectedMode);
      }
    });
  }
}

void _expectResult(TaxResult actual, Map<String, Object?> expected, String id) {
  final values = <String, int>{
    'taxableIncomeCents': actual.taxableIncome.cents,
    'grossTaxCents': actual.grossTax.cents,
    'taxCreditsCents': actual.taxCredits.cents,
    'taxDueCents': actual.taxDue.cents,
    'withholdingCents': actual.withholding.cents,
    'balanceCents': actual.balance.cents,
  };
  for (final entry in expected.entries) {
    expect(values[entry.key], entry.value, reason: '$id ${entry.key}');
  }
}

TaxSimulation _simulation(Map<String, Object?> fixture) {
  final input = (fixture['input'] as Map).cast<String, Object?>();
  final ages = (input['dependentAges'] as List).cast<int>();
  DeductionInput deductions(String key) {
    final values = (input[key] as Map).cast<String, Object?>();
    Money value(String name) => Money.fromCents(values[name] as int? ?? 0);
    return DeductionInput(
      general: value('general'),
      health: value('health'),
      education: value('education'),
      rent: value('rent'),
      careHomes: value('careHomes'),
      invoiceVat15: value('invoiceVat15'),
      invoiceVat30: value('invoiceVat30'),
      invoiceVat35: value('invoiceVat35'),
      invoiceVat100: value('invoiceVat100'),
      ppr: value('ppr'),
    );
  }

  final timestamp = DateTime.utc(2026);
  return TaxSimulation(
    id: fixture['id'] as String,
    name: fixture['description'] as String,
    createdAt: timestamp,
    updatedAt: timestamp,
    profile: TaxpayerProfile(
      taxYear: 2026,
      age: input['ageA'] as int,
      civilStatus: CivilStatus.married,
      dependentAges: ages,
      fullYearResident: true,
      region: TaxRegion.continent,
      filingMode: FilingMode.joint,
    ),
    income: EmploymentIncome(
      entryMode: IncomeEntryMode.annual,
      gross: Money.fromCents(input['grossA'] as int),
      withholding: Money.fromCents(input['withholdingA'] as int),
      socialSecurity: Money.fromCents(input['socialSecurityA'] as int),
    ),
    deductions: deductions('deductionsA'),
    secondaryTaxpayer: TaxpayerInput(
      id: 'B',
      age: input['ageB'] as int,
      income: EmploymentIncome(
        entryMode: IncomeEntryMode.annual,
        gross: Money.fromCents(input['grossB'] as int),
        withholding: Money.fromCents(input['withholdingB'] as int),
        socialSecurity: Money.fromCents(input['socialSecurityB'] as int),
      ),
      deductions: deductions('deductionsB'),
    ),
    dependents: [
      for (var index = 0; index < ages.length; index++)
        Dependent(id: 'dependent-$index', ageAtYearEnd: ages[index]),
    ],
    dependentDeductions: deductions('dependentDeductions'),
  );
}
