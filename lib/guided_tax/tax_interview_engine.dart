import 'tax_interview_models.dart';

final class TaxInterviewEngine {
  const TaxInterviewEngine();

  static const sections = <TaxInterviewSection>[
    TaxInterviewSection(
      id: TaxInterviewSectionId.aboutYou,
      titleKey: 'aboutYou',
    ),
    TaxInterviewSection(id: TaxInterviewSectionId.family, titleKey: 'family'),
    TaxInterviewSection(
      id: TaxInterviewSectionId.workAndIncome,
      titleKey: 'workAndIncome',
    ),
    TaxInterviewSection(
      id: TaxInterviewSectionId.otherIncome,
      titleKey: 'otherIncome',
    ),
    TaxInterviewSection(
      id: TaxInterviewSectionId.expenses,
      titleKey: 'expenses',
    ),
    TaxInterviewSection(
      id: TaxInterviewSectionId.withholdingAndPayments,
      titleKey: 'withholdingAndPayments',
    ),
    TaxInterviewSection(id: TaxInterviewSectionId.review, titleKey: 'review'),
  ];

  static const questions = <TaxQuestion>[
    TaxQuestion(
      id: 'residentPortugal',
      section: TaxInterviewSectionId.aboutYou,
      type: TaxQuestionType.yesNo,
      titleKey: 'qResidentPortugal',
      whyKey: 'whyResidentPortugal',
    ),
    TaxQuestion(
      id: 'region',
      section: TaxInterviewSectionId.aboutYou,
      type: TaxQuestionType.singleChoice,
      titleKey: 'qRegion',
      whyKey: 'whyRegion',
      options: [
        TaxQuestionOption('continent', 'mainlandPortugal'),
        TaxQuestionOption('madeira', 'madeira'),
        TaxQuestionOption('azores', 'azores'),
      ],
    ),
    TaxQuestion(
      id: 'age',
      section: TaxInterviewSectionId.aboutYou,
      type: TaxQuestionType.integer,
      titleKey: 'qAge',
      whyKey: 'whyAge',
    ),
    TaxQuestion(
      id: 'civilStatus',
      section: TaxInterviewSectionId.family,
      type: TaxQuestionType.singleChoice,
      titleKey: 'qCivilStatus',
      whyKey: 'whyCivilStatus',
      options: [
        TaxQuestionOption('single', 'single'),
        TaxQuestionOption('married', 'married'),
        TaxQuestionOption('deFacto', 'deFactoUnion'),
      ],
    ),
    TaxQuestion(
      id: 'jointTaxation',
      section: TaxInterviewSectionId.family,
      type: TaxQuestionType.yesNo,
      titleKey: 'qJointTaxation',
      whyKey: 'whyJointTaxation',
    ),
    TaxQuestion(
      id: 'dependentCount',
      section: TaxInterviewSectionId.family,
      type: TaxQuestionType.integer,
      titleKey: 'qDependents',
      whyKey: 'whyDependents',
    ),
    TaxQuestion(
      id: 'employmentIncome',
      section: TaxInterviewSectionId.workAndIncome,
      type: TaxQuestionType.yesNo,
      titleKey: 'qEmployment',
      whyKey: 'whyEmployment',
    ),
    TaxQuestion(
      id: 'employmentGrossCents',
      section: TaxInterviewSectionId.workAndIncome,
      type: TaxQuestionType.money,
      titleKey: 'qEmploymentGross',
      whyKey: 'whyEmploymentGross',
    ),
    TaxQuestion(
      id: 'selfEmploymentIncome',
      section: TaxInterviewSectionId.workAndIncome,
      type: TaxQuestionType.yesNo,
      titleKey: 'qSelfEmployment',
      whyKey: 'whySelfEmployment',
    ),
    TaxQuestion(
      id: 'pensionIncome',
      section: TaxInterviewSectionId.otherIncome,
      type: TaxQuestionType.yesNo,
      titleKey: 'qPension',
      whyKey: 'whyPension',
    ),
    TaxQuestion(
      id: 'foreignIncome',
      section: TaxInterviewSectionId.otherIncome,
      type: TaxQuestionType.yesNo,
      titleKey: 'qForeignIncome',
      whyKey: 'whyForeignIncome',
    ),
    TaxQuestion(
      id: 'rentalIncome',
      section: TaxInterviewSectionId.otherIncome,
      type: TaxQuestionType.yesNo,
      titleKey: 'qRentalIncome',
      whyKey: 'whyRentalIncome',
    ),
    TaxQuestion(
      id: 'expensesReviewed',
      section: TaxInterviewSectionId.expenses,
      type: TaxQuestionType.confirmation,
      titleKey: 'qExpensesReviewed',
      whyKey: 'whyExpensesReviewed',
      required: false,
    ),
    TaxQuestion(
      id: 'withholdingCents',
      section: TaxInterviewSectionId.withholdingAndPayments,
      type: TaxQuestionType.money,
      titleKey: 'qWithholding',
      whyKey: 'whyWithholding',
    ),
    TaxQuestion(
      id: 'socialSecurityCents',
      section: TaxInterviewSectionId.withholdingAndPayments,
      type: TaxQuestionType.money,
      titleKey: 'qSocialSecurity',
      whyKey: 'whySocialSecurity',
    ),
    TaxQuestion(
      id: 'reviewConfirmed',
      section: TaxInterviewSectionId.review,
      type: TaxQuestionType.confirmation,
      titleKey: 'qReview',
      whyKey: 'whyReview',
    ),
  ];

  List<TaxQuestion> visibleQuestions(TaxInterview interview) => questions
      .where((question) => _visible(question.id, interview.answers))
      .toList(growable: false);

  bool _visible(String id, Map<String, TaxAnswer> answers) {
    Object? value(String questionId) => answers[questionId]?.value;
    return switch (id) {
      'region' => value('residentPortugal') == true,
      'jointTaxation' =>
        value('civilStatus') == 'married' || value('civilStatus') == 'deFacto',
      'employmentGrossCents' => value('employmentIncome') == true,
      'withholdingCents' ||
      'socialSecurityCents' => value('employmentIncome') == true,
      _ => true,
    };
  }

  TaxInterview answer(TaxInterview interview, TaxAnswer answer) {
    final updated = {...interview.answers, answer.questionId: answer};
    final visible = questions
        .where((question) => _visible(question.id, updated))
        .map((question) => question.id)
        .toSet();
    updated.removeWhere((id, _) => !visible.contains(id));
    final draft = TaxInterview(taxYear: interview.taxYear, answers: updated);
    final list = visibleQuestions(draft);
    final current = list.indexWhere((q) => q.id == answer.questionId);
    return draft.copyWith(
      currentQuestionId: current >= 0 && current + 1 < list.length
          ? list[current + 1].id
          : list.last.id,
    );
  }

  TaxInterviewProgress progress(TaxInterview interview) {
    final visible = visibleQuestions(interview);
    final current = visible.firstWhere(
      (q) => q.id == interview.currentQuestionId,
      orElse: () => visible.first,
    );
    final completed = <TaxInterviewSectionId>{};
    for (final section in TaxInterviewSectionId.values) {
      final items = visible.where((q) => q.section == section).toList();
      if (items.isNotEmpty &&
          items.every((q) => interview.answers.containsKey(q.id))) {
        completed.add(section);
      }
    }
    return TaxInterviewProgress(
      completedSections: completed,
      currentSection: current.section,
      visibleQuestionCount: visible.length,
      answeredQuestionCount: visible
          .where((q) => interview.answers.containsKey(q.id))
          .length,
    );
  }

  TaxInterviewResult result(TaxInterview interview) {
    final facts = interview.answers.values
        .map(
          (answer) => TaxFact(
            id: answer.questionId,
            value: answer.value,
            taxYear: interview.taxYear,
            provenance: answer.provenance,
            confidence: TaxFactConfidence.confirmed,
          ),
        )
        .toList(growable: false);
    final missing = <TaxMissingData>[];
    for (final question in visibleQuestions(interview)) {
      final answer = interview.answers[question.id];
      final confirmationMissing =
          question.required &&
          question.type == TaxQuestionType.confirmation &&
          answer?.value != true;
      if (answer == null || confirmationMissing) {
        missing.add(
          TaxMissingData(
            question.id,
            question.required
                ? TaxMissingPriority.required
                : TaxMissingPriority.recommended,
          ),
        );
      }
    }
    final unsupported = [
      'selfEmploymentIncome',
      'pensionIncome',
      'foreignIncome',
      'rentalIncome',
    ].any((id) => interview.answers[id]?.value == true);
    final canEstimate =
        missing.every((m) => m.priority != TaxMissingPriority.required) &&
        interview.answers['employmentIncome']?.value == true &&
        interview.answers['civilStatus']?.value == 'single' &&
        !unsupported;
    return TaxInterviewResult(
      facts: facts,
      missing: missing,
      canEstimate: canEstimate,
      nextAction: missing.isNotEmpty
          ? TaxNextActionKind.continueInterview
          : unsupported
          ? TaxNextActionKind.completeProfile
          : TaxNextActionKind.reviewEstimate,
    );
  }
}
