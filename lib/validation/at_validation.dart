import 'dart:convert';

import '../domain/models.dart';
import '../domain/money.dart';
import '../tax_engine/household_tax_engine.dart';
import '../tax_engine/irs_jovem_tax_engine.dart';
import '../tax_engine/tax_rules.dart';

/// Fields used to compare Taxy calculations with an anonymised AT assessment.
///
/// Values are always integer cents. A fixture may omit phase fields that are
/// not displayed in its source document, but the core settlement fields are
/// mandatory.
abstract final class AtValidationField {
  static const grossIncome = 'grossIncomeCents';
  static const specificDeduction = 'specificDeductionCents';
  static const netIncome = 'netIncomeCents';
  static const minimumExistence = 'minimumExistenceCents';
  static const taxableIncome = 'taxableIncomeCents';
  static const quotient = 'quotientCents';
  static const grossTax = 'grossTaxCents';
  static const exemptIncome = 'exemptIncomeCents';
  static const exemptTax = 'exemptTaxCents';
  static const solidarityTax = 'solidarityTaxCents';
  static const taxCredits = 'taxCreditsCents';
  static const taxDue = 'taxDueCents';
  static const withholding = 'withholdingCents';
  static const balance = 'balanceCents';

  static const all = <String>[
    grossIncome,
    specificDeduction,
    netIncome,
    minimumExistence,
    taxableIncome,
    quotient,
    grossTax,
    exemptIncome,
    exemptTax,
    solidarityTax,
    taxCredits,
    taxDue,
    withholding,
    balance,
  ];

  static const required = <String>{
    taxableIncome,
    grossTax,
    taxCredits,
    taxDue,
    withholding,
    balance,
  };

  static const labels = <String, String>{
    grossIncome: 'Rendimento bruto',
    specificDeduction: 'Deducao especifica',
    netIncome: 'Rendimento liquido da categoria',
    minimumExistence: 'Reducao por minimo de existencia',
    taxableIncome: 'Rendimento coletavel',
    quotient: 'Quociente',
    grossTax: 'Coleta antes de deducoes',
    exemptIncome: 'Rendimento isento',
    exemptTax: 'Coleta associada a isencao',
    solidarityTax: 'Taxa adicional de solidariedade',
    taxCredits: 'Deducoes a coleta',
    taxDue: 'Imposto apurado',
    withholding: 'Retencoes',
    balance: 'Saldo final',
  };
}

enum FixtureFailureCategory {
  ruleError('RULE_ERROR'),
  roundingError('ROUNDING_ERROR'),
  inputMappingError('INPUT_MAPPING_ERROR'),
  fixtureError('FIXTURE_ERROR'),
  unsupportedScenario('UNSUPPORTED_SCENARIO'),
  unknown('UNKNOWN');

  const FixtureFailureCategory(this.code);
  final String code;
}

class FixtureFailure {
  const FixtureFailure({
    required this.category,
    required this.message,
    this.field,
  });

  final FixtureFailureCategory category;
  final String message;
  final String? field;
}

class AtFixtureValidationException implements Exception {
  const AtFixtureValidationException(this.failure);
  final FixtureFailure failure;

  @override
  String toString() => '${failure.category.code}: ${failure.message}';
}

class OfficialAssessmentFixture {
  OfficialAssessmentFixture._({
    required this.fixtureSchemaVersion,
    required this.source,
    required this.sourceDocumentType,
    required this.anonymousCaseId,
    required this.taxYear,
    required this.jurisdiction,
    required this.civilStatus,
    required this.filingMode,
    required this.rulesVersion,
    required this.inputs,
    required this.officialResults,
    required this.notes,
  });

  static const currentSchemaVersion = 2;
  static const officialSources = <String>{'OFFICIAL_AT_ASSESSMENT'};
  static const officialDocumentTypes = <String>{
    'IRS_ASSESSMENT_DEMONSTRATION',
    'IRS_LIQUIDATION_STATEMENT',
  };

  final int fixtureSchemaVersion;
  final String source;
  final String sourceDocumentType;
  final String anonymousCaseId;
  final int taxYear;
  final TaxRegion jurisdiction;
  final CivilStatus civilStatus;
  final FilingMode filingMode;
  final String rulesVersion;
  final TaxSimulation inputs;
  final Map<String, int> officialResults;
  final String notes;

  bool get usesIrsJovem =>
      inputs.primaryIrsJovem.requested ||
      (inputs.secondaryTaxpayer?.irsJovem.requested ?? false);
  int get taxpayerCount => inputs.secondaryTaxpayer == null ? 1 : 2;
  int get dependentCount => inputs.dependents.length;

  factory OfficialAssessmentFixture.fromJson(
    Map<String, Object?> json, {
    bool allowTemplate = false,
  }) {
    _assertNoPersonalData(json);

    final schema = _requiredInt(json, 'fixtureSchemaVersion');
    if (schema != currentSchemaVersion) {
      throw _fixtureError(
        'fixtureSchemaVersion deve ser $currentSchemaVersion.',
      );
    }
    final source = _requiredString(json, 'source');
    if (!officialSources.contains(source)) {
      throw _fixtureError(
        'A origem "$source" nao e uma fonte oficial AT aceite.',
      );
    }
    final documentType = _requiredString(json, 'sourceDocumentType');
    if (!officialDocumentTypes.contains(documentType)) {
      throw _fixtureError(
        'O tipo de documento "$documentType" nao esta documentado.',
      );
    }
    final caseId = _requiredString(json, 'anonymousCaseId');
    if (!RegExp(r'^AT-\d{4}-[A-Z0-9-]{3,32}$').hasMatch(caseId)) {
      throw _fixtureError(
        'anonymousCaseId deve usar apenas um identificador anonimo, por '
        'exemplo AT-2026-CASE-001.',
      );
    }

    final taxYear = _requiredInt(json, 'taxYear');
    final jurisdiction = _enumByName<TaxRegion>(
      TaxRegion.values,
      _requiredString(json, 'jurisdiction'),
      'jurisdiction',
    );
    final civilStatus = _enumByName<CivilStatus>(
      CivilStatus.values,
      _requiredString(json, 'civilStatus'),
      'civilStatus',
    );
    final filingMode = _enumByName<FilingMode>(
      FilingMode.values,
      _requiredString(json, 'filingMode'),
      'filingMode',
    );
    final rulesVersion = _requiredString(json, 'rulesVersion');
    final notes = json['notes'] == null ? '' : json['notes'].toString();

    final inputJson = _requiredMap(json, 'inputs');
    final simulation = TaxSimulation.fromJson(inputJson);
    if (simulation.id != 'anonymous' ||
        simulation.name != 'Official assessment') {
      throw _fixtureError(
        'Os inputs devem usar id "anonymous" e name "Official assessment".',
      );
    }
    final secondaryId = simulation.secondaryTaxpayer?.id;
    if (secondaryId != null &&
        !const {'B', 'anonymous-b'}.contains(secondaryId)) {
      throw _fixtureError('O identificador do titular B não é anónimo.');
    }
    if (simulation.dependents.any(
      (dependent) =>
          !RegExp(r'^(?:dependent|anonymous-dependent|lab)-\d+$')
              .hasMatch(dependent.id),
    )) {
      throw _fixtureError('Um identificador de dependente não é anónimo.');
    }
    if (simulation.profile.taxYear != taxYear ||
        simulation.profile.region != jurisdiction ||
        simulation.profile.civilStatus != civilStatus ||
        simulation.profile.filingMode != filingMode) {
      throw _fixtureError(
        'Os metadados do caso nao coincidem com os inputs da simulacao.',
      );
    }
    final requiresSecondTaxpayer =
        civilStatus == CivilStatus.married ||
        civilStatus == CivilStatus.deFacto;
    if (requiresSecondTaxpayer != (simulation.secondaryTaxpayer != null)) {
      throw _fixtureError(
        requiresSecondTaxpayer
            ? 'Casados/unidos de facto exigem titular B.'
            : 'Um caso individual nao pode conter titular B.',
      );
    }
    if (!requiresSecondTaxpayer && filingMode != FilingMode.separate) {
      throw _fixtureError('Um caso individual deve usar separate.');
    }

    final rawResults = _requiredMap(json, 'officialResults');
    final results = <String, int>{};
    for (final entry in rawResults.entries) {
      if (!AtValidationField.all.contains(entry.key)) {
        throw _fixtureError('Campo AT desconhecido: ${entry.key}.');
      }
      if (entry.value == null && allowTemplate) continue;
      if (entry.value is! int) {
        throw _fixtureError('${entry.key} deve conter centimos inteiros.');
      }
      final value = entry.value! as int;
      if (entry.key != AtValidationField.balance && value < 0) {
        throw _fixtureError('${entry.key} nao pode ser negativo.');
      }
      results[entry.key] = value;
    }
    if (!allowTemplate) {
      final missing = AtValidationField.required.difference(
        results.keys.toSet(),
      );
      if (missing.isNotEmpty) {
        throw _fixtureError(
          'Resultados AT obrigatorios em falta: ${missing.join(', ')}.',
        );
      }
    }

    return OfficialAssessmentFixture._(
      fixtureSchemaVersion: schema,
      source: source,
      sourceDocumentType: documentType,
      anonymousCaseId: caseId,
      taxYear: taxYear,
      jurisdiction: jurisdiction,
      civilStatus: civilStatus,
      filingMode: filingMode,
      rulesVersion: rulesVersion,
      inputs: simulation,
      officialResults: Map.unmodifiable(results),
      notes: notes,
    );
  }
}

class AtFieldComparison {
  const AtFieldComparison({
    required this.field,
    required this.taxyCents,
    required this.officialCents,
  });

  final String field;
  final int taxyCents;
  final int officialCents;
  int get differenceCents => taxyCents - officialCents;
  bool get isExact => differenceCents == 0;
}

class AtFixtureComparison {
  const AtFixtureComparison({
    required this.fixture,
    required this.actualResults,
    required this.fields,
    this.failure,
  });

  final OfficialAssessmentFixture fixture;
  final Map<String, int> actualResults;
  final List<AtFieldComparison> fields;
  final FixtureFailure? failure;

  bool get isExact => failure == null && fields.every((field) => field.isExact);
  List<AtFieldComparison> get mismatches =>
      fields.where((field) => !field.isExact).toList(growable: false);
}

class AtValidationEngine {
  const AtValidationEngine();

  AtFixtureComparison compare(
    OfficialAssessmentFixture fixture,
    TaxRuleSet rules,
  ) {
    if (rules.taxYear != fixture.taxYear ||
        rules.jurisdiction != fixture.jurisdiction.name.toUpperCase() ||
        rules.rulesVersion != fixture.rulesVersion) {
      throw AtFixtureValidationException(
        const FixtureFailure(
          category: FixtureFailureCategory.fixtureError,
          message:
              'As regras carregadas nao correspondem aos metadados do caso.',
        ),
      );
    }

    final actual = calculateComparable(fixture.inputs, rules);
    final fields = fixture.officialResults.entries
        .map(
          (entry) => AtFieldComparison(
            field: entry.key,
            taxyCents: actual[entry.key]!,
            officialCents: entry.value,
          ),
        )
        .toList(growable: false);
    final mismatch = fields.any((field) => !field.isExact);
    return AtFixtureComparison(
      fixture: fixture,
      actualResults: actual,
      fields: fields,
      failure: mismatch
          ? const FixtureFailure(
              category: FixtureFailureCategory.unknown,
              message: 'Diferenca por classificar; requer analise humana.',
            )
          : null,
    );
  }

  Map<String, int> calculateComparable(
    TaxSimulation simulation,
    TaxRuleSet rules,
  ) {
    final selected = _calculateSelected(simulation, rules);
    final result = selected.result;
    final exemptTax = result.breakdown
        .where((line) {
          final label = line.label.toLowerCase();
          return label.contains('isento') &&
              (label.contains('imposto') || label.contains('coleta'));
        })
        .fold<int>(0, (total, line) => total + line.amount.cents.abs());
    final netIncome = result.grossIncome - result.specificDeduction;
    final isJoint =
        simulation.secondaryTaxpayer != null &&
        simulation.profile.filingMode == FilingMode.joint;
    final quotient = isJoint
        ? Money.fromCents(_roundHalfUp(result.taxableIncome.cents, 2))
        : result.taxableIncome;

    return Map.unmodifiable(<String, int>{
      AtValidationField.grossIncome: result.grossIncome.cents,
      AtValidationField.specificDeduction: result.specificDeduction.cents,
      AtValidationField.netIncome: netIncome.cents,
      AtValidationField.minimumExistence:
          result.minimumExistenceAllowance.cents,
      AtValidationField.taxableIncome: result.taxableIncome.cents,
      AtValidationField.quotient: quotient.cents,
      AtValidationField.grossTax: result.grossTax.cents,
      AtValidationField.exemptIncome: selected.exemptIncome.cents,
      AtValidationField.exemptTax: exemptTax,
      AtValidationField.solidarityTax: result.solidarityTax.cents,
      AtValidationField.taxCredits: result.taxCredits.cents,
      AtValidationField.taxDue: result.taxDue.cents,
      AtValidationField.withholding: result.withholding.cents,
      AtValidationField.balance: result.balance.cents,
    });
  }

  _SelectedCalculation _calculateSelected(
    TaxSimulation simulation,
    TaxRuleSet rules,
  ) {
    if (simulation.secondaryTaxpayer != null) {
      final comparison = HouseholdTaxEngine(rules)
          .compareWithIrsJovem(simulation);
      if (!comparison.available) {
        throw AtFixtureValidationException(
          FixtureFailure(
            category: FixtureFailureCategory.unsupportedScenario,
            message: comparison.normal.warnings.join(' '),
          ),
        );
      }
      final useJovem =
          usesIrsJovem(simulation) && comparison.withIrsJovem != null;
      final selected = useJovem ? comparison.withIrsJovem! : comparison.normal;
      final result = simulation.profile.filingMode == FilingMode.joint
          ? selected.joint!
          : selected.separate!;
      var exempt = Money.zero;
      if (useJovem) {
        if (comparison.primaryEligibility.status ==
            IrsJovemEligibility.eligible) {
          exempt += comparison.primaryEligibility.eligibleExemptIncome;
        }
        if (comparison.secondaryEligibility.status ==
            IrsJovemEligibility.eligible) {
          exempt += comparison.secondaryEligibility.eligibleExemptIncome;
        }
      }
      return _SelectedCalculation(result, exempt);
    }

    final comparison = IrsJovemTaxEngine(rules).compare(simulation);
    if (!comparison.normal.available) {
      throw AtFixtureValidationException(
        FixtureFailure(
          category: FixtureFailureCategory.unsupportedScenario,
          message: comparison.normal.warnings.join(' '),
        ),
      );
    }
    final useJovem =
        simulation.primaryIrsJovem.requested &&
        comparison.withIrsJovem?.available == true;
    return _SelectedCalculation(
      useJovem ? comparison.withIrsJovem! : comparison.normal,
      useJovem ? comparison.adjustment?.exemptIncome ?? Money.zero : Money.zero,
    );
  }
}

bool usesIrsJovem(TaxSimulation simulation) =>
    simulation.primaryIrsJovem.requested ||
    (simulation.secondaryTaxpayer?.irsJovem.requested ?? false);

class _SelectedCalculation {
  const _SelectedCalculation(this.result, this.exemptIncome);
  final TaxResult result;
  final Money exemptIncome;
}

class ValidationCoverage {
  const ValidationCoverage({
    required this.comparisons,
    this.referenceCalculationCount = 0,
  });
  final List<AtFixtureComparison> comparisons;
  final int referenceCalculationCount;

  int get totalCases => comparisons.length;
  int get exactCases => comparisons.where((item) => item.isExact).length;
  int get failedCases => totalCases - exactCases;

  Map<String, int> get casesByScope {
    final grouped = <String, int>{};
    for (final comparison in comparisons) {
      final fixture = comparison.fixture;
      final key =
          '${fixture.taxYear} ${fixture.jurisdiction.name} | '
          '${fixture.civilStatus.name}/${fixture.filingMode.name} | '
          'IRS Jovem ${fixture.usesIrsJovem ? 'sim' : 'nao'}';
      grouped.update(key, (value) => value + 1, ifAbsent: () => 1);
    }
    return Map.unmodifiable(grouped);
  }

  Map<String, int> get failuresByCategory {
    final grouped = <String, int>{};
    for (final comparison in comparisons) {
      final failure = comparison.failure;
      if (failure == null) continue;
      grouped.update(
        failure.category.code,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    return Map.unmodifiable(grouped);
  }
}

class AtValidationReport {
  const AtValidationReport();

  String render(ValidationCoverage coverage, {required DateTime generatedAt}) {
    final buffer = StringBuffer()
      ..writeln('# AT Validation Report')
      ..writeln()
      ..writeln(
        '> Relatorio gerado automaticamente. Apenas fixtures anonimizadas com '
        'origem oficial AT sao contabilizadas.',
      )
      ..writeln()
      ..writeln('- Gerado em: ${generatedAt.toUtc().toIso8601String()}')
      ..writeln('- Casos oficiais executados: ${coverage.totalCases}')
      ..writeln(
        '- Casos de referência manual executáveis: '
        '${coverage.referenceCalculationCount}',
      )
      ..writeln('- Correspondencias exatas: ${coverage.exactCases}')
      ..writeln('- Casos com diferencas: ${coverage.failedCases}')
      ..writeln('- Tolerancia global: 0 centimos')
      ..writeln()
      ..writeln('## Cobertura absoluta')
      ..writeln();
    if (coverage.casesByScope.isEmpty) {
      buffer.writeln('Ainda nao existem liquidacoes oficiais anonimizadas.');
    } else {
      for (final entry in coverage.casesByScope.entries) {
        buffer.writeln('- ${entry.key}: ${entry.value} caso(s)');
      }
    }
    buffer
      ..writeln()
      ..writeln('## Falhas por categoria')
      ..writeln();
    if (coverage.failuresByCategory.isEmpty) {
      buffer.writeln('- Nenhuma falha classificada.');
    } else {
      for (final entry in coverage.failuresByCategory.entries) {
        buffer.writeln('- ${entry.key}: ${entry.value}');
      }
    }
    buffer
      ..writeln()
      ..writeln('## Casos')
      ..writeln();
    if (coverage.comparisons.isEmpty) {
      buffer.writeln('Nenhum caso oficial foi inventado ou adicionado.');
    } else {
      for (final comparison in coverage.comparisons) {
        buffer.writeln(
          '- ${comparison.fixture.anonymousCaseId}: '
          '${comparison.isExact ? 'EXACT' : 'DIFFERENCE'}',
        );
      }
    }
    return buffer.toString();
  }
}

Never _fixtureError(String message) => throw AtFixtureValidationException(
  FixtureFailure(
    category: FixtureFailureCategory.fixtureError,
    message: message,
  ),
);

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    _fixtureError('$key e obrigatorio.');
  }
  return value.trim();
}

int _requiredInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) {
    _fixtureError('$key deve ser um inteiro.');
  }
  return value;
}

Map<String, Object?> _requiredMap(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! Map) _fixtureError('$key deve ser um objeto JSON.');
  return value.map((mapKey, value) => MapEntry(mapKey.toString(), value));
}

T _enumByName<T extends Enum>(List<T> values, String name, String field) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  _fixtureError('$field contem o valor desconhecido "$name".');
}

void _assertNoPersonalData(Map<String, Object?> json) {
  const forbiddenKeys = <String>{
    'nif',
    'iban',
    'email',
    'phone',
    'telefone',
    'name',
    'fullName',
    'address',
    'morada',
    'declarationNumber',
    'assessmentNumber',
    'documentNumber',
  };

  void inspect(Object? value, String path) {
    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key.toString();
        if (forbiddenKeys.contains(key) &&
            !(key == 'name' && path == r'$.inputs')) {
          _fixtureError('Campo de dados pessoais proibido: $path.$key.');
        }
        inspect(entry.value, '$path.$key');
      }
      return;
    }
    if (value is List) {
      for (var index = 0; index < value.length; index++) {
        inspect(value[index], '$path[$index]');
      }
      return;
    }
    if (value is! String) return;
    if (RegExp(
      r'\b(?:nome|contribuinte|titular|sujeito passivo)\s*:',
      caseSensitive: false,
    ).hasMatch(value)) {
      _fixtureError('Nome ou identificação textual potencial em $path.');
    }
    if (RegExp(
      r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
      caseSensitive: false,
    ).hasMatch(value)) {
      _fixtureError('Email detetado em $path.');
    }
    if (RegExp(
      r'\b[A-Z]{2}\d{2}[A-Z0-9]{11,30}\b',
      caseSensitive: false,
    ).hasMatch(value.replaceAll(' ', ''))) {
      _fixtureError('IBAN detetado em $path.');
    }
    if (RegExp(r'(?<!\d)(?:\+351[ -]?)?9\d{2}[ -]?\d{3}[ -]?\d{3}(?!\d)')
        .hasMatch(value)) {
      _fixtureError('Numero de telefone detetado em $path.');
    }
    for (final match in RegExp(r'(?<!\d)\d{9}(?!\d)').allMatches(value)) {
      if (_isValidPortugueseNif(match.group(0)!)) {
        _fixtureError('NIF detetado em $path.');
      }
    }
    if (RegExp(r'(?<!\d)\d{10,}(?!\d)').hasMatch(value)) {
      _fixtureError('Identificador numerico potencialmente pessoal em $path.');
    }
  }

  inspect(json, r'$');
}

bool _isValidPortugueseNif(String value) {
  if (!RegExp(r'^\d{9}$').hasMatch(value)) return false;
  final digits = value.split('').map(int.parse).toList(growable: false);
  var sum = 0;
  for (var index = 0; index < 8; index++) {
    sum += digits[index] * (9 - index);
  }
  final remainder = sum % 11;
  final check = remainder < 2 ? 0 : 11 - remainder;
  return digits[8] == check;
}

int _roundHalfUp(int numerator, int denominator) {
  if (denominator <= 0) throw ArgumentError.value(denominator, 'denominator');
  if (numerator >= 0) return (numerator + denominator ~/ 2) ~/ denominator;
  return -((-numerator + denominator ~/ 2) ~/ denominator);
}

Map<String, Object?> decodeFixtureJson(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map) {
    _fixtureError('A raiz da fixture deve ser um objeto JSON.');
  }
  return decoded.map((key, value) => MapEntry(key.toString(), value));
}
