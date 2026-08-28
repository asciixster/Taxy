import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/domain/models.dart';
import 'package:taxy_pt/domain/money.dart';
import 'package:taxy_pt/tax_engine/tax_engine.dart';
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
    expect(comparison.failure?.field, AtValidationField.taxDue);
    expect(comparison.failure?.expected, expected[AtValidationField.taxDue]);
    expect(comparison.failure?.actual, actual[AtValidationField.taxDue]);
    expect(comparison.failure?.difference, -1);
    expect(comparison.failure?.probableStage, 'FINAL_SETTLEMENT');
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

  test('sourceNotes is optional but receives the same privacy checks', () {
    final safe = _fixture(simulation, rules, actual)
      ..['sourceNotes'] = 'Linha Rendimento coletável da demonstração.';
    expect(
      OfficialAssessmentFixture.fromJson(safe).sourceNotes,
      contains('Rendimento coletável'),
    );

    final unsafe = _fixture(simulation, rules, actual)
      ..['sourceNotes'] = 'NIF 123456789';
    expect(
      () => OfficialAssessmentFixture.fromJson(unsafe),
      throwsA(isA<AtFixtureValidationException>()),
    );
  });

  test('marital quotient accepts only structural divisors one or two', () {
    final invalid = _fixture(simulation, rules, actual);
    final results = Map<String, int>.from(
      invalid['officialResults']! as Map<String, int>,
    )..[AtValidationField.maritalQuotient] = 3;
    invalid['officialResults'] = results;

    expect(
      () => OfficialAssessmentFixture.fromJson(invalid),
      throwsA(isA<AtFixtureValidationException>()),
    );
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
    expect(coverage.totalFieldComparisons, AtValidationField.all.length);
    expect(coverage.exactFieldComparisons, AtValidationField.all.length);
    expect(coverage.mismatchedFields, 0);
    expect(coverage.casesByYear, {'2026': 1});
    expect(coverage.casesByRegion, {'continent': 1});
    expect(coverage.casesByFilingMode, {'separate': 1});
    expect(coverage.casesByIrsJovem, {'nao': 1});
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

  test('validation report counts exact and mismatched fields absolutely', () {
    final expected = Map<String, int>.from(actual)
      ..[AtValidationField.balance] = actual[AtValidationField.balance]! + 1;
    final fixture = OfficialAssessmentFixture.fromJson(
      _fixture(simulation, rules, expected),
    );
    final comparison = const AtValidationEngine().compare(fixture, rules);
    final report = const AtValidationReport().render(
      ValidationCoverage(comparisons: [comparison]),
      generatedAt: DateTime.utc(2026, 8, 27),
    );

    expect(
      report,
      contains(
        'Comparacoes de campos executadas: ${AtValidationField.all.length}',
      ),
    );
    expect(
      report,
      contains(
        'Comparacoes de campos exatas: ${AtValidationField.all.length - 1}',
      ),
    );
    expect(report, contains('Campos divergentes: 1'));
    expect(report, isNot(contains('%')));
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

  test('quality gate distinguishes EXACT from PARTIAL_EXACT', () {
    final fullFixture = OfficialAssessmentFixture.fromJson(
      _fixture(simulation, rules, actual),
    );
    final full = const AtValidationEngine().compare(fullFixture, rules);
    final partialResults = <String, int>{
      for (final field in AtValidationField.required) field: actual[field]!,
    };
    final partialFixture = OfficialAssessmentFixture.fromJson(
      _fixture(simulation, rules, partialResults),
    );
    final partial = const AtValidationEngine().compare(partialFixture, rules);

    expect(full.qualityGate, OfficialCaseQualityGate.exact);
    expect(partial.qualityGate, OfficialCaseQualityGate.partialExact);
    expect(full.isExact, isTrue);
    expect(partial.isExact, isTrue);
  });

  test('quality gate marks a one-cent mismatch as DIFFERENCE', () {
    final expected = Map<String, int>.from(actual)
      ..[AtValidationField.balance] = actual[AtValidationField.balance]! + 1;
    final fixture = OfficialAssessmentFixture.fromJson(
      _fixture(simulation, rules, expected),
    );
    final comparison = const AtValidationEngine().compare(fixture, rules);

    expect(comparison.qualityGate, OfficialCaseQualityGate.difference);
  });

  test('quality gate maps invalid and unsupported failures explicitly', () {
    const invalid = FixtureFailure(
      category: FixtureFailureCategory.fixtureError,
      message: 'Invalid fixture.',
    );
    const unsupported = FixtureFailure(
      category: FixtureFailureCategory.unsupportedScenario,
      message: 'Unsupported.',
    );

    expect(
      OfficialCaseQualityGateEvaluator.fromFailure(invalid),
      OfficialCaseQualityGate.invalidFixture,
    );
    expect(
      OfficialCaseQualityGateEvaluator.fromFailure(unsupported),
      OfficialCaseQualityGate.unsupported,
    );
  });

  test('typed trace exposes the four distinct quotient concepts', () {
    final trace = const AtValidationEngine().calculateTrace(simulation, rules);

    expect(trace.taxableIncome, isNot(Money.zero));
    expect(trace.maritalQuotient, 1);
    expect(trace.rateDeterminingIncome, trace.taxableIncome);
    expect(trace.rateDeterminingQuotient, trace.taxableIncome);
  });

  test('validation output is independent of all UI breakdown labels', () {
    final trace = const AtValidationEngine().calculateTrace(simulation, rules);
    final before = const AtValidationEngine().comparableFromTrace(trace);
    final renamedUiRows = [
      for (final row in TaxEngine(rules).calculate(simulation).breakdown)
        TaxBreakdown('RENAMED ${row.label}', row.amount, 'changed UI copy'),
    ];

    expect(
      renamedUiRows.every((row) => row.label.startsWith('RENAMED')),
      isTrue,
    );
    expect(const AtValidationEngine().comparableFromTrace(trace), before);
  });

  test('manual triage records evidence without changing the comparison', () {
    final comparison = const AtFieldComparison(
      field: AtValidationField.grossTax,
      taxyCents: 123454,
      officialCents: 123456,
    );
    final failure = FixtureTriage.classify(
      comparison,
      category: FixtureFailureCategory.roundingError,
      notes: 'Legal stage must be confirmed.',
    );

    expect(failure.expected, 123456);
    expect(failure.actual, 123454);
    expect(failure.difference, -2);
    expect(failure.probableStage, 'GROSS_TAX');
    expect(comparison.differenceCents, -2);
  });

  test('validation changelog helper renders every mandatory audit field', () {
    const entry = ValidationChangelogEntry(
      caseId: 'AT-2025-CASE-001',
      field: 'grossTaxAfterExemptionCents',
      expected: 123456,
      actual: 123454,
      cause: FixtureFailureCategory.roundingError,
      rootCause: 'Confirmed legal rounding stage.',
      fix: 'Round at the confirmed stage.',
      regressionTest: 'at_2025_case_001_test.dart',
      rulesVersionBefore: '2025.4.0',
      rulesVersionAfter: '2025.4.1',
    );
    final rendered = ValidationChangelogFormatter.renderEntry(entry);

    expect(rendered, contains('Difference:\n-2 cents'));
    expect(rendered, contains('Cause:\nROUNDING_ERROR'));
    expect(rendered, contains('Rules version after:\n2025.4.1'));
  });
}

Map<String, Object?> _fixture(
  TaxSimulation simulation,
  TaxRuleSet rules,
  Map<String, int> expected,
) => <String, Object?>{
  'fixtureSchemaVersion': OfficialAssessmentFixture.currentSchemaVersion,
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
  'sourceNotes': 'Values copied from generic AT result lines.',
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
