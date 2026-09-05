import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/domain/models.dart';
import 'package:taxy_pt/fiscal_data/fiscal_data_orchestrator.dart';
import 'package:taxy_pt/guided_tax/guided_tax_simulation.dart';
import 'package:taxy_pt/guided_tax/tax_interview_models.dart';
import 'package:taxy_pt/guided_tax/tax_review_models.dart';
import 'package:taxy_pt/product/product_models.dart';
import 'package:taxy_pt/tax_engine/tax_engine.dart';
import 'package:taxy_pt/tax_engine/tax_rules.dart';

void main() {
  const orchestrator = FiscalDataOrchestrator();
  const reviewService = TaxReviewService();
  final rules = TaxRuleSet.fromJsonString(
    File('assets/tax_rules/2026.json').readAsStringSync(),
  );

  TaxInterview employee({
    bool withholding = true,
    bool selfEmployment = false,
    bool foreignIncome = false,
    bool completed = true,
    Map<String, TaxConflictResolution> resolutions = const {},
  }) => TaxInterview(
    taxYear: 2026,
    completed: completed,
    conflictResolutions: resolutions,
    answers: {
      'residentPortugal': const TaxAnswer(
        questionId: 'residentPortugal',
        value: true,
      ),
      'region': const TaxAnswer(questionId: 'region', value: 'continent'),
      'age': const TaxAnswer(questionId: 'age', value: 35),
      'civilStatus': const TaxAnswer(
        questionId: 'civilStatus',
        value: 'single',
      ),
      'dependentCount': const TaxAnswer(questionId: 'dependentCount', value: 0),
      'employmentIncome': const TaxAnswer(
        questionId: 'employmentIncome',
        value: true,
      ),
      'employmentGrossCents': const TaxAnswer(
        questionId: 'employmentGrossCents',
        value: 3200000,
      ),
      'selfEmploymentIncome': TaxAnswer(
        questionId: 'selfEmploymentIncome',
        value: selfEmployment,
      ),
      'pensionIncome': const TaxAnswer(
        questionId: 'pensionIncome',
        value: false,
      ),
      'foreignIncome': TaxAnswer(
        questionId: 'foreignIncome',
        value: foreignIncome,
      ),
      'rentalIncome': const TaxAnswer(questionId: 'rentalIncome', value: false),
      'expensesReviewed': const TaxAnswer(
        questionId: 'expensesReviewed',
        value: true,
      ),
      if (withholding)
        'withholdingCents': const TaxAnswer(
          questionId: 'withholdingCents',
          value: 420000,
        ),
      'socialSecurityCents': const TaxAnswer(
        questionId: 'socialSecurityCents',
        value: 352000,
      ),
      'reviewConfirmed': const TaxAnswer(
        questionId: 'reviewConfirmed',
        value: true,
      ),
    },
  );

  ProductState product({bool selfEmployment = false}) => ProductState(
    profile: FiscalProfile(
      activeTaxYear: 2026,
      region: TaxRegion.continent,
      civilStatus: CivilStatus.single,
      dependentCount: 0,
      hasEmployment: true,
      hasSelfEmployment: selfEmployment,
    ),
  );

  ProductState productFor(TaxInterview interview) => ProductState(
    profile: FiscalProfile(
      activeTaxYear: interview.taxYear,
      region: TaxRegion.continent,
      civilStatus: switch (interview.answers['civilStatus']?.value) {
        'married' => CivilStatus.married,
        'deFacto' => CivilStatus.deFacto,
        _ => CivilStatus.single,
      },
      dependentCount: interview.answers['dependentCount']?.value as int? ?? 0,
      hasEmployment:
          interview.answers['employmentIncome']?.value as bool? ?? false,
      hasSelfEmployment:
          interview.answers['selfEmploymentIncome']?.value as bool? ?? false,
    ),
  );

  TaxReviewResult review(
    TaxInterview interview, {
    Iterable<FiscalDataPoint> candidates = const [],
    EfaturaCompanionEvidence? efatura,
  }) {
    final orchestration = orchestrator.consolidate(
      product: productFor(interview),
      interview: interview,
      candidates: candidates,
      efatura: efatura,
    );
    final simulation = simulationFromInterview(
      interview,
      now: DateTime.utc(2026, 9, 1),
    );
    final tax = simulation == null
        ? null
        : TaxEngine(rules).calculate(simulation);
    return reviewService.build(
      interview: interview,
      orchestration: orchestration,
      taxResult: tax,
    );
  }

  test('complete employee is ready with explainable complete estimate', () {
    final result = review(employee());
    expect(result.completeness, TaxReviewCompleteness.ready);
    expect(
      result.estimatePresentation,
      TaxEstimatePresentation.showCompleteEstimate,
    );
    expect(result.explainability?.lines, hasLength(5));
    expect(
      result.inclusion['employmentGrossCents'],
      TaxCalculationInclusion.included,
    );
  });

  test('missing withholding is incomplete and becomes primary action', () {
    final result = review(employee(withholding: false));
    expect(result.completeness, TaxReviewCompleteness.incomplete);
    expect(result.estimatePresentation, TaxEstimatePresentation.hideEstimate);
    expect(result.primaryAction, TaxReviewNextAction.addRequiredData);
    expect(
      result.missing.any((item) => item.factId == 'withholdingCents'),
      isTrue,
    );
  });

  test('document conflict needs review and a changed pair reopens it', () {
    final interview = employee();
    const firstDocument = FiscalDataPoint(
      id: 'withholdingCents',
      value: 430000,
      source: FiscalDataSource.imported,
      confidence: FiscalDataConfidence.confirmed,
      taxYear: 2026,
    );
    final first = orchestrator.consolidate(
      product: product(),
      interview: interview,
      candidates: const [firstDocument],
    );
    expect(first.conflicts, hasLength(1));
    final resolved = orchestrator.applyConflictResolution(
      interview: interview,
      conflict: first.conflicts.single,
      selected: firstDocument,
      resolvedAt: DateTime.utc(2026, 9, 1),
    );
    expect(
      resolved.answers['withholdingCents']?.provenance,
      TaxFactProvenance.imported,
    );
    expect(
      orchestrator
          .consolidate(
            product: product(),
            interview: resolved,
            candidates: const [firstDocument],
          )
          .conflicts,
      isEmpty,
    );
    const changedDocument = FiscalDataPoint(
      id: 'withholdingCents',
      value: 440000,
      source: FiscalDataSource.imported,
      confidence: FiscalDataConfidence.confirmed,
      taxYear: 2026,
    );
    expect(
      orchestrator
          .consolidate(
            product: product(),
            interview: resolved,
            candidates: const [changedDocument],
          )
          .conflicts,
      isNotEmpty,
    );
  });

  test(
    'unresolved conflict is the primary action and only a partial estimate',
    () {
      final result = review(
        employee(),
        candidates: const [
          FiscalDataPoint(
            id: 'withholdingCents',
            value: 430000,
            source: FiscalDataSource.imported,
            confidence: FiscalDataConfidence.confirmed,
            taxYear: 2026,
          ),
        ],
      );
      expect(result.completeness, TaxReviewCompleteness.needsReview);
      expect(
        result.estimatePresentation,
        TaxEstimatePresentation.showPartialEstimate,
      );
      expect(result.primaryAction, TaxReviewNextAction.resolveConflict);
    },
  );

  test('unsupported self-employment hides a falsely complete estimate', () {
    final result = review(employee(selfEmployment: true));
    expect(result.completeness, TaxReviewCompleteness.unsupportedSituation);
    expect(result.estimatePresentation, TaxEstimatePresentation.hideEstimate);
    expect(result.unsupportedFactIds, contains('selfEmploymentIncome'));
  });

  test('foreign income is identified but excluded from calculation', () {
    final result = review(employee(foreignIncome: true));
    expect(result.completeness, TaxReviewCompleteness.unsupportedSituation);
    expect(
      result.inclusion['foreignIncome'],
      TaxCalculationInclusion.excludedUnsupported,
    );
  });

  test('e-Fatura pending does not block a supported estimate', () {
    final result = review(
      employee(),
      efatura: EfaturaCompanionEvidence(
        taxYear: 2026,
        pendingCount: 7,
        invoiceCount: 20,
        available: true,
        lastUpdatedAt: DateTime.utc(2026, 9, 1),
      ),
    );
    expect(result.completeness, TaxReviewCompleteness.ready);
    expect(result.primaryAction, TaxReviewNextAction.reviewEfatura);
  });

  test(
    'married with dependants stays fail-closed when no engine result exists',
    () {
      final base = employee();
      final interview = base.copyWith(
        answers: {
          ...base.answers,
          'civilStatus': const TaxAnswer(
            questionId: 'civilStatus',
            value: 'married',
          ),
          'jointTaxation': const TaxAnswer(
            questionId: 'jointTaxation',
            value: false,
          ),
          'dependentCount': const TaxAnswer(
            questionId: 'dependentCount',
            value: 2,
          ),
        },
      );
      final result = review(interview);
      expect(result.completeness, TaxReviewCompleteness.incomplete);
      expect(result.estimatePresentation, TaxEstimatePresentation.hideEstimate);
    },
  );

  test('no income data identifies required information without an amount', () {
    final base = employee();
    final answers = Map<String, TaxAnswer>.from(base.answers)
      ..remove('employmentGrossCents')
      ..remove('withholdingCents')
      ..remove('socialSecurityCents');
    final result = review(base.copyWith(answers: answers));
    expect(result.completeness, TaxReviewCompleteness.incomplete);
    expect(result.estimatePresentation, TaxEstimatePresentation.hideEstimate);
    expect(result.primaryAction, TaxReviewNextAction.addRequiredData);
  });

  test('conflict resolutions serialize and remain isolated by tax year', () {
    final value = employee(
      resolutions: {
        'withholdingCents': TaxConflictResolution(
          factId: 'withholdingCents',
          selectedValue: 420000,
          competingValue: 430000,
          selectedProvenance: TaxFactProvenance.userEntered,
          resolvedAt: DateTime.utc(2026, 9, 1),
        ),
      },
    );
    final restored = TaxInterview.fromJson(value.toJson());
    expect(restored.taxYear, 2026);
    expect(restored.conflictResolutions, hasLength(1));
    expect(
      restored.conflictResolutions['withholdingCents']?.matches(430000, 420000),
      isTrue,
    );
  });
}
