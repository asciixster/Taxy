import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import '../domain/money.dart';
import '../fiscal_data/fiscal_data_orchestrator.dart';
import '../l10n/app_localizations.dart';
import '../l10n/taxy_formatters.dart';
import '../product/product_models.dart';
import '../state/providers.dart';
import '../modules/dm3irs/domain/historical_tax_evidence.dart';
import '../modules/dm3irs/screens/irs_history_prefill_screen.dart';
import '../tax_engine/tax_engine.dart';
import 'tax_interview_engine.dart';
import 'tax_interview_models.dart';
import 'document_evidence.dart';
import 'document_evidence_screen.dart';
import 'guided_tax_providers.dart';
import 'guided_tax_review_screen.dart';
import 'guided_tax_simulation.dart';
import 'secure_document_capture.dart';

export 'guided_tax_providers.dart';

final class GuidedTaxScreen extends ConsumerStatefulWidget {
  const GuidedTaxScreen({super.key, required this.taxYear});
  final int taxYear;

  @override
  ConsumerState<GuidedTaxScreen> createState() => _GuidedTaxScreenState();
}

final class _GuidedTaxScreenState extends ConsumerState<GuidedTaxScreen> {
  static const _engine = TaxInterviewEngine();
  TaxInterview? _interview;
  bool _loading = true;
  bool _showResult = false;
  bool _editingCompletedInterview = false;
  bool _estimateChanged = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final stored = await ref
          .read(taxInterviewRepositoryProvider)
          .load(widget.taxYear);
      final product = await ref.read(productStateProvider.future);
      final interview = stored ?? _prefill(product);
      if (!mounted) return;
      setState(() {
        _interview = interview;
        _loading = false;
        _showResult = interview.completed;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'load';
      });
    }
  }

  TaxInterview _prefill(ProductState product) {
    final profile = product.profile;
    final answers = <String, TaxAnswer>{};
    void imported(String id, Object? value) {
      if (value != null) {
        answers[id] = TaxAnswer(
          questionId: id,
          value: value,
          provenance: TaxFactProvenance.imported,
        );
      }
    }

    imported('region', profile.region?.name);
    imported('civilStatus', profile.civilStatus?.name);
    imported('dependentCount', profile.dependentCount);
    imported('employmentIncome', profile.hasEmployment);
    imported('selfEmploymentIncome', profile.hasSelfEmployment);
    final yearIncomes = product.incomes
        .where(
          (entry) =>
              entry.year == widget.taxYear &&
              entry.category == IncomeCategory.employment,
        )
        .toList();
    if (yearIncomes.isNotEmpty) {
      imported('employmentIncome', true);
      imported(
        'employmentGrossCents',
        yearIncomes.fold<int>(0, (sum, entry) => sum + entry.amount.cents),
      );
    }
    if (product.expenses.any((entry) => entry.year == widget.taxYear)) {
      imported('expensesReviewed', true);
    }
    return TaxInterview(
      taxYear: widget.taxYear,
      answers: answers,
      currentQuestionId: _engine
          .visibleQuestions(
            TaxInterview(taxYear: widget.taxYear, answers: answers),
          )
          .firstWhere(
            (q) => !answers.containsKey(q.id),
            orElse: () => TaxInterviewEngine.questions.last,
          )
          .id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.guidedTaxTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _interview == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.guidedTaxTitle)),
        body: Center(child: Text(l10n.calculationUnavailable)),
      );
    }
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (_, _) => _persist(),
      child: _showResult ? _result(l10n) : _questionFlow(l10n),
    );
  }

  Widget _questionFlow(AppLocalizations l10n) {
    final interview = _interview!;
    final questions = _engine.visibleQuestions(interview);
    final currentIndex = questions.indexWhere(
      (q) => q.id == interview.currentQuestionId,
    );
    final safeIndex = currentIndex < 0 ? 0 : currentIndex;
    final question = questions[safeIndex];
    final progress = _engine.progress(interview);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.guidedTaxYear(widget.taxYear))),
      body: SafeArea(
        child: Column(
          children: [
            Semantics(
              label: l10n.guidedTaxProgress(
                progress.completedSections.length,
                TaxInterviewEngine.sections.length,
              ),
              child: LinearProgressIndicator(
                value:
                    (progress.completedSections.length + .35) /
                    TaxInterviewEngine.sections.length,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _sectionLabel(l10n, question.section).toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Semantics(
                        header: true,
                        child: Text(
                          _title(l10n, question),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (_interview!.answers[question.id] case final answer?
                          when answer.provenance !=
                              TaxFactProvenance.userEntered) ...[
                        Semantics(
                          label: l10n.guidedTaxPrefilled,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome, size: 18),
                                const SizedBox(width: 8),
                                Flexible(child: Text(l10n.guidedTaxPrefilled)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      _answerWidget(l10n, question),
                      const SizedBox(height: 20),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text(l10n.guidedTaxWhy),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(_why(l10n, question)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.guidedTaxSaved,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  if (safeIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _goTo(questions[safeIndex - 1].id),
                        child: Text(l10n.guidedTaxBack),
                      ),
                    ),
                  if (safeIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _canContinue(question)
                          ? () => _continue(questions, safeIndex)
                          : null,
                      child: Text(
                        safeIndex == questions.length - 1
                            ? l10n.guidedTaxFinish
                            : l10n.guidedTaxNext,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _answerWidget(AppLocalizations l10n, TaxQuestion question) {
    final value = _interview!.answers[question.id]?.value;
    if (question.type == TaxQuestionType.yesNo ||
        question.type == TaxQuestionType.confirmation) {
      return SegmentedButton<bool>(
        segments: [
          ButtonSegment(value: true, label: Text(l10n.guidedTaxYes)),
          ButtonSegment(value: false, label: Text(l10n.guidedTaxNo)),
        ],
        selected: value is bool ? {value} : const {},
        emptySelectionAllowed: true,
        onSelectionChanged: (values) {
          if (values.isNotEmpty) _setAnswer(question.id, values.first);
        },
      );
    }
    if (question.type == TaxQuestionType.singleChoice) {
      return RadioGroup<Object>(
        groupValue: value,
        onChanged: (selected) => _setAnswer(question.id, selected),
        child: Column(
          children: [
            for (final option in question.options)
              RadioListTile<Object>(
                value: option.value,
                title: Text(_optionLabel(l10n, option.labelKey)),
                contentPadding: EdgeInsets.zero,
              ),
          ],
        ),
      );
    }
    if (question.type == TaxQuestionType.integer ||
        question.type == TaxQuestionType.money) {
      final initial = value is int
          ? (question.type == TaxQuestionType.money
                ? (value / 100).toStringAsFixed(2)
                : '$value')
          : '';
      return TextFormField(
        // Keep the field identity stable while typing. Re-keying it with the
        // parsed value recreates the editable state after every character.
        key: ValueKey(question.id),
        initialValue: initial,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          suffixText: question.type == TaxQuestionType.money ? '€' : null,
        ),
        onChanged: (source) {
          final normalized = source
              .trim()
              .replaceAll(' ', '')
              .replaceAll(',', '.');
          if (question.type == TaxQuestionType.money) {
            final amount = _parseCents(normalized);
            if (amount != null) _setAnswer(question.id, amount);
          } else {
            final amount = int.tryParse(normalized);
            if (amount != null && amount >= 0) _setAnswer(question.id, amount);
          }
        },
      );
    }
    return Text(l10n.guidedTaxNoAnswer);
  }

  Future<void> _setAnswer(String id, Object? value) async {
    setState(() {
      final updated = _engine.answer(
        _interview!,
        TaxAnswer(questionId: id, value: value),
      );
      _interview = _interview!.copyWith(answers: updated.answers);
    });
    await _persist();
  }

  bool _canContinue(TaxQuestion question) {
    if (!question.required) return true;
    final answer = _interview!.answers[question.id];
    if (answer == null) return false;
    if (question.type == TaxQuestionType.confirmation) {
      return answer.value == true;
    }
    return true;
  }

  Future<void> _continue(List<TaxQuestion> questions, int index) async {
    final nextIndex = List.generate(questions.length, (candidate) => candidate)
        .skip(index + 1)
        .firstWhere(
          (candidate) =>
              !_interview!.answers.containsKey(questions[candidate].id),
          orElse: () => -1,
        );
    if (nextIndex >= 0) {
      _goTo(questions[nextIndex].id);
      return;
    }
    final completed = _interview!.copyWith(completed: true);
    final product = await ref.read(productStateProvider.future);
    await ref
        .read(productRepositoryProvider)
        .save(
          product.copyWith(
            profile: profileFromInterview(completed, product.profile),
          ),
        );
    await ref.read(taxInterviewRepositoryProvider).save(completed);
    ref.invalidate(taxInterviewForYearProvider(widget.taxYear));
    final simulation = simulationFromInterview(completed, now: DateTime.now());
    if (_engine.result(completed).canEstimate && simulation != null) {
      await ref.read(repositoryProvider).save(simulation);
      ref.invalidate(simulationsProvider);
    }
    ref.invalidate(productStateProvider);
    if (!mounted) return;
    setState(() {
      _interview = completed;
      _showResult = true;
      _estimateChanged = _editingCompletedInterview;
      _editingCompletedInterview = false;
    });
  }

  void _goTo(String id) {
    setState(() => _interview = _interview!.copyWith(currentQuestionId: id));
    _persist();
  }

  Future<void> _persist() async {
    if (_interview != null) {
      await ref.read(taxInterviewRepositoryProvider).save(_interview!);
      ref.invalidate(taxInterviewForYearProvider(widget.taxYear));
    }
  }

  Widget _result(AppLocalizations l10n) {
    final interview = _interview;
    if (interview != null) {
      return GuidedTaxReviewScreen(
        taxYear: widget.taxYear,
        interview: interview,
        onEditQuestion: (questionId) => setState(() {
          _editingCompletedInterview = true;
          _showResult = false;
          _interview = _interview!.copyWith(
            currentQuestionId: questionId,
            completed: false,
          );
        }),
        onOpenDocuments: _openDocumentEvidence,
        onOpenIrsHistory: _openIrsHistory,
      );
    }
    final result = _engine.result(_interview!);
    final simulation = simulationFromInterview(
      _interview!,
      now: DateTime.now(),
    );
    final complexIncome = _complexIncomeLabels(l10n);
    final region = switch (_interview!.answers['region']?.value) {
      'madeira' => TaxRegion.madeira,
      'azores' => TaxRegion.azores,
      _ => TaxRegion.continent,
    };
    final rules = ref.watch(
      rulesForProvider((year: widget.taxYear, region: region)),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.guidedTaxEstimate)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            result.canEstimate
                ? l10n.guidedTaxEstimateGood
                : l10n.guidedTaxEstimateIncomplete,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          if (!result.canEstimate || simulation == null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(l10n.guidedTaxNotCalculation),
              ),
            )
          else
            rules.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Text(l10n.calculationUnavailable),
              data: (ruleSet) {
                final tax = TaxEngine(ruleSet).calculate(simulation);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.guidedTaxProvisionalEstimate),
                        const SizedBox(height: 8),
                        Text(
                          TaxyFormatters.euros(context, tax.balance.cents),
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.guidedTaxHowResult,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        _resultRow(l10n.guidedTaxIncome, tax.grossIncome),
                        _resultRow(l10n.guidedTaxWithholding, tax.withholding),
                        _resultRow(l10n.guidedTaxDeductions, tax.taxCredits),
                        _resultRow(l10n.guidedTaxResult, tax.balance),
                      ],
                    ),
                  ),
                );
              },
            ),
          if (_estimateChanged) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.update_rounded),
                  title: Text(l10n.estimateUpdated),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(l10n.guidedTaxNextAction),
              subtitle: Text(
                result.canEstimate
                    ? l10n.guidedTaxReviewAnswers
                    : l10n.guidedTaxUnsupported,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (complexIncome.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.complexIncomeTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(l10n.complexIncomeHint),
                    const SizedBox(height: 10),
                    for (final label in complexIncome)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(label)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Card(
            child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(l10n.guidedDocumentsTitle),
              subtitle: Text(l10n.guidedDocumentsEntryHint),
              trailing: const Icon(Icons.chevron_right),
              onTap: _openDocumentEvidence,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.guidedTaxReviewAnswers,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (final question in _engine.visibleQuestions(_interview!))
                  if (_interview!.answers.containsKey(question.id))
                    ListTile(
                      title: Text(_title(l10n, question)),
                      subtitle: _reviewSubtitle(
                        l10n,
                        question,
                        _interview!.answers[question.id]!,
                      ),
                      trailing: IconButton(
                        tooltip: l10n.guidedTaxEdit,
                        onPressed: () => setState(() {
                          _editingCompletedInterview = true;
                          _showResult = false;
                          _interview = _interview!.copyWith(
                            currentQuestionId: question.id,
                            completed: false,
                          );
                        }),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => setState(() {
              _showResult = false;
              _interview = _interview!.copyWith(
                currentQuestionId: TaxInterviewEngine.questions.first.id,
                completed: false,
              );
            }),
            icon: const Icon(Icons.edit_outlined),
            label: Text(l10n.guidedTaxReviewAnswers),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _resetTaxYear(l10n),
            icon: const Icon(Icons.restart_alt_rounded),
            label: Text(l10n.resetTaxYear),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, Money value) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(TaxyFormatters.euros(context, value.cents)),
      ],
    ),
  );

  Widget _reviewSubtitle(
    AppLocalizations l10n,
    TaxQuestion question,
    TaxAnswer answer,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(_displayAnswer(l10n, question, answer.value)),
      if (answer.provenance != TaxFactProvenance.userEntered)
        Text(
          l10n.guidedTaxPrefilled,
          style: Theme.of(context).textTheme.bodySmall,
        ),
    ],
  );

  List<String> _complexIncomeLabels(AppLocalizations l10n) => [
    if (_interview!.answers['selfEmploymentIncome']?.value == true)
      l10n.complexIncomeSelfEmployment,
    if (_interview!.answers['pensionIncome']?.value == true)
      l10n.complexIncomePension,
    if (_interview!.answers['foreignIncome']?.value == true)
      l10n.complexIncomeForeign,
    if (_interview!.answers['rentalIncome']?.value == true)
      l10n.complexIncomeRental,
  ];

  Future<void> _openDocumentEvidence() async {
    final repository = ref.read(documentEvidenceRepositoryProvider);
    final before = await repository.load(widget.taxYear);
    if (!mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentEvidenceScreen(
          taxYear: widget.taxYear,
          repository: repository,
        ),
      ),
    );
    final evidence = await repository.load(widget.taxYear);
    if (!mounted || _interview == null) return;
    final answers = reconcileDocumentEvidenceAnswers(
      current: _interview!.answers,
      before: before,
      after: evidence,
    );
    final changed = !_sameAnswers(_interview!.answers, answers);
    ref.invalidate(documentEvidenceForYearProvider(widget.taxYear));
    if (!changed) return;
    final updated = _interview!.copyWith(answers: answers);
    final product = await ref.read(productStateProvider.future);
    await ref
        .read(productRepositoryProvider)
        .save(
          product.copyWith(
            profile: profileFromInterview(updated, product.profile),
          ),
        );
    await ref.read(taxInterviewRepositoryProvider).save(updated);
    final simulation = simulationFromInterview(updated, now: DateTime.now());
    if (updated.completed &&
        _engine.result(updated).canEstimate &&
        simulation != null) {
      await ref.read(repositoryProvider).save(simulation);
      ref.invalidate(simulationsProvider);
    }
    ref.invalidate(productStateProvider);
    ref.invalidate(taxInterviewForYearProvider(widget.taxYear));
    if (!mounted) return;
    setState(() {
      _interview = updated;
      _estimateChanged = true;
    });
  }

  Future<void> _openIrsHistory() async {
    final confirmations = await Navigator.push<List<HistoricalTaxConfirmation>>(
      context,
      MaterialPageRoute(
        builder: (_) => IrsHistoryPrefillScreen(
          targetYear: widget.taxYear,
          gateway: ref.read(dm3IrsHistoryGatewayProvider),
          repository: ref.read(historicalTaxConfirmationRepositoryProvider),
        ),
      ),
    );
    if (!mounted ||
        confirmations == null ||
        confirmations.isEmpty ||
        _interview == null) {
      return;
    }
    final answers = applyHistoricalConfirmations(
      current: _interview!.answers,
      targetYear: widget.taxYear,
      confirmations: confirmations,
    );
    final updated = _interview!.copyWith(answers: answers);
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
    ref.invalidate(historicalTaxConfirmationsForYearProvider(widget.taxYear));
    if (!mounted) return;
    setState(() {
      _interview = updated;
      _estimateChanged = true;
    });
  }

  bool _sameAnswers(Map<String, TaxAnswer> left, Map<String, TaxAnswer> right) {
    if (left.length != right.length) return false;
    for (final entry in left.entries) {
      final other = right[entry.key];
      if (other?.value != entry.value.value ||
          other?.provenance != entry.value.provenance) {
        return false;
      }
    }
    return true;
  }

  Future<void> _resetTaxYear(AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.resetTaxYearTitle(widget.taxYear)),
        content: Text(l10n.resetTaxYearBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.resetTaxYearConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final product = await ref.read(productStateProvider.future);
    final reset = resetManualFiscalYear(product, widget.taxYear);
    await ref.read(productRepositoryProvider).save(reset);
    await ref.read(taxInterviewRepositoryProvider).clear(widget.taxYear);
    await ref.read(documentEvidenceRepositoryProvider).clear(widget.taxYear);
    await ref
        .read(historicalTaxConfirmationRepositoryProvider)
        .clear(widget.taxYear);
    await AndroidTaxDocumentCaptureGateway().clearTemporary().catchError(
      (_) {},
    );
    await LocalCapturedTaxDocumentRepository().clearUnconfirmed();
    ref.invalidate(productStateProvider);
    ref.invalidate(taxInterviewForYearProvider(widget.taxYear));
    ref.invalidate(documentEvidenceForYearProvider(widget.taxYear));
    ref.invalidate(historicalTaxConfirmationsForYearProvider(widget.taxYear));
    if (!mounted) return;
    setState(() {
      _interview = _prefill(reset);
      _showResult = false;
    });
  }

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

  String _title(AppLocalizations l10n, TaxQuestion q) => switch (q.titleKey) {
    'qResidentPortugal' => l10n.qResidentPortugal(widget.taxYear),
    'qRegion' => l10n.qRegion,
    'qAge' => l10n.qAge(widget.taxYear),
    'qCivilStatus' => l10n.qCivilStatus(widget.taxYear),
    'qJointTaxation' => l10n.qJointTaxation,
    'qDependents' => l10n.qDependents,
    'qEmployment' => l10n.qEmployment(widget.taxYear),
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

  String _why(AppLocalizations l10n, TaxQuestion q) => switch (q.whyKey) {
    'whyResidentPortugal' => l10n.whyResidentPortugal,
    'whyRegion' => l10n.whyRegion,
    'whyAge' => l10n.whyAge,
    'whyCivilStatus' => l10n.whyCivilStatus,
    'whyJointTaxation' => l10n.whyJointTaxation,
    'whyDependents' => l10n.whyDependents,
    'whyEmployment' => l10n.whyEmployment,
    'whyEmploymentGross' => l10n.whyEmploymentGross,
    'whySelfEmployment' => l10n.whySelfEmployment,
    'whyPension' => l10n.whyPension,
    'whyForeignIncome' => l10n.whyForeignIncome,
    'whyRentalIncome' => l10n.whyRentalIncome,
    'whyExpensesReviewed' => l10n.whyExpensesReviewed,
    'whyWithholding' => l10n.whyWithholding,
    'whySocialSecurity' => l10n.whySocialSecurity,
    _ => l10n.whyReview,
  };

  String _optionLabel(AppLocalizations l10n, String key) => switch (key) {
    'mainlandPortugal' => l10n.mainlandPortugal,
    'madeira' => l10n.madeira,
    'azores' => l10n.azores,
    'single' => l10n.single,
    'married' => l10n.married,
    _ => l10n.deFactoUnion,
  };

  String _displayAnswer(
    AppLocalizations l10n,
    TaxQuestion question,
    Object? value,
  ) {
    if (value is bool) return value ? l10n.guidedTaxYes : l10n.guidedTaxNo;
    if (value is int && question.type == TaxQuestionType.money) {
      return TaxyFormatters.euros(context, value);
    }
    final option = question.options.where((item) => item.value == value);
    if (option.isNotEmpty) return _optionLabel(l10n, option.first.labelKey);
    return value?.toString() ?? l10n.guidedTaxNoAnswer;
  }

  int? _parseCents(String source) {
    if (!RegExp(r'^\d+(\.\d{0,2})?$').hasMatch(source)) return null;
    final parts = source.split('.');
    final euros = int.tryParse(parts.first);
    if (euros == null) return null;
    final fraction = parts.length == 1
        ? 0
        : int.parse(parts[1].padRight(2, '0'));
    return euros * 100 + fraction;
  }
}
