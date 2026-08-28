import '../domain/models.dart';
import '../domain/money.dart';
import '../tax_engine/tax_rules.dart';
import 'at_validation.dart';

abstract final class ManualReferenceField {
  static const potentialTaxCredits = 'potentialTaxCreditsCents';
  static const effectiveTaxCredits = 'effectiveTaxCreditsCents';

  static const supported = <String>{
    ...AtValidationField.all,
    potentialTaxCredits,
    effectiveTaxCredits,
  };
}

enum InputEvidence {
  documented('DOCUMENTED'),
  manuallyDerived('MANUALLY_DERIVED'),
  assumedNonMaterial('ASSUMED_NON_MATERIAL'),
  noDirectSource('NO_DIRECT_SOURCE');

  const InputEvidence(this.code);
  final String code;
}

enum ManualReferenceStatus { pass, fail }

final class ManualReferenceDocument {
  const ManualReferenceDocument({
    required this.taxYear,
    required this.jurisdiction,
    required this.rulesVersion,
    required this.cases,
  });

  static const currentSchemaVersion = 1;
  final int taxYear;
  final TaxRegion jurisdiction;
  final String rulesVersion;
  final List<ManualReferenceCase> cases;

  factory ManualReferenceDocument.fromJson(Map<String, Object?> json) {
    if (json['manualReferenceSchemaVersion'] != currentSchemaVersion) {
      throw const FormatException('manualReferenceSchemaVersion inválido.');
    }
    if (json['source'] != 'MANUALLY_AUDITED_REFERENCE') {
      throw const FormatException(
        'Uma referência manual nunca pode declarar origem oficial.',
      );
    }
    final sources = (json['sources'] as List? ?? const []).cast<String>();
    if (sources.isEmpty) {
      throw const FormatException('A referência manual exige fontes.');
    }
    final cases = (json['cases'] as List? ?? const [])
        .map(
          (value) => ManualReferenceCase.fromJson(
            (value as Map).cast<String, Object?>(),
          ),
        )
        .toList(growable: false);
    if (cases.isEmpty) {
      throw const FormatException('A referência manual exige casos.');
    }
    return ManualReferenceDocument(
      taxYear: json['taxYear'] as int,
      jurisdiction: _region(json['jurisdiction'] as String),
      rulesVersion: json['rulesVersion'] as String,
      cases: cases,
    );
  }
}

final class ManualReferenceCase {
  const ManualReferenceCase({
    required this.id,
    required this.scenario,
    required this.description,
    required this.civilStatus,
    required this.filingMode,
    required this.input,
    required this.expected,
    required this.audit,
    required this.inputEvidence,
  });

  final String id;
  final String scenario;
  final String description;
  final CivilStatus civilStatus;
  final FilingMode filingMode;
  final Map<String, Object?> input;
  final Map<String, int> expected;
  final Map<String, Object?> audit;
  final Map<String, InputEvidence> inputEvidence;

  factory ManualReferenceCase.fromJson(Map<String, Object?> json) {
    final expectedRaw = (json['expected'] as Map).cast<String, Object?>();
    if (expectedRaw.isEmpty ||
        expectedRaw.keys.any(
          (key) => !ManualReferenceField.supported.contains(key),
        ) ||
        expectedRaw.values.any((value) => value is! int)) {
      throw FormatException('Expected inválido em ${json['id']}.');
    }
    final audit = (json['audit'] as Map? ?? const <String, Object?>{})
        .cast<String, Object?>();
    if (audit.length < 5) {
      throw FormatException('Audit trail insuficiente em ${json['id']}.');
    }
    final evidenceRaw =
        (json['inputEvidence'] as Map? ?? const <String, Object?>{})
            .cast<String, Object?>();
    const requiredEvidence = {
      'taxpayerA.age',
      'taxpayerA.grossIncomeCents',
      'taxpayerA.withholdingCents',
      'taxpayerA.mandatoryContributionsCents',
    };
    final input = (json['input'] as Map).cast<String, Object?>();
    final required = <String>{...requiredEvidence};
    if (input['taxpayerB'] != null) {
      required.addAll(const {
        'taxpayerB.age',
        'taxpayerB.grossIncomeCents',
        'taxpayerB.withholdingCents',
        'taxpayerB.mandatoryContributionsCents',
      });
    }
    if ((input['dependents'] as List? ?? const []).isNotEmpty) {
      required.add('dependents');
    }
    if (!evidenceRaw.keys.toSet().containsAll(required)) {
      throw FormatException(
        'Provenance de inputs incompleta em ${json['id']}.',
      );
    }
    final evidence = <String, InputEvidence>{};
    for (final entry in evidenceRaw.entries) {
      evidence[entry.key] = InputEvidence.values.firstWhere(
        (value) => value.code == entry.value,
        orElse: () => throw FormatException(
          'Input evidence inválida em ${json['id']}: ${entry.value}',
        ),
      );
    }
    return ManualReferenceCase(
      id: json['id'] as String,
      scenario: json['scenario'] as String,
      description: json['description'] as String,
      civilStatus: _civilStatus(json['civilStatus'] as String),
      filingMode: _filingMode(json['filingMode'] as String),
      input: input,
      expected: expectedRaw.map((key, value) => MapEntry(key, value! as int)),
      audit: audit,
      inputEvidence: Map.unmodifiable(evidence),
    );
  }
}

final class ManualFieldComparison {
  const ManualFieldComparison(this.field, this.expected, this.actual);
  final String field;
  final int expected;
  final int actual;
  int get difference => actual - expected;
  bool get matches => difference == 0;
}

final class ManualReferenceComparison {
  const ManualReferenceComparison(this.fixture, this.fields);
  final ManualReferenceCase fixture;
  final List<ManualFieldComparison> fields;
  ManualReferenceStatus get status => fields.every((field) => field.matches)
      ? ManualReferenceStatus.pass
      : ManualReferenceStatus.fail;
  List<ManualFieldComparison> get mismatches =>
      fields.where((field) => !field.matches).toList(growable: false);
}

final class ManualReferenceRunner {
  const ManualReferenceRunner();

  ManualReferenceComparison compare(
    ManualReferenceDocument document,
    ManualReferenceCase fixture,
    TaxRuleSet rules,
  ) {
    if (rules.taxYear != document.taxYear ||
        rules.jurisdiction != document.jurisdiction.name.toUpperCase() ||
        rules.rulesVersion != document.rulesVersion) {
      throw const FormatException('Ruleset não corresponde à referência.');
    }
    final trace = const AtValidationEngine().calculateTrace(
      _simulation(document, fixture),
      rules,
    );
    final actual = <String, int>{
      ...const AtValidationEngine().comparableFromTrace(trace),
      ManualReferenceField.potentialTaxCredits: trace.potentialTaxCredits.cents,
      ManualReferenceField.effectiveTaxCredits: trace.effectiveTaxCredits.cents,
    };
    return ManualReferenceComparison(
      fixture,
      fixture.expected.entries
          .map(
            (entry) => ManualFieldComparison(
              entry.key,
              entry.value,
              actual[entry.key]!,
            ),
          )
          .toList(growable: false),
    );
  }
}

TaxSimulation _simulation(
  ManualReferenceDocument document,
  ManualReferenceCase fixture,
) {
  final input = fixture.input;
  final taxpayerA = (input['taxpayerA'] as Map).cast<String, Object?>();
  final taxpayerB = input['taxpayerB'] == null
      ? null
      : (input['taxpayerB'] as Map).cast<String, Object?>();
  final dependentMaps = (input['dependents'] as List? ?? const [])
      .map((value) => (value as Map).cast<String, Object?>())
      .toList(growable: false);
  final dependents = dependentMaps
      .map(
        (value) => Dependent(
          id: value['id'] as String,
          ageAtYearEnd: value['ageAtYearEnd'] as int,
        ),
      )
      .toList(growable: false);
  final timestamp = DateTime.utc(2026, 8, 28);
  return TaxSimulation(
    id: fixture.id,
    name: fixture.description,
    createdAt: timestamp,
    updatedAt: timestamp,
    profile: TaxpayerProfile(
      taxYear: document.taxYear,
      age: taxpayerA['age'] as int,
      civilStatus: fixture.civilStatus,
      dependentAges: dependents.map((value) => value.ageAtYearEnd).toList(),
      fullYearResident: true,
      region: document.jurisdiction,
      filingMode: fixture.filingMode,
    ),
    income: _income(taxpayerA),
    deductions: _deductions(taxpayerA['deductions']),
    primaryIrsJovem: _irsJovem(taxpayerA['irsJovem']),
    secondaryTaxpayer: taxpayerB == null
        ? null
        : TaxpayerInput(
            id: 'B',
            age: taxpayerB['age'] as int,
            income: _income(taxpayerB),
            deductions: _deductions(taxpayerB['deductions']),
            irsJovem: _irsJovem(taxpayerB['irsJovem']),
          ),
    dependents: dependents,
    dependentDeductions: _deductions(input['dependentDeductions']),
  );
}

EmploymentIncome _income(Map<String, Object?> json) => EmploymentIncome(
  entryMode: IncomeEntryMode.annual,
  gross: Money.fromCents(json['grossIncomeCents'] as int),
  withholding: Money.fromCents(json['withholdingCents'] as int),
  socialSecurity: Money.fromCents(json['mandatoryContributionsCents'] as int),
);

DeductionInput _deductions(Object? value) {
  final json = value == null
      ? const <String, Object?>{}
      : (value as Map).cast<String, Object?>();
  Money money(String key) => Money.fromCents(json[key] as int? ?? 0);
  return DeductionInput(
    general: money('generalCents'),
    health: money('healthCents'),
    education: money('educationCents'),
    rent: money('rentCents'),
    careHomes: money('careHomeCents'),
    invoiceVat15: money('invoiceVat15Cents'),
    invoiceVat30: money('invoiceVat30Cents'),
    invoiceVat35: money('invoiceVat35Cents'),
    invoiceVat100: money('invoiceVat100Cents'),
    ppr: money('pprCents'),
  );
}

IrsJovemAnswers _irsJovem(Object? value) => value == null
    ? const IrsJovemAnswers()
    : IrsJovemAnswers.fromJson((value as Map).cast<String, Object?>());

TaxRegion _region(String value) => switch (value.toUpperCase()) {
  'CONTINENT' => TaxRegion.continent,
  'MADEIRA' => TaxRegion.madeira,
  'AZORES' => TaxRegion.azores,
  _ => throw FormatException('Região desconhecida: $value'),
};

CivilStatus _civilStatus(String value) => switch (value.toUpperCase()) {
  'SINGLE' => CivilStatus.single,
  'MARRIED' => CivilStatus.married,
  'DE_FACTO' => CivilStatus.deFacto,
  _ => throw FormatException('Estado civil desconhecido: $value'),
};

FilingMode _filingMode(String value) => switch (value.toUpperCase()) {
  'SEPARATE' => FilingMode.separate,
  'JOINT' => FilingMode.joint,
  _ => throw FormatException('Modo de tributação desconhecido: $value'),
};
