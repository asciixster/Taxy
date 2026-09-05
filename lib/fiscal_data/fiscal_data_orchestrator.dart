import '../guided_tax/tax_interview_models.dart';
import '../modules/efatura/domain/efatura_models.dart';
import '../product/product_models.dart';

enum FiscalDataSource {
  userEntered,
  interview,
  official,
  imported,
  calculated,
  inferred,
}

enum FiscalDataConfidence { confirmed, likely, incomplete, unknown }

enum FiscalDataFreshness { current, stale, notApplicable }

enum EstimateCompleteness { ready, provisional, incomplete, unavailable }

enum TaxMissingDataSeverity {
  requiredForCalculation,
  improvesEstimate,
  optional,
}

enum InterviewSectionState { clean, needsReview, incomplete }

enum FiscalCompanionAction {
  completeProfile,
  continueInterview,
  reviewEfatura,
  reviewEstimate,
  noAction,
}

final class FiscalDataPoint {
  const FiscalDataPoint({
    required this.id,
    required this.value,
    required this.source,
    required this.confidence,
    required this.taxYear,
    this.lastUpdatedAt,
    this.isUserOverride = false,
  });

  final String id;
  final Object? value;
  final FiscalDataSource source;
  final FiscalDataConfidence confidence;
  final int taxYear;
  final DateTime? lastUpdatedAt;
  final bool isUserOverride;

  FiscalDataFreshness freshness(DateTime now) {
    if (source == FiscalDataSource.userEntered ||
        source == FiscalDataSource.interview ||
        source == FiscalDataSource.calculated) {
      return FiscalDataFreshness.notApplicable;
    }
    final updated = lastUpdatedAt;
    if (updated == null) return FiscalDataFreshness.stale;
    return now.difference(updated) <= const Duration(days: 31)
        ? FiscalDataFreshness.current
        : FiscalDataFreshness.stale;
  }
}

final class FiscalDataConflict {
  const FiscalDataConflict({
    required this.id,
    required this.current,
    required this.candidate,
  });
  final String id;
  final FiscalDataPoint current;
  final FiscalDataPoint candidate;
}

final class TaxMissingDataItem {
  const TaxMissingDataItem({
    required this.id,
    required this.area,
    required this.severity,
    required this.reason,
    required this.action,
  });
  final String id;
  final TaxInterviewSectionId area;
  final TaxMissingDataSeverity severity;
  final String reason;
  final FiscalCompanionAction action;
}

final class EfaturaCompanionEvidence {
  const EfaturaCompanionEvidence({
    required this.taxYear,
    required this.pendingCount,
    this.invoiceCount,
    required this.available,
    required this.lastUpdatedAt,
    this.needsReview = false,
  });

  factory EfaturaCompanionEvidence.fromOverview({
    required int taxYear,
    required EfaturaOverview overview,
    int? invoiceCount,
    required DateTime updatedAt,
    bool needsReview = false,
  }) => EfaturaCompanionEvidence(
    taxYear: taxYear,
    pendingCount: overview.pendingValidation.valueOrNull,
    invoiceCount: invoiceCount,
    available: true,
    lastUpdatedAt: updatedAt,
    needsReview: needsReview,
  );

  final int taxYear;
  final int? pendingCount;
  final int? invoiceCount;
  final bool available;
  final DateTime lastUpdatedAt;
  final bool needsReview;
}

final class FiscalDataOrchestrationResult {
  const FiscalDataOrchestrationResult({
    required this.facts,
    required this.conflicts,
    required this.missing,
    required this.sections,
    required this.estimateCompleteness,
    required this.nextAction,
  });

  final Map<String, FiscalDataPoint> facts;
  final List<FiscalDataConflict> conflicts;
  final List<TaxMissingDataItem> missing;
  final Map<TaxInterviewSectionId, InterviewSectionState> sections;
  final EstimateCompleteness estimateCompleteness;
  final FiscalCompanionAction nextAction;
}

final class TaxEstimateSnapshot {
  const TaxEstimateSnapshot({
    required this.taxYear,
    required this.engineVersion,
    required this.inputsFingerprint,
    required this.resultCents,
    required this.completeness,
  });

  factory TaxEstimateSnapshot.create({
    required int taxYear,
    required String engineVersion,
    required Map<String, Object?> normalizedInputs,
    required int? resultCents,
    required EstimateCompleteness completeness,
  }) {
    final canonical = normalizedInputs.keys.toList()..sort();
    final source = canonical
        .map((key) => '$key=${normalizedInputs[key]}')
        .join('|');
    return TaxEstimateSnapshot(
      taxYear: taxYear,
      engineVersion: engineVersion,
      inputsFingerprint: _fnv1a64(source),
      resultCents: resultCents,
      completeness: completeness,
    );
  }

  final int taxYear;
  final String engineVersion;
  final String inputsFingerprint;
  final int? resultCents;
  final EstimateCompleteness completeness;
}

String _fnv1a64(String value) {
  var hash = BigInt.parse('cbf29ce484222325', radix: 16);
  final prime = BigInt.parse('100000001b3', radix: 16);
  final mask = BigInt.parse('ffffffffffffffff', radix: 16);
  for (final byte in value.codeUnits) {
    hash = ((hash ^ BigInt.from(byte)) * prime) & mask;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}

ProductState resetManualFiscalYear(
  ProductState product,
  int taxYear,
) => product.copyWith(
  profile: FiscalProfile(activeTaxYear: taxYear),
  incomes: product.incomes
      .where(
        (entry) =>
            entry.year != taxYear || entry.provenance != EntryProvenance.manual,
      )
      .toList(),
  expenses: product.expenses
      .where(
        (entry) =>
            entry.year != taxYear || entry.provenance != EntryProvenance.manual,
      )
      .toList(),
  snapshots: product.snapshots
      .where((entry) => entry.taxYear != taxYear)
      .toList(),
);

/// Consolidates fiscal evidence without replacing [FiscalProfile].
///
/// Profile values remain authoritative application state. This layer records
/// where candidates came from, detects conflicts, scopes them by fiscal year,
/// and decides which question or action should be presented next.
final class FiscalDataOrchestrator {
  const FiscalDataOrchestrator();

  FiscalDataOrchestrationResult consolidate({
    required ProductState product,
    TaxInterview? interview,
    EfaturaCompanionEvidence? efatura,
    Iterable<FiscalDataPoint> candidates = const [],
  }) {
    final year = product.profile.activeTaxYear;
    if (interview != null && interview.taxYear != year) {
      throw ArgumentError.value(interview.taxYear, 'interview.taxYear');
    }
    if (efatura != null && efatura.taxYear != year) {
      throw ArgumentError.value(efatura.taxYear, 'efatura.taxYear');
    }

    final profileFacts = _profileFacts(product.profile);
    final ledgerFacts = <FiscalDataPoint>[
      if (product.incomes.any((entry) => entry.year == year))
        FiscalDataPoint(
          id: 'knownIncomeCents',
          value: product.incomeTotal.cents,
          source: FiscalDataSource.calculated,
          confidence: FiscalDataConfidence.confirmed,
          taxYear: year,
        ),
      if (product.expenses.any((entry) => entry.year == year))
        FiscalDataPoint(
          id: 'knownExpenseCents',
          value: product.expenseTotal.cents,
          source: FiscalDataSource.calculated,
          confidence: FiscalDataConfidence.confirmed,
          taxYear: year,
        ),
    ];
    final interviewFacts = interview == null
        ? const <FiscalDataPoint>[]
        : interview.answers.values.map(
            (answer) => FiscalDataPoint(
              id: answer.questionId,
              value: answer.value,
              source: answer.provenance == TaxFactProvenance.userEntered
                  ? FiscalDataSource.interview
                  : FiscalDataSource.imported,
              confidence: FiscalDataConfidence.confirmed,
              taxYear: year,
              isUserOverride:
                  answer.provenance == TaxFactProvenance.userEntered,
            ),
          );
    final officialFacts = efatura == null || !efatura.available
        ? const <FiscalDataPoint>[]
        : <FiscalDataPoint>[
            if (efatura.pendingCount case final pending?)
              FiscalDataPoint(
                id: 'efaturaPendingCount',
                value: pending,
                source: FiscalDataSource.official,
                confidence: FiscalDataConfidence.confirmed,
                taxYear: year,
                lastUpdatedAt: efatura.lastUpdatedAt,
              ),
            if (efatura.invoiceCount case final invoiceCount?)
              FiscalDataPoint(
                id: 'efaturaInvoiceCount',
                value: invoiceCount,
                source: FiscalDataSource.official,
                confidence: FiscalDataConfidence.confirmed,
                taxYear: year,
                lastUpdatedAt: efatura.lastUpdatedAt,
              ),
          ];

    final facts = <String, FiscalDataPoint>{};
    final conflicts = <FiscalDataConflict>[];
    for (final point in [
      ...profileFacts,
      ...ledgerFacts,
      ...interviewFacts,
      ...officialFacts,
      ...candidates.where((candidate) => candidate.taxYear == year),
    ]) {
      final current = facts[point.id];
      if (current == null) {
        facts[point.id] = point;
        continue;
      }
      if (current.value == point.value) {
        if (_priority(point) > _priority(current)) facts[point.id] = point;
        continue;
      }
      conflicts.add(
        FiscalDataConflict(id: point.id, current: current, candidate: point),
      );
      if (point.isUserOverride || _priority(point) > _priority(current)) {
        facts[point.id] = point;
      }
    }

    final missing = _missing(product.profile, interview);
    final sections = _sectionStates(interview, conflicts, missing, efatura);
    final unsupported = [
      'selfEmploymentIncome',
      'pensionIncome',
      'foreignIncome',
      'rentalIncome',
    ].any((id) => facts[id]?.value == true);
    final requiredMissing = missing.any(
      (item) => item.severity == TaxMissingDataSeverity.requiredForCalculation,
    );
    final completeness = requiredMissing
        ? EstimateCompleteness.incomplete
        : unsupported
        ? EstimateCompleteness.provisional
        : interview?.completed == true
        ? EstimateCompleteness.ready
        : EstimateCompleteness.incomplete;
    final pending = facts['efaturaPendingCount']?.value;
    final action = conflicts.isNotEmpty || requiredMissing
        ? FiscalCompanionAction.completeProfile
        : interview?.completed != true
        ? FiscalCompanionAction.continueInterview
        : pending is int && pending > 0
        ? FiscalCompanionAction.reviewEfatura
        : completeness == EstimateCompleteness.provisional
        ? FiscalCompanionAction.reviewEstimate
        : FiscalCompanionAction.noAction;

    return FiscalDataOrchestrationResult(
      facts: Map.unmodifiable(facts),
      conflicts: List.unmodifiable(conflicts),
      missing: List.unmodifiable(missing),
      sections: Map.unmodifiable(sections),
      estimateCompleteness: completeness,
      nextAction: action,
    );
  }

  FiscalDataOrchestrationResult resolveConflict({
    required ProductState product,
    required TaxInterview interview,
    required FiscalDataConflict conflict,
    required Object? selectedValue,
  }) {
    final updated = interview.copyWith(
      answers: {
        ...interview.answers,
        conflict.id: TaxAnswer(
          questionId: conflict.id,
          value: selectedValue,
          provenance: TaxFactProvenance.userEntered,
        ),
      },
    );
    return consolidate(product: product, interview: updated);
  }

  int _priority(FiscalDataPoint point) => point.isUserOverride
      ? 100
      : switch (point.source) {
          FiscalDataSource.userEntered || FiscalDataSource.interview => 90,
          FiscalDataSource.official => 80,
          FiscalDataSource.imported => 60,
          FiscalDataSource.calculated => 50,
          FiscalDataSource.inferred => 20,
        };

  List<FiscalDataPoint> _profileFacts(FiscalProfile profile) => [
    FiscalDataPoint(
      id: 'taxYear',
      value: profile.activeTaxYear,
      source: FiscalDataSource.userEntered,
      confidence: FiscalDataConfidence.confirmed,
      taxYear: profile.activeTaxYear,
    ),
    if (profile.region case final value?)
      FiscalDataPoint(
        id: 'region',
        value: value.name,
        source: FiscalDataSource.userEntered,
        confidence: FiscalDataConfidence.confirmed,
        taxYear: profile.activeTaxYear,
      ),
    if (profile.civilStatus case final value?)
      FiscalDataPoint(
        id: 'civilStatus',
        value: value.name,
        source: FiscalDataSource.userEntered,
        confidence: FiscalDataConfidence.confirmed,
        taxYear: profile.activeTaxYear,
      ),
    if (profile.dependentCount case final value?)
      FiscalDataPoint(
        id: 'dependentCount',
        value: value,
        source: FiscalDataSource.userEntered,
        confidence: FiscalDataConfidence.confirmed,
        taxYear: profile.activeTaxYear,
      ),
    if (profile.hasEmployment case final value?)
      FiscalDataPoint(
        id: 'employmentIncome',
        value: value,
        source: FiscalDataSource.userEntered,
        confidence: FiscalDataConfidence.confirmed,
        taxYear: profile.activeTaxYear,
      ),
    if (profile.hasSelfEmployment case final value?)
      FiscalDataPoint(
        id: 'selfEmploymentIncome',
        value: value,
        source: FiscalDataSource.userEntered,
        confidence: FiscalDataConfidence.confirmed,
        taxYear: profile.activeTaxYear,
      ),
  ];

  List<TaxMissingDataItem> _missing(
    FiscalProfile profile,
    TaxInterview? interview,
  ) => [
    for (final id in profile.missingFields)
      TaxMissingDataItem(
        id: id,
        area: switch (id) {
          'civilStatus' || 'dependentCount' => TaxInterviewSectionId.family,
          'hasEmployment' ||
          'hasSelfEmployment' => TaxInterviewSectionId.workAndIncome,
          _ => TaxInterviewSectionId.aboutYou,
        },
        severity: TaxMissingDataSeverity.requiredForCalculation,
        reason: 'profile_incomplete',
        action: FiscalCompanionAction.completeProfile,
      ),
    if (interview != null && !interview.completed)
      const TaxMissingDataItem(
        id: 'interview',
        area: TaxInterviewSectionId.review,
        severity: TaxMissingDataSeverity.improvesEstimate,
        reason: 'interview_incomplete',
        action: FiscalCompanionAction.continueInterview,
      ),
  ];

  Map<TaxInterviewSectionId, InterviewSectionState> _sectionStates(
    TaxInterview? interview,
    List<FiscalDataConflict> conflicts,
    List<TaxMissingDataItem> missing,
    EfaturaCompanionEvidence? efatura,
  ) => {
    for (final section in TaxInterviewSectionId.values)
      section:
          (section == TaxInterviewSectionId.expenses &&
              efatura?.needsReview == true)
          ? InterviewSectionState.needsReview
          : conflicts.any((conflict) => _sectionForFact(conflict.id) == section)
          ? InterviewSectionState.needsReview
          : missing.any((item) => item.area == section)
          ? InterviewSectionState.incomplete
          : InterviewSectionState.clean,
  };

  TaxInterviewSectionId _sectionForFact(String id) => switch (id) {
    'civilStatus' || 'dependentCount' => TaxInterviewSectionId.family,
    'employmentIncome' ||
    'selfEmploymentIncome' => TaxInterviewSectionId.workAndIncome,
    'foreignIncome' || 'rentalIncome' => TaxInterviewSectionId.otherIncome,
    'expensesReviewed' ||
    'efaturaInvoiceCount' ||
    'efaturaPendingCount' => TaxInterviewSectionId.expenses,
    'withholdingCents' ||
    'socialSecurityCents' => TaxInterviewSectionId.withholdingAndPayments,
    _ => TaxInterviewSectionId.aboutYou,
  };
}
