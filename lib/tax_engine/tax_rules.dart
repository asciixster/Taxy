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
    required this.taxYear,
    required this.rulesVersion,
    required this.verifiedAt,
    required this.iasCents,
    required this.employmentSpecificDeductionCents,
    required this.minimumExistenceReferenceCents,
    required this.minimumExistence,
    required this.brackets,
    required this.solidarity,
    required this.deductions,
    required this.ruleMetadata,
  });

  final int taxYear;
  final String rulesVersion;
  final DateTime verifiedAt;
  final int iasCents;
  final int employmentSpecificDeductionCents;
  final int minimumExistenceReferenceCents;
  final Map<String, int> minimumExistence;
  final List<TaxBracket> brackets;
  final Map<String, int> solidarity;
  final Map<String, int> deductions;
  final Map<String, TaxRuleMetadata> ruleMetadata;

  int d(String key) =>
      deductions[key] ?? (throw StateError('Regra $key em falta'));
  int me(String key) =>
      minimumExistence[key] ?? (throw StateError('Regra $key em falta'));
  int s(String key) =>
      solidarity[key] ?? (throw StateError('Regra $key em falta'));

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
    };
    if (!metadata.keys.toSet().containsAll(requiredMetadata)) {
      throw const FormatException('Metadados obrigatórios das regras em falta');
    }
    return TaxRuleSet(
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
      deductions: (json['deductions'] as Map).cast<String, int>(),
      ruleMetadata: metadata,
    );
  }
}
