import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/domain/models.dart';
import 'package:taxy_pt/domain/money.dart';
import 'package:taxy_pt/tax_engine/tax_rules.dart';
import 'package:taxy_pt/validation/at_validation.dart';

void main() {
  late TaxRuleSet rules;
  late TaxSimulation simulation;
  late Map<String, int> actual;

  setUpAll(() async {
    rules = await TaxRuleRepository((path) => File(path).readAsString())
        .load(2026, 'continent');
    simulation = _simulation();
    actual = const AtValidationEngine().calculateComparable(simulation, rules);
  });

  test(
    'valid official fixture compares every supplied field at zero cents',
    () {
      final fixture = OfficialAssessmentFixture.fromJson(
        _fixture(simulation, rules, actual),
      );
      final comparison = const AtValidationEngine().compare(fixture, rules);

      expect(comparison.isExact, isTrue);
      expect(comparison.fields.length, AtValidationField.all.length);
      expect(comparison.mismatches, isEmpty);
    },
  );

  test('one cent difference fails closed and remains UNKNOWN until triage', () {
    final expected = Map<String, int>.from(actual)
      ..[AtValidationField.taxDue] = actual[AtValidationField.taxDue]! + 1;
    final fixture = OfficialAssessmentFixture.fromJson(
      _fixture(simulation, rules, expected),
    );
    final comparison = const AtValidationEngine().compare(fixture, rules);

    expect(comparison.isExact, isFalse);
    expect(comparison.mismatches.single.differenceCents, -1);
    expect(comparison.failure?.category, FixtureFailureCategory.unknown);
  });

  test(
    'optional phase fields may be absent but core outputs are mandatory',
    () {
      final core = <String, int>{
        for (final key in AtValidationField.required) key: actual[key]!,
      };
      final fixture = OfficialAssessmentFixture.fromJson(
        _fixture(simulation, rules, core),
      );
      expect(fixture.officialResults.keys, AtValidationField.required);

      core.remove(AtValidationField.balance);
      expect(
        () => OfficialAssessmentFixture.fromJson(
          _fixture(simulation, rules, core),
        ),
        throwsA(isA<AtFixtureValidationException>()),
      );
    },
  );

  test('non-official sources are rejected', () {
    final json = _fixture(simulation, rules, actual)
      ..['source'] = 'MANUAL_REFERENCE';
    expect(
      () => OfficialAssessmentFixture.fromJson(json),
      throwsA(
        isA<AtFixtureValidationException>().having(
          (error) => error.failure.category,
          'category',
          FixtureFailureCategory.fixtureError,
        ),
      ),
    );
  });

  test('metadata inconsistent with simulation is rejected', () {
    final json = _fixture(simulation, rules, actual)
      ..['jurisdiction'] = 'azores';
    expect(
      () => OfficialAssessmentFixture.fromJson(json),
      throwsA(isA<AtFixtureValidationException>()),
    );
  });

  test('personal data patterns are rejected and never anonymised', () {
    final unsafeValues = <String>[
      'joao@example.pt',
      'PT50000201231234567890154',
      '+351 912 345 678',
      'NIF 123456789',
      'identificador 123456789012345',
    ];
    for (final unsafe in unsafeValues) {
      final json = _fixture(simulation, rules, actual)..['notes'] = unsafe;
      expect(
        () => OfficialAssessmentFixture.fromJson(json),
        throwsA(isA<AtFixtureValidationException>()),
        reason: unsafe,
      );
      expect(
        json['notes'],
        unsafe,
        reason: 'The loader must not rewrite data.',
      );
    }
  });

  test('personal identifier keys are rejected recursively', () {
    for (final key in ['nif', 'iban', 'email', 'phone', 'address']) {
      final json = _fixture(simulation, rules, actual)..[key] = 'redacted';
      expect(
        () => OfficialAssessmentFixture.fromJson(json),
        throwsA(isA<AtFixtureValidationException>()),
        reason: key,
      );
    }
  });

  test('personal name labels and non-anonymous taxpayer ids are rejected', () {
    final named = _fixture(simulation, rules, actual)
      ..['notes'] = 'Nome: João da Silva';
    expect(
      () => OfficialAssessmentFixture.fromJson(named),
      throwsA(isA<AtFixtureValidationException>()),
    );

    final unsafeInputs = Map<String, Object?>.from(simulation.toJson())
      ..['id'] = 'assessment-987';
    final identified = _fixture(simulation, rules, actual)
      ..['inputs'] = unsafeInputs;
    expect(
      () => OfficialAssessmentFixture.fromJson(identified),
      throwsA(isA<AtFixtureValidationException>()),
    );
  });

  test('anonymous id follows stable non-personal convention', () {
    final json = _fixture(simulation, rules, actual)
      ..['anonymousCaseId'] = 'Joao Silva';
    expect(
      () => OfficialAssessmentFixture.fromJson(json),
      throwsA(isA<AtFixtureValidationException>()),
    );
  });

  test('rule version mismatch is a fixture error', () {
    final json = _fixture(simulation, rules, actual)
      ..['rulesVersion'] = '2099.0.0';
    final fixture = OfficialAssessmentFixture.fromJson(json);
    expect(
      () => const AtValidationEngine().compare(fixture, rules),
      throwsA(
        isA<AtFixtureValidationException>().having(
          (error) => error.failure.category,
          'category',
          FixtureFailureCategory.fixtureError,
        ),
      ),
    );
  });

  test('coverage exposes absolute counts and scope groups', () {
    final fixture = OfficialAssessmentFixture.fromJson(
      _fixture(simulation, rules, actual),
    );
    final exact = const AtValidationEngine().compare(fixture, rules);
    final coverage = ValidationCoverage(comparisons: [exact]);

    expect(coverage.totalCases, 1);
    expect(coverage.exactCases, 1);
    expect(coverage.failedCases, 0);
    expect(coverage.casesByScope.values.single, 1);
  });

  test('empty validation report says zero and does not claim coverage', () {
    final report = const AtValidationReport().render(
      const ValidationCoverage(comparisons: []),
      generatedAt: DateTime.utc(2026, 8, 27),
    );
    expect(report, contains('Casos oficiais executados: 0'));
    expect(report, contains('Nenhum caso oficial foi inventado'));
    expect(report, contains('Tolerancia global: 0 centimos'));
  });

  test('all failure categories have stable audit codes', () {
    expect(
      FixtureFailureCategory.values.map((value) => value.code),
      containsAll([
        'RULE_ERROR',
        'ROUNDING_ERROR',
        'INPUT_MAPPING_ERROR',
        'FIXTURE_ERROR',
        'UNSUPPORTED_SCENARIO',
        'UNKNOWN',
      ]),
    );
  });
}

Map<String, Object?> _fixture(
  TaxSimulation simulation,
  TaxRuleSet rules,
  Map<String, int> expected,
) => <String, Object?>{
  'fixtureSchemaVersion': 2,
  'source': 'OFFICIAL_AT_ASSESSMENT',
  'sourceDocumentType': 'IRS_ASSESSMENT_DEMONSTRATION',
  'anonymousCaseId': 'AT-2026-CASE-001',
  'taxYear': 2026,
  'jurisdiction': 'continent',
  'civilStatus': 'single',
  'filingMode': 'separate',
  'rulesVersion': rules.rulesVersion,
  'inputs': simulation.toJson(),
  'officialResults': expected,
  'notes': 'Anonymous unit-test fixture, not an official assessment.',
};

TaxSimulation _simulation() => TaxSimulation(
  id: 'anonymous',
  name: 'Official assessment',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  profile: const TaxpayerProfile(
    taxYear: 2026,
    age: 35,
    civilStatus: CivilStatus.single,
    dependentAges: [],
    fullYearResident: true,
    region: TaxRegion.continent,
    filingMode: FilingMode.separate,
  ),
  income: const EmploymentIncome(
    entryMode: IncomeEntryMode.annual,
    gross: Money.fromCents(3000000),
    withholding: Money.fromCents(350000),
    socialSecurity: Money.fromCents(330000),
  ),
  deductions: const DeductionInput(
    general: Money.fromCents(90000),
    health: Money.fromCents(40000),
  ),
);
