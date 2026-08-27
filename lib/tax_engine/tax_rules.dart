import 'dart:convert';

final class TaxBracket {
  const TaxBracket({
    required this.upperCents,
    required this.marginalRatePpm,
    required this.averageRatePpm,
  });
  final int? upperCents;
  final int marginalRatePpm;
  final int? averageRatePpm;

  factory TaxBracket.fromJson(Map<String, Object?> json) => TaxBracket(
    upperCents: json['upperCents'] as int?,
    marginalRatePpm: json['marginalRatePpm'] as int,
    averageRatePpm: json['averageRatePpm'] as int?,
  );
}

final class TaxRuleMetadata {
  const TaxRuleMetadata({
    required this.name,
    required this.unit,
    required this.source,
    required this.comment,
    required this.version,
  });

  final String name;
  final String unit;
  final String source;
  final String comment;
  final String version;

  factory TaxRuleMetadata.fromJson(Map<String, Object?> json) =>
      TaxRuleMetadata(
        name: json['name'] as String,
        unit: json['unit'] as String,
        source: json['source'] as String,
        comment: json['comment'] as String,
        version: json['version'] as String,
      );
}

final class TaxRuleSet {
  const TaxRuleSet({
    required this.jurisdiction,
    required this.taxYear,
    required this.rulesVersion,
    required this.verifiedAt,
    required this.iasCents,
    required this.employmentSpecificDeductionCents,
    required this.minimumExistenceReferenceCents,
    required this.minimumExistence,
    required this.brackets,
    required this.solidarity,
    required this.household,
    required this.irsJovem,
    required this.deductions,
    required this.ruleMetadata,
  });

  final String jurisdiction;
  final int taxYear;
  final String rulesVersion;
  final DateTime verifiedAt;
  final int iasCents;
  final int employmentSpecificDeductionCents;
  final int minimumExistenceReferenceCents;
  final Map<String, int> minimumExistence;
  final List<TaxBracket> brackets;
  final Map<String, int> solidarity;
  final Map<String, int> household;
  final Map<String, int> irsJovem;
  final Map<String, int> deductions;
  final Map<String, TaxRuleMetadata> ruleMetadata;

  int d(String key) =>
      deductions[key] ?? (throw StateError('Regra $key em falta'));
  int me(String key) =>
      minimumExistence[key] ?? (throw StateError('Regra $key em falta'));
  int s(String key) =>
      solidarity[key] ?? (throw StateError('Regra $key em falta'));
  int h(String key) =>
      household[key] ?? (throw StateError('Regra conjugal $key em falta'));
  int jovem(String key) =>
      irsJovem[key] ?? (throw StateError('Regra IRS Jovem $key em falta'));

  TaxRuleSet copyWith({
    String? jurisdiction,
    int? taxYear,
    String? rulesVersion,
    DateTime? verifiedAt,
    int? iasCents,
    int? employmentSpecificDeductionCents,
    int? minimumExistenceReferenceCents,
    Map<String, int>? minimumExistence,
    List<TaxBracket>? brackets,
    Map<String, int>? solidarity,
    Map<String, int>? household,
    Map<String, int>? irsJovem,
    Map<String, int>? deductions,
    Map<String, TaxRuleMetadata>? ruleMetadata,
  }) => TaxRuleSet(
    jurisdiction: jurisdiction ?? this.jurisdiction,
    taxYear: taxYear ?? this.taxYear,
    rulesVersion: rulesVersion ?? this.rulesVersion,
    verifiedAt: verifiedAt ?? this.verifiedAt,
    iasCents: iasCents ?? this.iasCents,
    employmentSpecificDeductionCents:
        employmentSpecificDeductionCents ??
        this.employmentSpecificDeductionCents,
    minimumExistenceReferenceCents:
        minimumExistenceReferenceCents ?? this.minimumExistenceReferenceCents,
    minimumExistence: minimumExistence ?? this.minimumExistence,
    brackets: brackets ?? this.brackets,
    solidarity: solidarity ?? this.solidarity,
    household: household ?? this.household,
    irsJovem: irsJovem ?? this.irsJovem,
    deductions: deductions ?? this.deductions,
    ruleMetadata: ruleMetadata ?? this.ruleMetadata,
  );

  factory TaxRuleSet.fromJsonString(String source) {
    final json = (jsonDecode(source) as Map).cast<String, Object?>();
    if (json['schemaVersion'] != 2 ||
        json['status'] != 'VERIFIED_FOR_MVP_SCOPE') {
      throw const FormatException(
        'Ficheiro de regras não verificado ou incompatível',
      );
    }
    final brackets = (json['brackets'] as List)
        .map((e) => TaxBracket.fromJson((e as Map).cast<String, Object?>()))
        .toList(growable: false);
    if (brackets.length != 9 || brackets.last.upperCents != null) {
      throw const FormatException('Escalões IRS inválidos');
    }
    final metadata = (json['ruleMetadata'] as Map).map(
      (key, value) => MapEntry(
        key as String,
        TaxRuleMetadata.fromJson((value as Map).cast<String, Object?>()),
      ),
    );
    const requiredMetadata = {
      'generalSingleParentRatePpm',
      'generalSingleParentCapCents',
      'invoiceVat15RatePpm',
      'invoiceVat30RatePpm',
      'invoiceVat35RatePpm',
      'invoiceVat100RatePpm',
      'invoiceVatCapCents',
      'jointDivisor',
      'separateDependentExpenseSharePpm',
      'familyLimitDivisor',
      'irsJovemRates',
    };
    if (!metadata.keys.toSet().containsAll(requiredMetadata)) {
      throw const FormatException('Metadados obrigatórios das regras em falta');
    }
    return TaxRuleSet(
      jurisdiction:
          ((json['supportedScope'] as Map?)?['jurisdiction'] as String?) ??
          (json['jurisdiction'] as String? ?? 'CONTINENT'),
      taxYear: json['taxYear'] as int,
      rulesVersion: json['rulesVersion'] as String,
      verifiedAt: DateTime.parse(json['verifiedAt'] as String),
      iasCents: json['iasCents'] as int,
      employmentSpecificDeductionCents:
          json['employmentSpecificDeductionCents'] as int,
      minimumExistenceReferenceCents:
          json['minimumExistenceReferenceCents'] as int,
      minimumExistence: (json['minimumExistence'] as Map).cast<String, int>(),
      brackets: brackets,
      solidarity: (json['solidarity'] as Map).cast<String, int>(),
      household: (json['household'] as Map).cast<String, int>(),
      irsJovem: (json['irsJovem'] as Map).cast<String, int>(),
      deductions: (json['deductions'] as Map).cast<String, int>(),
      ruleMetadata: metadata,
    );
  }
}

typedef TaxAssetLoader = Future<String> Function(String assetPath);

/// Resolve regras exclusivamente por ano + jurisdição. Os descritores v3
/// versionados aplicam apenas overrides declarativos sobre uma base validada.
final class TaxRuleRepository {
  const TaxRuleRepository(this.loadAsset);

  final TaxAssetLoader loadAsset;

  static String descriptorPath(int year, String jurisdiction) =>
      'assets/tax_rules/$year/${jurisdiction.toLowerCase()}.json';

  Future<TaxRuleSet> load(int year, String jurisdiction) async {
    final path = descriptorPath(year, jurisdiction);
    final descriptor = (jsonDecode(await loadAsset(path)) as Map)
        .cast<String, Object?>();
    if (descriptor['schemaVersion'] != 3 ||
        descriptor['status'] != 'VERIFIED') {
      throw FormatException('Descritor fiscal não verificado: $path');
    }
    final basePath = descriptor['baseAsset'] as String;
    final base = TaxRuleSet.fromJsonString(await loadAsset(basePath));
    final overrides = (descriptor['overrides'] as Map? ?? const {})
        .cast<String, Object?>();
    final bracketValues = descriptor['brackets'] as List?;
    final deductionOverrides = (overrides['deductions'] as Map? ?? const {})
        .cast<String, int>();
    final minimumOverrides = (overrides['minimumExistence'] as Map? ?? const {})
        .cast<String, int>();
    return base.copyWith(
      jurisdiction: descriptor['jurisdiction'] as String,
      taxYear: descriptor['taxYear'] as int,
      rulesVersion: descriptor['rulesVersion'] as String,
      verifiedAt: DateTime.parse(descriptor['verifiedAt'] as String),
      iasCents: overrides['iasCents'] as int? ?? base.iasCents,
      employmentSpecificDeductionCents:
          overrides['employmentSpecificDeductionCents'] as int? ??
          base.employmentSpecificDeductionCents,
      minimumExistenceReferenceCents:
          overrides['minimumExistenceReferenceCents'] as int? ??
          base.minimumExistenceReferenceCents,
      minimumExistence: {...base.minimumExistence, ...minimumOverrides},
      brackets: bracketValues == null
          ? base.brackets
          : bracketValues
                .map(
                  (value) => TaxBracket.fromJson(
                    (value as Map).cast<String, Object?>(),
                  ),
                )
                .toList(growable: false),
      deductions: {...base.deductions, ...deductionOverrides},
    );
  }
}
