import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/tax_engine/tax_rules.dart';
import 'package:taxy_pt/validation/manual_reference_validation.dart';

void main() {
  final file = File(
    'test/fixtures/reference_calculations/'
    'single_2025_continent_positive_tax.json',
  );
  final document = ManualReferenceDocument.fromJson(
    (jsonDecode(file.readAsStringSync()) as Map).cast<String, Object?>(),
  );

  test('positive-tax reference remains manual and structurally audited', () {
    expect(document.cases, hasLength(1));
    expect(document.cases.single.id, 'single-category-a-positive-tax-2025-001');
    expect(document.cases.single.audit, hasLength(greaterThanOrEqualTo(10)));
    expect(file.path, contains('reference_calculations'));
    expect(file.path, isNot(contains('official_assessments')));
  });

  test('positive-tax reference matches at zero cents tolerance', () async {
    final repository = TaxRuleRepository((path) => File(path).readAsString());
    final rules = await repository.load(2025, 'CONTINENT');
    final comparison = const ManualReferenceRunner().compare(
      document,
      document.cases.single,
      rules,
    );
    expect(comparison.status, ManualReferenceStatus.pass);
    expect(comparison.mismatches, isEmpty);
    expect(comparison.fields, hasLength(12));
  });
}
