import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import '../fiscal_data/fiscal_data_orchestrator.dart';
import '../l10n/app_localizations.dart';
import '../l10n/taxy_formatters.dart';
import '../state/providers.dart';
import '../tax_engine/tax_engine.dart';
import 'document_evidence.dart';
import 'guided_tax_providers.dart';
import 'guided_tax_simulation.dart';
import 'tax_interview_engine.dart';
import 'tax_interview_models.dart';
import 'tax_review_models.dart';

final class GuidedTaxReviewScreen extends ConsumerStatefulWidget {
  const GuidedTaxReviewScreen({
    super.key,
    required this.taxYear,
    this.interview,
    this.onEditQuestion,
    this.onOpenDocuments,
    this.onOpenEfatura,
  });

  final int taxYear;
  final TaxInterview? interview;
  final ValueChanged<String>? onEditQuestion;
  final VoidCallback? onOpenDocuments;
  final VoidCallback? onOpenEfatura;

  @override
  ConsumerState<GuidedTaxReviewScreen> createState() =>
      _GuidedTaxReviewScreenState();
}

final class _GuidedTaxReviewScreenState
    extends ConsumerState<GuidedTaxReviewScreen> {
  static const _orchestrator = FiscalDataOrchestrator();
  static const _reviewService = TaxReviewService();
  TaxInterview? _resolvedInterview;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final product = ref.watch(productStateProvider);
    final stored = ref.watch(taxInterviewForYearProvider(widget.taxYear));
    final efatura = ref.watch(efaturaEvidenceForYearProvider(widget.taxYear));
    final documents = ref.watch(
      documentEvidenceForYearProvider(widget.taxYear),
    );
    final interview = _resolvedInterview ?? widget.interview ?? stored.value;
    if (product.isLoading || stored.isLoading || documents.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.taxReviewTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (product.hasError || interview == null || documents.hasError) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.taxReviewTitle)),
        body: Center(child: Text(l10n.calculationUnavailable)),
      );
    }
    final productValue = product.requireValue;
    final orchestration = _orchestrator.consolidate(
      product: productValue,
      interview: interview,
      efatura: efatura.value,
      candidates: _documentCandidates(documents.value ?? const []),
    );
    final simulation = simulationFromInterview(interview, now: DateTime.now());
    final region = productValue.profile.region ?? TaxRegion.continent;
    final rules = ref.watch(
      rulesForProvider((year: widget.taxYear, region: region)),
    );
    return rules.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.taxReviewTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.taxReviewTitle)),
        body: Center(child: Text(l10n.calculationUnavailable)),
      ),
      data: (ruleSet) {
        final taxResult = simulation == null
            ? null
            : TaxEngine(ruleSet).calculate(simulation);
        final review = _reviewService.build(
          interview: interview,
          orchestration: orchestration,
          taxResult: taxResult,
        );
        return Scaffold(
          appBar: AppBar(title: Text(l10n.taxReviewTitle)),
          body: ListView(
            key: const Key('guided-tax-review'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _EstimateHero(review: review, taxResult: taxResult),
              const SizedBox(height: 12),
              _PrimaryActionCard(
                review: review,
                onPressed: () => _runPrimaryAction(review, interview),
              ),
              if (orchestration.conflicts.isNotEmpty) ...[
                const SizedBox(height: 12),
                _ConflictCenter(
                  conflicts: orchestration.conflicts,
                  saving: _saving,
                  onResolve: (conflict, selected) =>
                      _resolve(interview, conflict, selected),
                ),
              ],
              if (review.missing.isNotEmpty) ...[
                const SizedBox(height: 12),
                _MissingPanel(
                  items: review.missing,
                  onEdit: widget.onEditQuestion,
                ),
              ],
              if (review.unsupportedFactIds.isNotEmpty) ...[
                const SizedBox(height: 12),
                _UnsupportedPanel(factIds: review.unsupportedFactIds),
              ],
              if (review.explainability != null &&
                  review.estimatePresentation !=
                      TaxEstimatePresentation.hideEstimate) ...[
                const SizedBox(height: 12),
                _ExplainabilityCard(
                  model: review.explainability!,
                  facts: orchestration.facts,
                ),
              ],
              const SizedBox(height: 12),
              _InclusionCard(review: review),
              if (orchestration.facts['efaturaPendingCount']?.value
                  case final int pending) ...[
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: const Text('e-Fatura'),
                    subtitle: Text(l10n.guidedTaxPendingEfatura(pending)),
                    trailing: widget.onOpenEfatura == null
                        ? null
                        : const Icon(Icons.chevron_right),
                    onTap: widget.onOpenEfatura,
                  ),
                ),
              ],
              if (widget.onOpenDocuments != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(l10n.guidedDocumentsTitle),
                    subtitle: Text(l10n.guidedDocumentsPrivacy),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: widget.onOpenDocuments,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _AnswerReview(
                interview: interview,
                onEdit: widget.onEditQuestion,
              ),
            ],
          ),
        );
      },
    );
  }

  List<FiscalDataPoint> _documentCandidates(
    List<GuidedDocumentEvidence> values,
  ) => [
    for (final evidence in values)
      FiscalDataPoint(
        id: evidence.factId,
        value: evidence.amountCents,
        source: FiscalDataSource.imported,
        confidence: FiscalDataConfidence.confirmed,
        taxYear: evidence.taxYear,
        lastUpdatedAt: evidence.confirmedAt,
      ),
    for (final evidence in values)
      if (evidence.type == GuidedDocumentType.employmentIncomeStatement)
        FiscalDataPoint(
          id: 'employmentIncome',
          value: true,
          source: FiscalDataSource.imported,
          confidence: FiscalDataConfidence.confirmed,
          taxYear: evidence.taxYear,
          lastUpdatedAt: evidence.confirmedAt,
        ),
  ];

  Future<void> _resolve(
    TaxInterview interview,
    FiscalDataConflict conflict,
    FiscalDataPoint selected,
  ) async {
    setState(() => _saving = true);
    final updated = _orchestrator.applyConflictResolution(
      interview: interview,
      conflict: conflict,
      selected: selected,
    );
    final product = await ref.read(productStateProvider.future);
    await ref
        .read(productRepositoryProvider)
        .save(
          product.copyWith(
            profile: profileFromInterview(updated, product.profile),
          ),
        );
    await ref.read(taxInterviewRepositoryProvider).save(updated);
    ref.invalidate(productStateProvider);
    ref.invalidate(taxInterviewForYearProvider(widget.taxYear));
    if (!mounted) return;
    setState(() {
      _resolvedInterview = updated;
      _saving = false;
    });
  }

  void _runPrimaryAction(TaxReviewResult review, TaxInterview interview) {
    switch (review.primaryAction) {
      case TaxReviewNextAction.resolveConflict:
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 250),
        );
        return;
      case TaxReviewNextAction.addRequiredData:
        final id = review.missing
            .where((item) => item.priority == TaxMissingPriority.required)
            .firstOrNull
            ?.factId;
        if (id != null) widget.onEditQuestion?.call(id);
        return;
      case TaxReviewNextAction.continueInterview:
        final questionId = interview.currentQuestionId;
        if (questionId != null) widget.onEditQuestion?.call(questionId);
        return;
      case TaxReviewNextAction.reviewEfatura:
        widget.onOpenEfatura?.call();
        return;
      case TaxReviewNextAction.reviewUnsupported:
      case TaxReviewNextAction.reviewEstimate:
      case TaxReviewNextAction.noAction:
        return;
    }
  }
}

final class _EstimateHero extends StatelessWidget {
  const _EstimateHero({required this.review, required this.taxResult});
  final TaxReviewResult review;
  final TaxResult? taxResult;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = _completenessLabel(l10n, review.completeness);
    final resolvedTaxResult = taxResult;
    final show =
        review.estimatePresentation != TaxEstimatePresentation.hideEstimate &&
        resolvedTaxResult != null;
    final amount = show
        ? TaxyFormatters.euros(context, resolvedTaxResult.balance.cents.abs())
        : null;
    final result = show
        ? resolvedTaxResult.isRefund
              ? l10n.taxReviewRefund(amount!)
              : l10n.taxReviewPayable(amount!)
        : l10n.taxReviewEstimateHidden;
    return Semantics(
      container: true,
      header: true,
      label: '${l10n.guidedTaxEstimate}. $status. $result',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.guidedTaxEstimate,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                result,
                key: const Key('review-estimate-result'),
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Chip(label: Text(status)),
              const SizedBox(height: 4),
              Text(l10n.taxReviewEstimateDisclaimer),
            ],
          ),
        ),
      ),
    );
  }
}

final class _PrimaryActionCard extends StatelessWidget {
  const _PrimaryActionCard({required this.review, required this.onPressed});
  final TaxReviewResult review;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = _nextActionLabel(l10n, review.primaryAction);
    final actionable =
        review.primaryAction != TaxReviewNextAction.noAction &&
        review.primaryAction != TaxReviewNextAction.reviewEstimate;
    return Semantics(
      button: actionable,
      label: '${l10n.guidedTaxNextAction}. $label',
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.assistant_direction_outlined),
          title: Text(l10n.guidedTaxNextAction),
          subtitle: Text(label),
          trailing: actionable ? const Icon(Icons.arrow_forward) : null,
          onTap: actionable ? onPressed : null,
        ),
      ),
    );
  }
}

final class _ConflictCenter extends StatelessWidget {
  const _ConflictCenter({
    required this.conflicts,
    required this.saving,
    required this.onResolve,
  });
  final List<FiscalDataConflict> conflicts;
  final bool saving;
  final void Function(FiscalDataConflict, FiscalDataPoint) onResolve;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      container: true,
      label: l10n.taxReviewConflictSemantics,
      child: Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.taxReviewConflictsTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(l10n.dataConflictBody),
              for (final conflict in conflicts) ...[
                const SizedBox(height: 16),
                Text(
                  _factLabel(l10n, conflict.id),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _ConflictOption(
                  factId: conflict.id,
                  point: conflict.current,
                  enabled: !saving,
                  onTap: () => onResolve(conflict, conflict.current),
                ),
                const SizedBox(height: 8),
                _ConflictOption(
                  factId: conflict.id,
                  point: conflict.candidate,
                  enabled: !saving,
                  onTap: () => onResolve(conflict, conflict.candidate),
                ),
                TextButton(
                  onPressed: saving
                      ? null
                      : () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.guidedTaxSaved)),
                        ),
                  child: Text(l10n.taxReviewLater),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

final class _ConflictOption extends StatelessWidget {
  const _ConflictOption({
    required this.factId,
    required this.point,
    required this.enabled,
    required this.onTap,
  });
  final String factId;
  final FiscalDataPoint point;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Text(_sourceLabel(l10n, point.source)),
              Text(
                _valueLabel(context, factId, point.value),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _MissingPanel extends StatelessWidget {
  const _MissingPanel({required this.items, required this.onEdit});
  final List<TaxReviewMissingItem> items;
  final ValueChanged<String>? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sorted = [...items]
      ..sort((a, b) => a.priority.index.compareTo(b.priority.index));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.taxReviewMissingTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            for (final item in sorted)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_factLabel(l10n, item.factId)),
                subtitle: Text(_missingPriorityLabel(l10n, item.priority)),
                trailing: onEdit == null
                    ? null
                    : const Icon(Icons.edit_outlined),
                onTap: onEdit == null ? null : () => onEdit!(item.factId),
              ),
          ],
        ),
      ),
    );
  }
}

final class _UnsupportedPanel extends StatelessWidget {
  const _UnsupportedPanel({required this.factIds});
  final List<String> factIds;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      container: true,
      label: l10n.taxReviewNotIncluded,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.taxReviewSituationsTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(l10n.taxReviewUnsupportedBody),
              for (final id in factIds)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline),
                  title: Text(_factLabel(l10n, id)),
                  subtitle: Text(l10n.taxReviewNotIncluded),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _ExplainabilityCard extends StatelessWidget {
  const _ExplainabilityCard({required this.model, required this.facts});
  final TaxExplainabilityViewModel model;
  final Map<String, FiscalDataPoint> facts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ExpansionTile(
        title: Text(l10n.guidedTaxHowResult),
        subtitle: Text(l10n.taxReviewBreakdownSubtitle),
        children: [
          for (final line in model.lines)
            ListTile(
              title: Text(_explainabilityLabel(l10n, line.id)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (facts[line.id] != null)
                    Text(_sourceLabel(l10n, facts[line.id]!.source)),
                  Text(
                    TaxyFormatters.euros(context, line.amount.cents),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

final class _InclusionCard extends StatelessWidget {
  const _InclusionCard({required this.review});
  final TaxReviewResult review;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final included = review.inclusion.entries
        .where((entry) => entry.value == TaxCalculationInclusion.included)
        .toList();
    return Card(
      child: ExpansionTile(
        title: Text(l10n.taxReviewIncludedTitle),
        children: [
          if (included.isEmpty)
            ListTile(title: Text(l10n.noDataAvailable))
          else
            for (final entry in included)
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: Text(_factLabel(l10n, entry.key)),
              ),
        ],
      ),
    );
  }
}

final class _AnswerReview extends StatelessWidget {
  const _AnswerReview({required this.interview, required this.onEdit});
  final TaxInterview interview;
  final ValueChanged<String>? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visible = const TaxInterviewEngine().visibleQuestions(interview);
    final sections = TaxInterviewSectionId.values
        .where(
          (section) => visible.any(
            (question) =>
                question.section == section &&
                interview.answers.containsKey(question.id),
          ),
        )
        .toList(growable: false);
    return Card(
      child: ExpansionTile(
        title: Text(l10n.guidedTaxReviewAnswers),
        children: [
          for (final section in sections)
            ExpansionTile(
              title: Text(_sectionLabel(l10n, section)),
              children: [
                for (final question in visible)
                  if (question.section == section &&
                      interview.answers.containsKey(question.id))
                    ListTile(
                      title: Text(
                        _questionLabel(l10n, question, interview.taxYear),
                      ),
                      subtitle:
                          interview.answers[question.id]!.provenance ==
                              TaxFactProvenance.userEntered
                          ? null
                          : Text(
                              _sourceForProvenance(
                                l10n,
                                interview.answers[question.id]!.provenance,
                              ),
                            ),
                      trailing: onEdit == null
                          ? null
                          : const Icon(Icons.edit_outlined),
                      onTap: onEdit == null ? null : () => onEdit!(question.id),
                    ),
              ],
            ),
        ],
      ),
    );
  }
}

String _completenessLabel(AppLocalizations l10n, TaxReviewCompleteness value) =>
    switch (value) {
      TaxReviewCompleteness.ready => l10n.taxReviewReady,
      TaxReviewCompleteness.needsReview => l10n.taxReviewNeedsReview,
      TaxReviewCompleteness.incomplete => l10n.taxReviewIncomplete,
      TaxReviewCompleteness.unsupportedSituation => l10n.taxReviewUnsupported,
    };

String _nextActionLabel(AppLocalizations l10n, TaxReviewNextAction action) =>
    switch (action) {
      TaxReviewNextAction.resolveConflict => l10n.taxReviewActionConflict,
      TaxReviewNextAction.addRequiredData => l10n.taxReviewActionMissing,
      TaxReviewNextAction.reviewUnsupported => l10n.taxReviewActionUnsupported,
      TaxReviewNextAction.continueInterview => l10n.fiscalCompanionContinue,
      TaxReviewNextAction.reviewEfatura => l10n.fiscalCompanionReviewEfatura,
      TaxReviewNextAction.reviewEstimate => l10n.taxReviewActionEstimate,
      TaxReviewNextAction.noAction => l10n.fiscalCompanionNoAction,
    };

String _missingPriorityLabel(AppLocalizations l10n, TaxMissingPriority value) =>
    switch (value) {
      TaxMissingPriority.required => l10n.taxReviewRequired,
      TaxMissingPriority.recommended => l10n.taxReviewRecommended,
      TaxMissingPriority.optional => l10n.taxReviewOptional,
    };

String _sourceLabel(AppLocalizations l10n, FiscalDataSource source) =>
    switch (source) {
      FiscalDataSource.userEntered ||
      FiscalDataSource.interview => l10n.sourceUser,
      FiscalDataSource.imported => l10n.taxReviewSourceDocument,
      FiscalDataSource.official => l10n.sourceEfatura,
      FiscalDataSource.calculated => l10n.sourceCalculated,
      FiscalDataSource.inferred => l10n.sourceExternal,
    };

String _sourceForProvenance(
  AppLocalizations l10n,
  TaxFactProvenance provenance,
) => switch (provenance) {
  TaxFactProvenance.userEntered => l10n.sourceUser,
  TaxFactProvenance.imported => l10n.taxReviewSourceDocument,
  TaxFactProvenance.official => l10n.sourceEfatura,
  TaxFactProvenance.calculated => l10n.sourceCalculated,
  TaxFactProvenance.inferred => l10n.sourceExternal,
};

String _valueLabel(BuildContext context, String factId, Object? value) =>
    switch (value) {
      int cents when factId.endsWith('Cents') => TaxyFormatters.euros(
        context,
        cents,
      ),
      int value => value.toString(),
      bool enabled => enabled ? '✓' : '—',
      null => '—',
      _ => value.toString(),
    };

String _sectionLabel(AppLocalizations l10n, TaxInterviewSectionId id) =>
    switch (id) {
      TaxInterviewSectionId.aboutYou => l10n.aboutYou,
      TaxInterviewSectionId.family => l10n.family,
      TaxInterviewSectionId.workAndIncome => l10n.workAndIncome,
      TaxInterviewSectionId.otherIncome => l10n.otherIncome,
      TaxInterviewSectionId.expenses => l10n.expenses,
      TaxInterviewSectionId.withholdingAndPayments =>
        l10n.withholdingAndPayments,
      TaxInterviewSectionId.review => l10n.review,
    };

String _questionLabel(AppLocalizations l10n, TaxQuestion q, int taxYear) =>
    switch (q.titleKey) {
      'qResidentPortugal' => l10n.qResidentPortugal(taxYear),
      'qRegion' => l10n.qRegion,
      'qAge' => l10n.qAge(taxYear),
      'qCivilStatus' => l10n.qCivilStatus(taxYear),
      'qJointTaxation' => l10n.qJointTaxation,
      'qDependents' => l10n.qDependents,
      'qEmployment' => l10n.qEmployment(taxYear),
      'qEmploymentGross' => l10n.qEmploymentGross,
      'qSelfEmployment' => l10n.qSelfEmployment,
      'qPension' => l10n.qPension,
      'qForeignIncome' => l10n.qForeignIncome,
      'qRentalIncome' => l10n.qRentalIncome,
      'qExpensesReviewed' => l10n.qExpensesReviewed,
      'qWithholding' => l10n.qWithholding,
      'qSocialSecurity' => l10n.qSocialSecurity,
      _ => l10n.qReview,
    };

String _factLabel(AppLocalizations l10n, String id) => switch (id) {
  'employmentGrossCents' || 'employmentGross' => l10n.guidedTaxIncome,
  'withholdingCents' || 'withholding' => l10n.guidedTaxWithholding,
  'socialSecurityCents' || 'socialSecurity' => l10n.taxReviewSocialSecurity,
  'taxCredits' => l10n.guidedTaxDeductions,
  'selfEmploymentIncome' => l10n.complexIncomeSelfEmployment,
  'pensionIncome' => l10n.complexIncomePension,
  'foreignIncome' => l10n.complexIncomeForeign,
  'rentalIncome' => l10n.complexIncomeRental,
  'residentPortugal' => l10n.aboutYou,
  'region' ||
  'age' ||
  'civilStatus' ||
  'jointTaxation' ||
  'dependentCount' => l10n.aboutYou,
  'employmentIncome' => l10n.workAndIncome,
  'expensesReviewed' => l10n.expenses,
  'reviewConfirmed' => l10n.review,
  _ => l10n.taxReviewInformation,
};

String _explainabilityLabel(AppLocalizations l10n, String id) => switch (id) {
  'employmentGrossCents' => l10n.taxReviewIncomeConsidered,
  'taxCredits' => l10n.taxReviewDeductionsConsidered,
  'taxDue' => l10n.taxReviewEstimatedTax,
  'withholdingCents' => l10n.taxReviewWithholdingConsidered,
  _ => l10n.guidedTaxResult,
};
