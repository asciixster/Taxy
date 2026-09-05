import '../domain/models.dart';
import '../domain/money.dart';
import '../fiscal_data/fiscal_data_orchestrator.dart';
import 'tax_interview_engine.dart';
import 'tax_interview_models.dart';

enum TaxReviewCompleteness {
  ready,
  needsReview,
  incomplete,
  unsupportedSituation,
}

enum TaxCalculationInclusion {
  included,
  excludedUnsupported,
  missing,
  conflicted,
  notRelevant,
}

enum TaxEstimatePresentation {
  showCompleteEstimate,
  showPartialEstimate,
  hideEstimate,
}

enum TaxReviewNextAction {
  resolveConflict,
  addRequiredData,
  reviewUnsupported,
  continueInterview,
  reviewEfatura,
  reviewEstimate,
  noAction,
}

final class TaxReviewMissingItem {
  const TaxReviewMissingItem({required this.factId, required this.priority});

  final String factId;
  final TaxMissingPriority priority;
}

final class TaxExplainabilityLine {
  const TaxExplainabilityLine({required this.id, required this.amount});

  final String id;
  final Money amount;
}

final class TaxExplainabilityViewModel {
  const TaxExplainabilityViewModel({
    required this.isRefund,
    required this.lines,
  });

  factory TaxExplainabilityViewModel.fromTaxResult(TaxResult result) =>
      TaxExplainabilityViewModel(
        isRefund: result.isRefund,
        lines: [
          TaxExplainabilityLine(
            id: 'employmentGrossCents',
            amount: result.grossIncome,
          ),
          TaxExplainabilityLine(id: 'taxCredits', amount: result.taxCredits),
          TaxExplainabilityLine(id: 'taxDue', amount: result.taxDue),
          TaxExplainabilityLine(
            id: 'withholdingCents',
            amount: result.withholding,
          ),
          TaxExplainabilityLine(id: 'balance', amount: result.balance),
        ],
      );

  final bool isRefund;
  final List<TaxExplainabilityLine> lines;
}

final class TaxReviewResult {
  const TaxReviewResult({
    required this.completeness,
    required this.estimatePresentation,
    required this.inclusion,
    required this.missing,
    required this.unsupportedFactIds,
    required this.primaryAction,
    required this.explainability,
  });

  final TaxReviewCompleteness completeness;
  final TaxEstimatePresentation estimatePresentation;
  final Map<String, TaxCalculationInclusion> inclusion;
  final List<TaxReviewMissingItem> missing;
  final List<String> unsupportedFactIds;
  final TaxReviewNextAction primaryAction;
  final TaxExplainabilityViewModel? explainability;
}

abstract final class TaxEstimatePresentationPolicy {
  static TaxEstimatePresentation decide({
    required TaxReviewCompleteness completeness,
    required TaxResult? taxResult,
  }) {
    if (taxResult == null || !taxResult.available) {
      return TaxEstimatePresentation.hideEstimate;
    }
    return switch (completeness) {
      TaxReviewCompleteness.ready =>
        TaxEstimatePresentation.showCompleteEstimate,
      TaxReviewCompleteness.needsReview =>
        TaxEstimatePresentation.showPartialEstimate,
      TaxReviewCompleteness.incomplete ||
      TaxReviewCompleteness.unsupportedSituation =>
        TaxEstimatePresentation.hideEstimate,
    };
  }
}

final class TaxReviewService {
  const TaxReviewService();

  static const unsupportedFactIds = <String>[
    'selfEmploymentIncome',
    'pensionIncome',
    'foreignIncome',
    'rentalIncome',
  ];

  TaxReviewResult build({
    required TaxInterview interview,
    required FiscalDataOrchestrationResult orchestration,
    required TaxResult? taxResult,
  }) {
    final interviewResult = const TaxInterviewEngine().result(interview);
    final missing = interviewResult.missing
        .map(
          (item) => TaxReviewMissingItem(
            factId: item.factId,
            priority: item.priority,
          ),
        )
        .toList(growable: false);
    final unsupported = [
      for (final id in unsupportedFactIds)
        if (orchestration.facts[id]?.value == true) id,
    ];
    final hasRequiredMissing = missing.any(
      (item) => item.priority == TaxMissingPriority.required,
    );
    final completeness = orchestration.conflicts.isNotEmpty
        ? TaxReviewCompleteness.needsReview
        : hasRequiredMissing
        ? TaxReviewCompleteness.incomplete
        : unsupported.isNotEmpty
        ? TaxReviewCompleteness.unsupportedSituation
        : taxResult != null && taxResult.available
        ? TaxReviewCompleteness.ready
        : TaxReviewCompleteness.incomplete;
    final presentation = TaxEstimatePresentationPolicy.decide(
      completeness: completeness,
      taxResult: taxResult,
    );
    final inclusion = <String, TaxCalculationInclusion>{};
    for (final id in [
      'employmentGrossCents',
      'withholdingCents',
      'socialSecurityCents',
      ...unsupportedFactIds,
    ]) {
      inclusion[id] =
          orchestration.conflicts.any((conflict) => conflict.id == id)
          ? TaxCalculationInclusion.conflicted
          : missing.any((item) => item.factId == id)
          ? TaxCalculationInclusion.missing
          : unsupported.contains(id)
          ? TaxCalculationInclusion.excludedUnsupported
          : orchestration.facts[id]?.value == false
          ? TaxCalculationInclusion.notRelevant
          : taxResult != null &&
                const {
                  'employmentGrossCents',
                  'withholdingCents',
                  'socialSecurityCents',
                }.contains(id)
          ? TaxCalculationInclusion.included
          : TaxCalculationInclusion.notRelevant;
    }
    if (taxResult != null) {
      inclusion['taxCredits'] = TaxCalculationInclusion.included;
    }
    final pending = orchestration.facts['efaturaPendingCount']?.value;
    final action = orchestration.conflicts.isNotEmpty
        ? TaxReviewNextAction.resolveConflict
        : hasRequiredMissing
        ? TaxReviewNextAction.addRequiredData
        : unsupported.isNotEmpty
        ? TaxReviewNextAction.reviewUnsupported
        : !interview.completed
        ? TaxReviewNextAction.continueInterview
        : pending is int && pending > 0
        ? TaxReviewNextAction.reviewEfatura
        : taxResult != null &&
              interview.answers['reviewConfirmed']?.value != true
        ? TaxReviewNextAction.reviewEstimate
        : TaxReviewNextAction.noAction;
    return TaxReviewResult(
      completeness: completeness,
      estimatePresentation: presentation,
      inclusion: Map.unmodifiable(inclusion),
      missing: List.unmodifiable(missing),
      unsupportedFactIds: List.unmodifiable(unsupported),
      primaryAction: action,
      explainability: taxResult == null
          ? null
          : TaxExplainabilityViewModel.fromTaxResult(taxResult),
    );
  }
}
