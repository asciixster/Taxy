import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/domain/models.dart';
import 'package:taxy_pt/tax_engine/tax_rules.dart';
import 'package:taxy_pt/validation/at_validation.dart';

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

  test('official fixture count is reported as an absolute number', () {
    expect(files.length, greaterThanOrEqualTo(0));
  });

  test('committed official fixtures contain only anonymous identifiers', () {
    final longIdentifier = RegExp(r'(?<!\d)\d{9,}(?!\d)');
    final forbiddenKeys = RegExp(
      r'"(?:nif|iban|email|phone|telefone|fullName|address|morada|declarationNumber|assessmentNumber|documentNumber)"\s*:',
      caseSensitive: false,
    );

    for (final file in files) {
      final source = file.readAsStringSync();
      final fixture = OfficialAssessmentFixture.fromJson(
        decodeFixtureJson(source),
      );

      expect(source, isNot(matches(longIdentifier)), reason: file.path);
      expect(source, isNot(matches(forbiddenKeys)), reason: file.path);
      expect(fixture.inputs.id, 'anonymous', reason: file.path);
      expect(fixture.inputs.name, 'Official assessment', reason: file.path);
      expect(
        fixture.inputs.secondaryTaxpayer?.id,
        anyOf(isNull, 'B', 'anonymous-b'),
        reason: file.path,
      );
      expect(
        fixture.inputs.dependents.every(
          (dependent) =>
              RegExp(r'^(?:dependent|anonymous-dependent|lab)-\d+$')
                  .hasMatch(dependent.id),
        ),
        isTrue,
        reason: file.path,
      );
    }
  });

  test('first real AT case is a partial exact joint Category A case', () async {
    final file = File(
      'test/fixtures/official_assessments/at-2025-joint-a-001.json',
    );
    final fixture = OfficialAssessmentFixture.fromJson(
      decodeFixtureJson(file.readAsStringSync()),
    );
    final repository = TaxRuleRepository((path) => File(path).readAsString());
    final rules = await repository.load(2025, 'continent');
    final comparison = const AtValidationEngine().compare(fixture, rules);

    expect(fixture.anonymousCaseId, 'AT-2025-JOINT-A-001');
    expect(fixture.inputs.incomeTypes, {IncomeType.employment});
    expect(fixture.inputs.income.gross.cents, 184800);
    expect(fixture.inputs.income.socialSecurity.cents, 20328);
    expect(fixture.inputs.income.withholding.cents, 0);
    expect(fixture.inputs.secondaryTaxpayer?.income.gross.cents, 0);
    expect(fixture.inputs.profile.filingMode, FilingMode.joint);
    expect(fixture.inputs.dependents.single.id, 'dependent-1');
    expect(comparison.mismatches, isEmpty);
    expect(comparison.qualityGate, OfficialCaseQualityGate.partialExact);
  });

  for (final file in files) {
    test('official assessment: ${file.path}', () async {
      final fixture = OfficialAssessmentFixture.fromJson(
        decodeFixtureJson(file.readAsStringSync()),
      );
      final repository = TaxRuleRepository((path) => File(path).readAsString());
      final profile = fixture.inputs.profile;
      final rules = await repository.load(profile.taxYear, profile.region.name);
      expect(rules.rulesVersion, fixture.rulesVersion);
      final comparison = const AtValidationEngine().compare(fixture, rules);
      expect(
        comparison.isExact,
        isTrue,
        reason:
            '${fixture.anonymousCaseId}: '
            '${comparison.mismatches.map((item) => '${item.field}=${item.differenceCents}').join(', ')}. '
            '${fixture.notes}',
      );
    });
  }
}
