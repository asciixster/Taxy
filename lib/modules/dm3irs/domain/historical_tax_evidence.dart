import '../../../guided_tax/tax_interview_models.dart';

enum HistoricalTaxSource { dm3irsOfficialDeclaration }

enum HistoricalEvidenceConfidence { exact }

enum HistoricalTaxAnnex { a, c, h, ss }

enum HistoricalIncomeCategory { a, b }

enum HistoricalCategoryBRegime { organizedAccounting }

enum HistoricalSuggestionField {
  categoryA,
  categoryB,
  categoryBRegime,
  activityCode,
  taxableProfit,
  withholding,
}

/// Sanitized, session-only output of the DM3IRS parser.
///
/// This deliberately is not a [TaxFact]. Only an explicit confirmation can be
/// converted into a current-year interview answer.
final class HistoricalTaxEvidence {
  const HistoricalTaxEvidence({
    required this.taxYear,
    required this.source,
    required this.annexes,
    required this.incomeCategories,
    required this.confidence,
    required this.templateVersion,
    required this.templateFingerprint,
    this.categoryBRegime,
    this.activityCode,
    this.taxableProfitCents,
    this.withholdingCents,
  });

  final int taxYear;
  final HistoricalTaxSource source;
  final Set<HistoricalTaxAnnex> annexes;
  final Set<HistoricalIncomeCategory> incomeCategories;
  final HistoricalCategoryBRegime? categoryBRegime;
  final String? activityCode;
  final int? taxableProfitCents;
  final int? withholdingCents;
  final HistoricalEvidenceConfidence confidence;
  final String templateVersion;
  final String templateFingerprint;

  factory HistoricalTaxEvidence.fromNative(Map<Object?, Object?> value) {
    final year = value['taxYear'];
    final template = value['templateVersion'];
    final fingerprint = value['templateFingerprint'];
    final annexNames = value['annexes'];
    final categoryNames = value['incomeCategories'];
    if (year is! int ||
        year != 2024 ||
        template != 'MODELO3_2024_V1' ||
        fingerprint is! String ||
        fingerprint.isEmpty ||
        annexNames is! List ||
        categoryNames is! List ||
        value['confidence'] != 'EXACT') {
      throw const FormatException('unsupported historical tax evidence');
    }
    final annexes = annexNames
        .whereType<String>()
        .map(
          (name) => switch (name) {
            'A' => HistoricalTaxAnnex.a,
            'C' => HistoricalTaxAnnex.c,
            'H' => HistoricalTaxAnnex.h,
            'SS' => HistoricalTaxAnnex.ss,
            _ => throw const FormatException('unsupported annex'),
          },
        )
        .toSet();
    final categories = categoryNames
        .whereType<String>()
        .map(
          (name) => switch (name) {
            'A' => HistoricalIncomeCategory.a,
            'B' => HistoricalIncomeCategory.b,
            _ => throw const FormatException('unsupported category'),
          },
        )
        .toSet();
    final activityCode = value['activityCode'];
    final taxableProfit = value['taxableProfitCents'];
    final withholding = value['withholdingCents'];
    if (activityCode != null &&
        (activityCode is! String ||
            !RegExp(r'^\d{4}$').hasMatch(activityCode))) {
      throw const FormatException('invalid activity code');
    }
    if (taxableProfit != null && (taxableProfit is! int || taxableProfit < 0)) {
      throw const FormatException('invalid taxable profit');
    }
    if (withholding != null && (withholding is! int || withholding < 0)) {
      throw const FormatException('invalid withholding');
    }
    return HistoricalTaxEvidence(
      taxYear: year,
      source: HistoricalTaxSource.dm3irsOfficialDeclaration,
      annexes: Set.unmodifiable(annexes),
      incomeCategories: Set.unmodifiable(categories),
      categoryBRegime: value['categoryBRegime'] == 'CONTABILIDADE_ORGANIZADA'
          ? HistoricalCategoryBRegime.organizedAccounting
          : null,
      activityCode: activityCode as String?,
      taxableProfitCents: taxableProfit as int?,
      withholdingCents: withholding as int?,
      confidence: HistoricalEvidenceConfidence.exact,
      templateVersion: template as String,
      templateFingerprint: fingerprint,
    );
  }

  List<HistoricalTaxSuggestion> get suggestions => [
    if (incomeCategories.contains(HistoricalIncomeCategory.a))
      const HistoricalTaxSuggestion(
        field: HistoricalSuggestionField.categoryA,
        value: true,
      ),
    if (incomeCategories.contains(HistoricalIncomeCategory.b))
      const HistoricalTaxSuggestion(
        field: HistoricalSuggestionField.categoryB,
        value: true,
      ),
    if (categoryBRegime != null)
      HistoricalTaxSuggestion(
        field: HistoricalSuggestionField.categoryBRegime,
        value: categoryBRegime!.name,
      ),
    if (activityCode != null)
      HistoricalTaxSuggestion(
        field: HistoricalSuggestionField.activityCode,
        value: activityCode!,
      ),
    if (taxableProfitCents != null)
      HistoricalTaxSuggestion(
        field: HistoricalSuggestionField.taxableProfit,
        value: taxableProfitCents!,
      ),
    if (withholdingCents != null)
      HistoricalTaxSuggestion(
        field: HistoricalSuggestionField.withholding,
        value: withholdingCents!,
      ),
  ];
}

final class HistoricalTaxSuggestion {
  const HistoricalTaxSuggestion({required this.field, required this.value});
  final HistoricalSuggestionField field;
  final Object value;
}

final class HistoricalTaxConfirmation {
  const HistoricalTaxConfirmation({
    required this.field,
    required this.value,
    required this.sourceYear,
    required this.targetYear,
    required this.userConfirmedAt,
    required this.templateFingerprint,
    this.provenance = TaxFactProvenance.official,
    this.confidence = HistoricalEvidenceConfidence.exact,
  });

  final HistoricalSuggestionField field;
  final Object value;
  final int sourceYear;
  final int targetYear;
  final DateTime userConfirmedAt;
  final String templateFingerprint;
  final TaxFactProvenance provenance;
  final HistoricalEvidenceConfidence confidence;

  String? get targetQuestionId => switch (field) {
    HistoricalSuggestionField.categoryA => 'employmentIncome',
    HistoricalSuggestionField.categoryB => 'selfEmploymentIncome',
    HistoricalSuggestionField.withholding => 'withholdingCents',
    HistoricalSuggestionField.categoryBRegime ||
    HistoricalSuggestionField.activityCode ||
    HistoricalSuggestionField.taxableProfit => null,
  };

  Map<String, Object?> toJson() => {
    'field': field.name,
    'value': value,
    'sourceYear': sourceYear,
    'targetYear': targetYear,
    'userConfirmedAt': userConfirmedAt.toUtc().toIso8601String(),
    'templateFingerprint': templateFingerprint,
    'provenance': provenance.name,
    'confidence': confidence.name,
  };

  factory HistoricalTaxConfirmation.fromJson(Map<String, Object?> json) {
    final sourceYear = json['sourceYear'];
    final targetYear = json['targetYear'];
    final confirmedAt = DateTime.tryParse(
      json['userConfirmedAt'] as String? ?? '',
    );
    final fingerprint = json['templateFingerprint'];
    if (sourceYear != 2024 ||
        targetYear is! int ||
        targetYear == sourceYear ||
        confirmedAt == null ||
        fingerprint is! String ||
        fingerprint.isEmpty ||
        json['provenance'] != TaxFactProvenance.official.name ||
        json['confidence'] != HistoricalEvidenceConfidence.exact.name) {
      throw const FormatException('invalid historical confirmation');
    }
    return HistoricalTaxConfirmation(
      field: HistoricalSuggestionField.values.byName(json['field'] as String),
      value: json['value'] as Object,
      sourceYear: sourceYear as int,
      targetYear: targetYear,
      userConfirmedAt: confirmedAt.toUtc(),
      templateFingerprint: fingerprint,
    );
  }
}

Map<String, TaxAnswer> applyHistoricalConfirmations({
  required Map<String, TaxAnswer> current,
  required int targetYear,
  required List<HistoricalTaxConfirmation> confirmations,
}) {
  final updated = {...current};
  for (final confirmation in confirmations) {
    if (confirmation.targetYear != targetYear ||
        confirmation.sourceYear == targetYear ||
        confirmation.confidence != HistoricalEvidenceConfidence.exact) {
      continue;
    }
    final questionId = confirmation.targetQuestionId;
    if (questionId == null) continue;
    updated[questionId] = TaxAnswer(
      questionId: questionId,
      value: confirmation.value,
      provenance: TaxFactProvenance.official,
    );
  }
  return updated;
}
