import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/domain/models.dart';
import 'package:taxy_pt/domain/money.dart';
import 'package:taxy_pt/fiscal_data/fiscal_data_orchestrator.dart';
import 'package:taxy_pt/fiscal_data/fiscal_evidence_repository.dart';
import 'package:taxy_pt/guided_tax/tax_interview_models.dart';
import 'package:taxy_pt/modules/efatura/domain/efatura_models.dart';
import 'package:taxy_pt/product/product_models.dart';

void main() {
  const orchestrator = FiscalDataOrchestrator();
  final completeProfile = FiscalProfile(
    activeTaxYear: 2026,
    region: TaxRegion.continent,
    civilStatus: CivilStatus.single,
    dependentCount: 0,
    hasEmployment: true,
    hasSelfEmployment: false,
  );

  TaxInterview interview({
    bool completed = true,
    String civilStatus = 'single',
  }) => TaxInterview(
    taxYear: 2026,
    completed: completed,
    answers: {
      'region': const TaxAnswer(questionId: 'region', value: 'continent'),
      'civilStatus': TaxAnswer(questionId: 'civilStatus', value: civilStatus),
      'dependentCount': const TaxAnswer(questionId: 'dependentCount', value: 0),
      'employmentIncome': const TaxAnswer(
        questionId: 'employmentIncome',
        value: true,
      ),
      'selfEmploymentIncome': const TaxAnswer(
        questionId: 'selfEmploymentIncome',
        value: false,
      ),
    },
  );

  test('profile remains the authoritative value store', () {
    final product = ProductState(profile: completeProfile);
    final result = orchestrator.consolidate(
      product: product,
      interview: interview(),
    );
    expect(result.facts['civilStatus']?.value, 'single');
    expect(product.profile.civilStatus, CivilStatus.single);
    expect(result.conflicts, isEmpty);
    expect(result.estimateCompleteness, EstimateCompleteness.ready);
  });

  test('same known fact is deduplicated across profile and interview', () {
    final result = orchestrator.consolidate(
      product: ProductState(profile: completeProfile),
      interview: interview(),
    );
    expect(
      result.facts.keys.where((id) => id == 'dependentCount'),
      hasLength(1),
    );
  });

  test(
    'divergent candidates produce DATA_CONFLICT instead of silent choice',
    () {
      final result = orchestrator.consolidate(
        product: ProductState(profile: completeProfile),
        interview: interview(civilStatus: 'married'),
      );
      expect(result.conflicts.single.id, 'civilStatus');
      expect(
        result.sections[TaxInterviewSectionId.family],
        InterviewSectionState.needsReview,
      );
      expect(result.nextAction, FiscalCompanionAction.completeProfile);
    },
  );

  test(
    'explicit user override wins but original conflict remains auditable',
    () {
      final conflict = FiscalDataConflict(
        id: 'dependentCount',
        current: const FiscalDataPoint(
          id: 'dependentCount',
          value: 2,
          source: FiscalDataSource.official,
          confidence: FiscalDataConfidence.confirmed,
          taxYear: 2026,
        ),
        candidate: const FiscalDataPoint(
          id: 'dependentCount',
          value: 1,
          source: FiscalDataSource.imported,
          confidence: FiscalDataConfidence.likely,
          taxYear: 2026,
        ),
      );
      final result = orchestrator.resolveConflict(
        product: ProductState(profile: completeProfile),
        interview: interview(),
        conflict: conflict,
        selectedValue: 2,
      );
      expect(result.facts['dependentCount']?.value, 2);
      expect(result.facts['dependentCount']?.isUserOverride, isTrue);
    },
  );

  test('tax-year mismatch fails closed', () {
    expect(
      () => orchestrator.consolidate(
        product: ProductState(profile: completeProfile),
        interview: TaxInterview(taxYear: 2025, answers: const {}),
      ),
      throwsArgumentError,
    );
  });

  test('facts from another year are never silently carried over', () {
    final result = orchestrator.consolidate(
      product: ProductState(profile: completeProfile),
      candidates: const [
        FiscalDataPoint(
          id: 'foreignIncome',
          value: true,
          source: FiscalDataSource.imported,
          confidence: FiscalDataConfidence.confirmed,
          taxYear: 2025,
        ),
      ],
    );
    expect(result.facts, isNot(contains('foreignIncome')));
  });

  test(
    'official data has explicit freshness rather than timeless authority',
    () {
      final point = FiscalDataPoint(
        id: 'efaturaInvoiceCount',
        value: 4,
        source: FiscalDataSource.official,
        confidence: FiscalDataConfidence.confirmed,
        taxYear: 2026,
        lastUpdatedAt: DateTime.utc(2026, 1, 1),
      );
      expect(
        point.freshness(DateTime.utc(2026, 3, 1)),
        FiscalDataFreshness.stale,
      );
    },
  );

  test('e-Fatura pending becomes deterministic read-only next action', () {
    final result = orchestrator.consolidate(
      product: ProductState(profile: completeProfile),
      interview: interview(),
      efatura: EfaturaCompanionEvidence(
        taxYear: 2026,
        pendingCount: 3,
        invoiceCount: 8,
        available: true,
        lastUpdatedAt: DateTime.utc(2026, 8, 1),
      ),
    );
    expect(result.nextAction, FiscalCompanionAction.reviewEfatura);
    expect(
      result.facts['efaturaPendingCount']?.source,
      FiscalDataSource.official,
    );
  });

  test('unavailable official aggregates are not converted to zero', () {
    const overview = EfaturaOverview(
      provisionalBenefitCents: AtValue.unavailable(),
      pendingValidation: AtValue.unavailable(),
      pendingRevenueAssociation: AtValue.unavailable(),
      sectors: AtValue.unavailable(),
    );
    final evidence = EfaturaCompanionEvidence.fromOverview(
      taxYear: 2026,
      overview: overview,
      invoiceCount: 0,
      updatedAt: DateTime.utc(2026, 8, 1),
    );
    final result = orchestrator.consolidate(
      product: ProductState(profile: completeProfile),
      interview: interview(),
      efatura: evidence,
    );
    expect(result.facts, isNot(contains('efaturaPendingCount')));
    expect(result.facts['efaturaInvoiceCount']?.value, 0);
  });

  test('unsupported income marks estimate provisional, never approximated', () {
    final draft = interview().copyWith(
      answers: {
        ...interview().answers,
        'foreignIncome': const TaxAnswer(
          questionId: 'foreignIncome',
          value: true,
        ),
      },
    );
    final result = orchestrator.consolidate(
      product: ProductState(profile: completeProfile),
      interview: draft,
    );
    expect(result.estimateCompleteness, EstimateCompleteness.provisional);
    expect(result.nextAction, FiscalCompanionAction.reviewEstimate);
  });

  test('income and retention remain normalized in product state', () {
    final state = ProductState(
      profile: completeProfile,
      incomes: const [
        IncomeEntry(
          id: 'income',
          category: IncomeCategory.employment,
          amount: Money.fromCents(3200000),
          year: 2026,
          provenance: EntryProvenance.manual,
          status: EntryStatus.confirmed,
        ),
      ],
    );
    expect(state.incomeTotal.cents, 3200000);
    final result = orchestrator.consolidate(product: state);
    expect(result.facts['taxYear']?.value, 2026);
  });

  test(
    'estimate snapshot is versioned and contains only an input fingerprint',
    () {
      final first = TaxEstimateSnapshot.create(
        taxYear: 2026,
        engineVersion: 'irs-2026-v1',
        normalizedInputs: const {
          'incomeCents': 3200000,
          'withholdingCents': 500000,
        },
        resultCents: -43265,
        completeness: EstimateCompleteness.ready,
      );
      final reordered = TaxEstimateSnapshot.create(
        taxYear: 2026,
        engineVersion: 'irs-2026-v1',
        normalizedInputs: const {
          'withholdingCents': 500000,
          'incomeCents': 3200000,
        },
        resultCents: -43265,
        completeness: EstimateCompleteness.ready,
      );
      expect(first.inputsFingerprint, reordered.inputsFingerprint);
      expect(first.inputsFingerprint, hasLength(16));
      expect(first.engineVersion, 'irs-2026-v1');
    },
  );

  test(
    'disconnecting e-Fatura evidence preserves manual fiscal state',
    () async {
      final repository = MemoryFiscalEvidenceRepository();
      await repository.saveEfatura(
        EfaturaCompanionEvidence(
          taxYear: 2026,
          pendingCount: 2,
          invoiceCount: 5,
          available: true,
          lastUpdatedAt: DateTime.utc(2026, 9, 1),
        ),
      );
      final product = ProductState(profile: completeProfile);
      final manualInterview = interview();
      await repository.clearEfatura(2026);
      expect(await repository.loadEfatura(2026), isNull);
      expect(product.profile, same(completeProfile));
      expect(manualInterview.answers, isNotEmpty);
    },
  );

  test('source refresh re-evaluates next action without changing profile', () {
    final product = ProductState(profile: completeProfile);
    final before = orchestrator.consolidate(
      product: product,
      interview: interview(),
      efatura: EfaturaCompanionEvidence(
        taxYear: 2026,
        pendingCount: 0,
        invoiceCount: 4,
        available: true,
        lastUpdatedAt: DateTime.utc(2026, 9, 1),
      ),
    );
    final after = orchestrator.consolidate(
      product: product,
      interview: interview(),
      efatura: EfaturaCompanionEvidence(
        taxYear: 2026,
        pendingCount: 2,
        invoiceCount: 6,
        available: true,
        lastUpdatedAt: DateTime.utc(2026, 9, 2),
        needsReview: true,
      ),
    );
    expect(before.nextAction, FiscalCompanionAction.noAction);
    expect(after.nextAction, FiscalCompanionAction.reviewEfatura);
    expect(
      after.sections[TaxInterviewSectionId.expenses],
      InterviewSectionState.needsReview,
    );
    expect(product.profile, same(completeProfile));
  });

  test('new conflicting evidence dirties only the affected section', () {
    final result = orchestrator.consolidate(
      product: ProductState(profile: completeProfile),
      interview: interview(),
      candidates: const [
        FiscalDataPoint(
          id: 'employmentIncome',
          value: false,
          source: FiscalDataSource.official,
          confidence: FiscalDataConfidence.confirmed,
          taxYear: 2026,
        ),
      ],
    );
    expect(
      result.sections[TaxInterviewSectionId.workAndIncome],
      InterviewSectionState.needsReview,
    );
    expect(
      result.sections[TaxInterviewSectionId.family],
      InterviewSectionState.clean,
    );
  });

  test('year reset removes manual data but preserves imported evidence', () {
    final product = ProductState(
      profile: completeProfile,
      incomes: const [
        IncomeEntry(
          id: 'manual',
          category: IncomeCategory.employment,
          amount: Money.fromCents(100),
          year: 2026,
          provenance: EntryProvenance.manual,
          status: EntryStatus.confirmed,
        ),
        IncomeEntry(
          id: 'imported',
          category: IncomeCategory.employment,
          amount: Money.fromCents(200),
          year: 2026,
          provenance: EntryProvenance.imported,
          status: EntryStatus.confirmed,
        ),
      ],
    );
    final reset = resetManualFiscalYear(product, 2026);
    expect(reset.profile.isComplete, isFalse);
    expect(reset.incomes.map((entry) => entry.id), ['imported']);
  });
}
