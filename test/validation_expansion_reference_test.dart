import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/tax_engine/tax_rules.dart';
import 'package:taxy_pt/validation/at_validation.dart';
import 'package:taxy_pt/validation/manual_reference_validation.dart';

void main() {
  final file = File(
    'test/fixtures/reference_calculations/'
    'validation_expansion_2025_continent.json',
  );
  final document = ManualReferenceDocument.fromJson(
    (jsonDecode(file.readAsStringSync()) as Map).cast<String, Object?>(),
  );

  test(
    '0.8 references have manual provenance and independent audit trails',
    () {
      expect(document.cases, hasLength(7));
      expect(document.cases.map((item) => item.scenario).toSet(), {
        'single positive tax',
        'deductions',
        'married separate',
        'married joint',
        'PPR couple',
        'minimum existence',
        'IRS Jovem positive tax',
      });
      for (final fixture in document.cases) {
        expect(fixture.audit, hasLength(greaterThanOrEqualTo(5)));
        expect(fixture.inputEvidence, isNotEmpty);
        expect(fixture.expected, isNotEmpty);
      }
    },
  );

  for (final fixture in document.cases) {
    test('${fixture.id} passes at zero cents tolerance', () async {
      final repository = TaxRuleRepository((path) => File(path).readAsString());
      final rules = await repository.load(
        document.taxYear,
        document.jurisdiction.name,
      );
      final comparison = const ManualReferenceRunner().compare(
        document,
        fixture,
        rules,
      );
      expect(
        comparison.status,
        ManualReferenceStatus.pass,
        reason: comparison.mismatches
            .map(
              (field) =>
                  '${field.field}: ${field.expected} != ${field.actual} '
                  '(${field.difference >= 0 ? '+' : ''}${field.difference})',
            )
            .join('; '),
      );
      expect(comparison.mismatches, isEmpty);
    });
  }

  test(
    'same household produces a deterministic separate/joint difference',
    () async {
      final repository = TaxRuleRepository((path) => File(path).readAsString());
      final rules = await repository.load(2025, 'CONTINENT');
      final separate = document.cases.firstWhere(
        (item) => item.id == 'couple-one-dependent-separate-2025-001',
      );
      final joint = document.cases.firstWhere(
        (item) => item.id == 'couple-one-dependent-joint-2025-001',
      );
      final runner = const ManualReferenceRunner();
      final separateResult = runner.compare(document, separate, rules);
      final jointResult = runner.compare(document, joint, rules);
      final separateDue = separateResult.fields
          .singleWhere((field) => field.field == 'finalTaxDueCents')
          .actual;
      final jointDue = jointResult.fields
          .singleWhere((field) => field.field == 'finalTaxDueCents')
          .actual;
      expect(separateDue - jointDue, 53603);
    },
  );

  test(
    'PPR caps remain individual and unused capacity is not transferred',
    () async {
      final repository = TaxRuleRepository((path) => File(path).readAsString());
      final rules = await repository.load(2025, 'CONTINENT');
      final fixture = document.cases.firstWhere(
        (item) => item.id == 'couple-ppr-individual-caps-joint-2025-001',
      );
      final comparison = const ManualReferenceRunner().compare(
        document,
        fixture,
        rules,
      );
      expect(
        comparison.fields
            .singleWhere((field) => field.field == 'pprCreditCents')
            .actual,
        50000,
      );
    },
  );

  test('malformed reference without provenance is rejected', () {
    final raw = (jsonDecode(file.readAsStringSync()) as Map)
        .cast<String, Object?>();
    final cases = (raw['cases'] as List).map((value) {
      final copy = Map<String, Object?>.from(
        (value as Map).cast<String, Object?>(),
      );
      copy.remove('inputEvidence');
      return copy;
    }).toList();
    expect(
      () => ManualReferenceDocument.fromJson({...raw, 'cases': cases}),
      throwsFormatException,
    );
  });

  test('manual source cannot be promoted to official evidence', () {
    final raw = (jsonDecode(file.readAsStringSync()) as Map)
        .cast<String, Object?>();
    expect(
      () => ManualReferenceDocument.fromJson({
        ...raw,
        'source': 'OFFICIAL_AT_ASSESSMENT',
      }),
      throwsFormatException,
    );
  });

  test('report keeps manual PASS counts outside official quality gates', () {
    final report = const AtValidationReport().render(
      const ValidationCoverage(
        comparisons: [],
        referenceCalculationCount: 29,
        manualReferencesExecuted: 8,
        manualReferencesPassing: 8,
        manualReferencesFailing: 0,
        manualCoverage: {'deductions': 1},
      ),
      generatedAt: DateTime.utc(2026, 8, 28),
    );
    expect(report, contains('Casos oficiais executados: 0'));
    expect(report, contains('Referências manuais PASS: 8'));
    expect(report, contains('Referências manuais FAIL: 0'));
    expect(report, contains('Casos oficiais EXACT: 0'));
    expect(report, isNot(contains('Manual EXACT')));
  });
}
