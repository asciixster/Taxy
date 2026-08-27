import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/tax_engine/household_tax_engine.dart';
import 'package:taxy_pt/tax_engine/tax_engine.dart';
import 'package:taxy_pt/tax_engine/tax_rules.dart';

import 'support/official_assessment_fixture.dart';

void main() {
  final directory = Directory('test/fixtures/official_assessments');
  final files = directory
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.json'))
      .where((file) => !file.path.endsWith('schema.example.json'))
      .toList(growable: false);

  test('official assessment fixture directory is available', () {
    expect(directory.existsSync(), isTrue);
  });

  for (final file in files) {
    test('official assessment: ${file.path}', () async {
      final fixture = OfficialAssessmentFixture.fromFile(file);
      final repository = TaxRuleRepository((path) => File(path).readAsString());
      final profile = fixture.simulation.profile;
      final rules = await repository.load(profile.taxYear, profile.region.name);
      expect(rules.rulesVersion, fixture.rulesVersion);
      final result = profile.civilStatus.name == 'single'
          ? TaxEngine(rules).calculate(fixture.simulation)
          : (() {
              final comparison = HouseholdTaxEngine(rules)
                  .compare(fixture.simulation);
              expect(comparison.available, isTrue);
              return profile.filingMode.name == 'joint'
                  ? comparison.joint!
                  : comparison.separate!;
            })();
      final actual = <String, int>{
        'taxableIncomeCents': result.taxableIncome.cents,
        'grossTaxCents': result.grossTax.cents,
        'deductionsCents': result.taxCredits.cents,
        'taxDueCents': result.taxDue.cents,
        'withholdingCents': result.withholding.cents,
        'balanceCents': result.balance.cents,
      };
      for (final entry in fixture.expected.entries) {
        final tolerance = fixture.documentedRoundingCents[entry.key] ?? 0;
        final difference = (actual[entry.key]! - entry.value).abs();
        expect(
          difference,
          lessThanOrEqualTo(tolerance),
          reason:
              '${fixture.name}: ${entry.key}; ${fixture.notes}. Default is exact cents.',
        );
      }
    });
  }
}
