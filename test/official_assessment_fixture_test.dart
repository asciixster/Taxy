import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
