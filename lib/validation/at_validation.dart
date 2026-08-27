import 'dart:convert';

import '../domain/models.dart';
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
  static const minimumExistence = 'minimumExistenceAllowanceCents';
  static const taxableIncome = 'taxableIncomeCents';
  static const maritalQuotient = 'maritalQuotient';
  static const rateDeterminingIncome = 'rateDeterminingIncomeCents';
  static const rateDeterminingQuotient = 'rateDeterminingQuotientCents';
  static const bracketBaseTax = 'bracketBaseTaxCents';
  static const bracketExcess = 'bracketExcessCents';
  static const marginalRate = 'marginalRatePpm';
  static const taxBeforeExemption = 'taxBeforeExemptionCents';
  static const exemptIncome = 'exemptIncomeCents';
  static const taxAllocatedToExemptIncome = 'taxAllocatedToExemptIncomeCents';
  static const grossTaxAfterExemption = 'grossTaxAfterExemptionCents';
  static const dependentCredits = 'dependentCreditsCents';
  static const generalExpenseCredit = 'generalExpenseCreditCents';
  static const healthCredit = 'healthCreditCents';
  static const educationCredit = 'educationCreditCents';
  static const careHomeCredit = 'careHomeCreditCents';
  static const rentCredit = 'rentCreditCents';
  static const invoiceVatCredit = 'invoiceVatCreditCents';
  static const pprCredit = 'pprCreditCents';
  static const overallDeductionsCap = 'overallDeductionsCapCents';
  static const totalTaxCredits = 'totalTaxCreditsCents';
  static const solidarityTax = 'solidarityTaxCents';
  static const finalTaxDue = 'finalTaxDueCents';
  static const withholding = 'withholdingCents';
  static const balance = 'balanceCents';

  // Source compatibility for call sites written against schema v2 names.
  static const grossTax = grossTaxAfterExemption;
  static const taxCredits = totalTaxCredits;
  static const taxDue = finalTaxDue;

  static const all = <String>[
    grossIncome,
    specificDeduction,
    netIncome,
    minimumExistence,
    taxableIncome,
    maritalQuotient,
    rateDeterminingIncome,
    rateDeterminingQuotient,
    bracketBaseTax,
    bracketExcess,
    marginalRate,
    taxBeforeExemption,
    exemptIncome,
    taxAllocatedToExemptIncome,
    grossTaxAfterExemption,
    dependentCredits,
    generalExpenseCredit,
    healthCredit,
    educationCredit,
    careHomeCredit,
    rentCredit,
    invoiceVatCredit,
    pprCredit,
    overallDeductionsCap,
    totalTaxCredits,
    solidarityTax,
    finalTaxDue,
    withholding,
    balance,
  ];

  static const required = <String>{
    taxableIncome,
    grossTaxAfterExemption,
    totalTaxCredits,
    finalTaxDue,
    withholding,
    balance,
  };

  static const scalar = <String>{maritalQuotient, marginalRate};

  static const labels = <String, String>{
    grossIncome: 'Rendimento bruto',
    specificDeduction: 'Deducao especifica',
    netIncome: 'Rendimento liquido da categoria',
    minimumExistence: 'Reducao por minimo de existencia',
    taxableIncome: 'Rendimento coletavel',
    maritalQuotient: 'Quociente conjugal (divisor)',
    rateDeterminingIncome: 'Rendimento para determinação da taxa',
    rateDeterminingQuotient: 'Quociente para determinação da taxa',
    bracketBaseTax: 'Coleta da parcela a abater/base do escalão',
    bracketExcess: 'Excesso no escalão marginal',
    marginalRate: 'Taxa marginal (ppm)',
    taxBeforeExemption: 'Coleta antes da imputação da isenção',
    exemptIncome: 'Rendimento isento',
    taxAllocatedToExemptIncome: 'Coleta imputada ao rendimento isento',
    grossTaxAfterExemption: 'Coleta após isenção',
    dependentCredits: 'Dedução por dependentes',
    generalExpenseCredit: 'Dedução de despesas gerais',
    healthCredit: 'Dedução de saúde',
    educationCredit: 'Dedução de educação',
    careHomeCredit: 'Dedução de lares',
    rentCredit: 'Dedução de rendas',
    invoiceVatCredit: 'Dedução de IVA por fatura',
    pprCredit: 'Dedução de PPR',
    overallDeductionsCap: 'Limite global de deduções',
    totalTaxCredits: 'Deduções à coleta aplicadas',
    solidarityTax: 'Taxa adicional de solidariedade',
    finalTaxDue: 'Imposto apurado',
    withholding: 'Retencoes',
    balance: 'Saldo final',
  };

  static const probableStages = <String, String>{
    grossIncome: 'INPUTS',
    specificDeduction: 'SPECIFIC_DEDUCTION',
    netIncome: 'SPECIFIC_DEDUCTION',
    minimumExistence: 'MINIMUM_EXISTENCE',
    taxableIncome: 'TAXABLE_INCOME',
    maritalQuotient: 'FILING_MODE',
    rateDeterminingIncome: 'RATE_DETERMINATION',
    rateDeterminingQuotient: 'RATE_DETERMINATION',
    bracketBaseTax: 'BRACKETS',
    bracketExcess: 'BRACKETS',
    marginalRate: 'BRACKETS',
    taxBeforeExemption: 'IRS_JOVEM_EXEMPTION',
    exemptIncome: 'IRS_JOVEM_EXEMPTION',
    taxAllocatedToExemptIncome: 'IRS_JOVEM_EXEMPTION',
    grossTaxAfterExemption: 'GROSS_TAX',
    dependentCredits: 'TAX_CREDITS',
    generalExpenseCredit: 'TAX_CREDITS',
    healthCredit: 'TAX_CREDITS',
    educationCredit: 'TAX_CREDITS',
    careHomeCredit: 'TAX_CREDITS',
    rentCredit: 'TAX_CREDITS',
    invoiceVatCredit: 'TAX_CREDITS',
    pprCredit: 'TAX_CREDITS',
    overallDeductionsCap: 'DEDUCTIONS_CAP',
    totalTaxCredits: 'TAX_CREDITS',
    solidarityTax: 'SOLIDARITY_TAX',
    finalTaxDue: 'FINAL_SETTLEMENT',
    withholding: 'WITHHOLDING',
    balance: 'FINAL_SETTLEMENT',
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
    this.expected,
    this.actual,
    this.difference,
    this.probableStage,
    this.notes = '',
  });

  final FixtureFailureCategory category;
  final String message;
  final String? field;
  final int? expected;
  final int? actual;
  final int? difference;
  final String? probableStage;
  final String notes;
}

/// Explicit human triage helper. It records a decision but never changes a
/// fixture, a result or a tolerance automatically.
abstract final class FixtureTriage {
  static FixtureFailure classify(
    AtFieldComparison comparison, {
    required FixtureFailureCategory category,
    String? probableStage,
    String notes = '',
  }) => FixtureFailure(
    category: category,
    message: 'Divergência classificada manualmente.',
    field: comparison.field,
    expected: comparison.officialCents,
    actual: comparison.taxyCents,
    difference: comparison.differenceCents,
    probableStage:
        probableStage ?? AtValidationField.probableStages[comparison.field],
    notes: notes,
  );
}

final class ValidationChangelogEntry {
  const ValidationChangelogEntry({
    required this.caseId,
    required this.field,
    required this.expected,
    required this.actual,
    required this.cause,
    required this.rootCause,
    required this.fix,
    required this.regressionTest,
    required this.rulesVersionBefore,
    required this.rulesVersionAfter,
  });

  final String caseId;
  final String field;
  final int expected;
  final int actual;
  final FixtureFailureCategory cause;
  final String rootCause;
  final String fix;
  final String regressionTest;
  final String rulesVersionBefore;
  final String rulesVersionAfter;
  int get difference => actual - expected;
}

abstract final class ValidationChangelogFormatter {
  static String renderEntry(ValidationChangelogEntry entry) =>
      '''Case:
${entry.caseId}

Field:
${entry.field}

Expected:
${entry.expected}

Actual:
${entry.actual}

Difference:
${entry.difference >= 0 ? '+' : ''}${entry.difference} cents

Cause:
${entry.cause.code}

Root cause:
${entry.rootCause}

Fix:
${entry.fix}

Regression test:
${entry.regressionTest}

Rules version before:
${entry.rulesVersionBefore}

Rules version after:
${entry.rulesVersionAfter}''';
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
    required this.sourceNotes,
  });

  static const currentSchemaVersion = 3;
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
  final String sourceNotes;

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
    final sourceNotes = json['sourceNotes'] == null
        ? ''
        : json['sourceNotes'].toString();

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
        throw _fixtureError('${entry.key} deve conter um inteiro.');
      }
      final value = entry.value! as int;
      if (entry.key != AtValidationField.balance && value < 0) {
        throw _fixtureError('${entry.key} nao pode ser negativo.');
      }
      if (entry.key == AtValidationField.maritalQuotient &&
          value != 1 &&
          value != 2) {
        throw _fixtureError('maritalQuotient deve ser 1 ou 2.');
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
      sourceNotes: sourceNotes,
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
    final firstMismatch = mismatch
        ? fields.firstWhere((field) => !field.isExact)
        : null;
    return AtFixtureComparison(
      fixture: fixture,
      actualResults: actual,
      fields: fields,
      failure: mismatch
          ? FixtureFailure(
              category: FixtureFailureCategory.unknown,
              message: 'Diferenca por classificar; requer analise humana.',
              field: firstMismatch!.field,
              expected: firstMismatch.officialCents,
              actual: firstMismatch.taxyCents,
              difference: firstMismatch.differenceCents,
              probableStage:
                  AtValidationField.probableStages[firstMismatch.field],
            )
          : null,
    );
  }

  Map<String, int> calculateComparable(
    TaxSimulation simulation,
    TaxRuleSet rules,
  ) => comparableFromTrace(calculateTrace(simulation, rules));

  TaxCalculationTrace calculateTrace(
    TaxSimulation simulation,
    TaxRuleSet rules,
  ) => _calculateSelected(simulation, rules).trace;

  /// Converts only typed fields. UI breakdown labels are intentionally absent.
  Map<String, int> comparableFromTrace(
    TaxCalculationTrace trace,
  ) => Map.unmodifiable(<String, int>{
    AtValidationField.grossIncome: trace.grossIncome.cents,
    AtValidationField.specificDeduction: trace.specificDeduction.cents,
    AtValidationField.netIncome: trace.netIncome.cents,
    AtValidationField.minimumExistence: trace.minimumExistenceAllowance.cents,
    AtValidationField.taxableIncome: trace.taxableIncome.cents,
    AtValidationField.maritalQuotient: trace.maritalQuotient,
    AtValidationField.rateDeterminingIncome: trace.rateDeterminingIncome.cents,
    AtValidationField.rateDeterminingQuotient:
        trace.rateDeterminingQuotient.cents,
    AtValidationField.bracketBaseTax: trace.bracketBaseTax.cents,
    AtValidationField.bracketExcess: trace.bracketExcess.cents,
    AtValidationField.marginalRate: trace.marginalRatePpm,
    AtValidationField.taxBeforeExemption: trace.taxBeforeExemption.cents,
    AtValidationField.exemptIncome: trace.exemptIncome.cents,
    AtValidationField.taxAllocatedToExemptIncome:
        trace.taxAllocatedToExemptIncome.cents,
    AtValidationField.grossTaxAfterExemption:
        trace.grossTaxAfterExemption.cents,
    AtValidationField.dependentCredits: trace.dependentCredits.cents,
    AtValidationField.generalExpenseCredit: trace.generalExpenseCredit.cents,
    AtValidationField.healthCredit: trace.healthCredit.cents,
    AtValidationField.educationCredit: trace.educationCredit.cents,
    AtValidationField.careHomeCredit: trace.careHomeCredit.cents,
    AtValidationField.rentCredit: trace.rentCredit.cents,
    AtValidationField.invoiceVatCredit: trace.invoiceVatCredit.cents,
    AtValidationField.pprCredit: trace.pprCredit.cents,
    AtValidationField.overallDeductionsCap:
        trace.overallDeductionsCap?.cents ?? 0,
    AtValidationField.totalTaxCredits: trace.totalTaxCredits.cents,
    AtValidationField.solidarityTax: trace.solidarityTax.cents,
    AtValidationField.finalTaxDue: trace.finalTaxDue.cents,
    AtValidationField.withholding: trace.withholding.cents,
    AtValidationField.balance: trace.balance.cents,
  });

  TaxResult _calculateSelected(TaxSimulation simulation, TaxRuleSet rules) {
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
      return result;
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
    return useJovem ? comparison.withIrsJovem! : comparison.normal;
  }
}

bool usesIrsJovem(TaxSimulation simulation) =>
    simulation.primaryIrsJovem.requested ||
    (simulation.secondaryTaxpayer?.irsJovem.requested ?? false);

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
  int get totalFieldComparisons => comparisons.fold(
    0,
    (total, comparison) => total + comparison.fields.length,
  );
  int get exactFieldComparisons => comparisons.fold(
    0,
    (total, comparison) =>
        total + comparison.fields.where((field) => field.isExact).length,
  );
  int get mismatchedFields => totalFieldComparisons - exactFieldComparisons;

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

  Map<String, int> get casesByYear => _groupBy(
    comparisons,
    (comparison) => comparison.fixture.taxYear.toString(),
  );
  Map<String, int> get casesByRegion => _groupBy(
    comparisons,
    (comparison) => comparison.fixture.jurisdiction.name,
  );
  Map<String, int> get casesByFilingMode =>
      _groupBy(comparisons, (comparison) => comparison.fixture.filingMode.name);
  Map<String, int> get casesByIrsJovem => _groupBy(
    comparisons,
    (comparison) => comparison.fixture.usesIrsJovem ? 'sim' : 'nao',
  );

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
      ..writeln(
        '- Comparacoes de campos executadas: '
        '${coverage.totalFieldComparisons}',
      )
      ..writeln(
        '- Comparacoes de campos exatas: ${coverage.exactFieldComparisons}',
      )
      ..writeln('- Campos divergentes: ${coverage.mismatchedFields}')
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
    _writeGroup(buffer, 'Por ano', coverage.casesByYear);
    _writeGroup(buffer, 'Por regiao', coverage.casesByRegion);
    _writeGroup(buffer, 'Por modo de tributacao', coverage.casesByFilingMode);
    _writeGroup(buffer, 'Por IRS Jovem', coverage.casesByIrsJovem);
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

Map<String, int> _groupBy(
  Iterable<AtFixtureComparison> comparisons,
  String Function(AtFixtureComparison) keyOf,
) {
  final grouped = <String, int>{};
  for (final comparison in comparisons) {
    grouped.update(keyOf(comparison), (value) => value + 1, ifAbsent: () => 1);
  }
  return Map.unmodifiable(grouped);
}

void _writeGroup(StringBuffer buffer, String title, Map<String, int> values) {
  buffer
    ..writeln()
    ..writeln('### $title')
    ..writeln();
  if (values.isEmpty) {
    buffer.writeln('- 0 casos');
    return;
  }
  for (final entry in values.entries) {
    buffer.writeln('- ${entry.key}: ${entry.value} caso(s)');
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

Map<String, Object?> decodeFixtureJson(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map) {
    _fixtureError('A raiz da fixture deve ser um objeto JSON.');
  }
  return decoded.map((key, value) => MapEntry(key.toString(), value));
}
