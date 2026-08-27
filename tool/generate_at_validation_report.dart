import 'dart:io';
import 'dart:convert';

import 'package:taxy_pt/tax_engine/tax_rules.dart';
import 'package:taxy_pt/validation/at_validation.dart';

Future<void> main() async {
  final directory = Directory('test/fixtures/official_assessments');
  final files =
      directory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .where((file) => !file.path.endsWith('schema.example.json'))
          .toList(growable: false)
        ..sort((left, right) => left.path.compareTo(right.path));
  final repository = TaxRuleRepository((path) => File(path).readAsString());
  final comparisons = <AtFixtureComparison>[];
  for (final file in files) {
    final fixture = OfficialAssessmentFixture.fromJson(
      decodeFixtureJson(file.readAsStringSync()),
    );
    final rules = await repository.load(
      fixture.taxYear,
      fixture.jurisdiction.name,
    );
    comparisons.add(const AtValidationEngine().compare(fixture, rules));
  }
  final referenceFiles = Directory('test/fixtures/reference_calculations')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.json'));
  var referenceCount = 0;
  for (final file in referenceFiles) {
    final decoded = jsonDecode(file.readAsStringSync()) as Map;
    referenceCount += (decoded['cases'] as List? ?? const []).length;
  }
  final report = const AtValidationReport().render(
    ValidationCoverage(
      comparisons: comparisons,
      referenceCalculationCount: referenceCount,
    ),
    generatedAt: DateTime.now(),
  );
  File('AT_VALIDATION_REPORT.md').writeAsStringSync(report);
  stdout.write(report);
  if (comparisons.any((comparison) => !comparison.isExact)) exitCode = 1;
}
