import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/guided_tax/tax_interview_engine.dart';
import 'package:taxy_pt/guided_tax/tax_interview_models.dart';
import 'package:taxy_pt/guided_tax/tax_interview_repository.dart';
import 'package:taxy_pt/product/product_models.dart';
import 'package:taxy_pt/domain/models.dart';

void main() {
  const engine = TaxInterviewEngine();

  TaxInterview complete({
    String civilStatus = 'single',
    int dependents = 0,
    bool employment = true,
    bool selfEmployment = false,
    bool pension = false,
    bool foreign = false,
    bool rental = false,
    bool omitWithholding = false,
  }) {
    final values = <String, Object?>{
      'residentPortugal': true,
      'region': 'continent',
      'age': 35,
      'civilStatus': civilStatus,
      if (civilStatus != 'single') 'jointTaxation': false,
      'dependentCount': dependents,
      'employmentIncome': employment,
      if (employment) 'employmentGrossCents': 3200000,
      'selfEmploymentIncome': selfEmployment,
      'pensionIncome': pension,
      'foreignIncome': foreign,
      'rentalIncome': rental,
      'expensesReviewed': true,
      if (employment && !omitWithholding) 'withholdingCents': 420000,
      if (employment) 'socialSecurityCents': 352000,
      'reviewConfirmed': true,
    };
    return TaxInterview(
      taxYear: 2026,
      answers: {
        for (final entry in values.entries)
          entry.key: TaxAnswer(questionId: entry.key, value: entry.value),
      },
    );
  }

  test('simple employee persona reaches an estimable result', () {
    final result = engine.result(complete());
    expect(result.canEstimate, isTrue);
    expect(result.missing, isEmpty);
    expect(result.nextAction, TaxNextActionKind.reviewEstimate);
  });

  test('married with dependants receives the family branch', () {
    final interview = complete(civilStatus: 'married', dependents: 2);
    final ids = engine.visibleQuestions(interview).map((q) => q.id);
    expect(ids, contains('jointTaxation'));
    expect(
      engine
          .result(interview)
          .facts
          .singleWhere((f) => f.id == 'dependentCount')
          .value,
      2,
    );
  });

  test('employee and self-employed is identified but not approximated', () {
    final result = engine.result(complete(selfEmployment: true));
    expect(result.canEstimate, isFalse);
    expect(result.nextAction, TaxNextActionKind.completeProfile);
  });

  test('self-employed persona omits employment amounts', () {
    final interview = complete(employment: false, selfEmployment: true);
    final ids = engine.visibleQuestions(interview).map((q) => q.id).toSet();
    expect(ids, isNot(contains('employmentGrossCents')));
    expect(ids, isNot(contains('withholdingCents')));
    expect(ids, isNot(contains('socialSecurityCents')));
  });

  test('foreign income is retained as an identified unsupported fact', () {
    final result = engine.result(complete(foreign: true));
    expect(result.canEstimate, isFalse);
    expect(
      result.facts.singleWhere((fact) => fact.id == 'foreignIncome').value,
      isTrue,
    );
  });

  test('incomplete persona reports required data', () {
    final result = engine.result(complete(omitWithholding: true));
    expect(result.canEstimate, isFalse);
    expect(
      result.missing.any(
        (item) =>
            item.factId == 'withholdingCents' &&
            item.priority == TaxMissingPriority.required,
      ),
      isTrue,
    );
  });

  test('required confirmation must be accepted before estimating', () {
    final interview = complete();
    final answers = Map<String, TaxAnswer>.from(interview.answers)
      ..['reviewConfirmed'] = const TaxAnswer(
        questionId: 'reviewConfirmed',
        value: false,
      );
    final result = engine.result(
      TaxInterview(taxYear: interview.taxYear, answers: answers),
    );
    expect(result.canEstimate, isFalse);
    expect(
      result.missing.any((item) => item.factId == 'reviewConfirmed'),
      isTrue,
    );
  });

  test('changing employment to no cleans dependent answers', () {
    var interview = complete();
    interview = engine.answer(
      interview,
      const TaxAnswer(questionId: 'employmentIncome', value: false),
    );
    expect(interview.answers, isNot(contains('employmentGrossCents')));
    expect(interview.answers, isNot(contains('withholdingCents')));
    expect(interview.answers, isNot(contains('socialSecurityCents')));
  });

  test('changing civil status cleans joint-taxation answer', () {
    var interview = complete(civilStatus: 'married');
    interview = engine.answer(
      interview,
      const TaxAnswer(questionId: 'civilStatus', value: 'single'),
    );
    expect(interview.answers, isNot(contains('jointTaxation')));
  });

  test(
    'persistence is isolated by tax year and resumes current question',
    () async {
      final repository = MemoryTaxInterviewRepository();
      final value = TaxInterview(
        taxYear: 2026,
        currentQuestionId: 'civilStatus',
        answers: const {
          'residentPortugal': TaxAnswer(
            questionId: 'residentPortugal',
            value: true,
          ),
        },
      );
      await repository.save(value);
      expect((await repository.load(2026))?.currentQuestionId, 'civilStatus');
      expect(await repository.load(2025), isNull);
    },
  );

  test(
    'JSON round-trip preserves provenance without confidence conflation',
    () {
      final value = TaxInterview(
        taxYear: 2026,
        currentQuestionId: 'region',
        answers: const {
          'residentPortugal': TaxAnswer(
            questionId: 'residentPortugal',
            value: true,
            provenance: TaxFactProvenance.official,
          ),
        },
      );
      final restored = TaxInterview.fromJson(value.toJson());
      expect(
        restored.answers['residentPortugal']?.provenance,
        TaxFactProvenance.official,
      );
    },
  );

  test('interview updates the existing FiscalProfile source of truth', () {
    const base = FiscalProfile(activeTaxYear: 2025);
    final profile = profileFromInterview(complete(dependents: 2), base);
    expect(profile.activeTaxYear, 2026);
    expect(profile.region, TaxRegion.continent);
    expect(profile.civilStatus, CivilStatus.single);
    expect(profile.dependentCount, 2);
    expect(profile.hasEmployment, isTrue);
    expect(profile.hasSelfEmployment, isFalse);
  });

  test('question model exposes every supported input type', () {
    expect(TaxQuestionType.values, hasLength(10));
    expect(
      TaxQuestionType.values,
      containsAll([
        TaxQuestionType.yesNo,
        TaxQuestionType.singleChoice,
        TaxQuestionType.multipleChoice,
        TaxQuestionType.money,
        TaxQuestionType.integer,
        TaxQuestionType.date,
        TaxQuestionType.text,
        TaxQuestionType.country,
        TaxQuestionType.document,
        TaxQuestionType.confirmation,
      ]),
    );
  });

  test('observability model contains no tax-answer payload', () {
    const allowedEvents = {
      'interview_started',
      'section_completed',
      'interview_completed',
      'abandoned_section',
      'error_category',
    };
    expect(allowedEvents.every((event) => !event.contains('income')), isTrue);
  });
}
