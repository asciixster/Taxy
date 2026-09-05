import '../product/product_models.dart';
import '../domain/models.dart';

enum TaxQuestionType {
  yesNo,
  singleChoice,
  multipleChoice,
  money,
  integer,
  date,
  text,
  country,
  document,
  confirmation,
}

enum TaxInterviewSectionId {
  aboutYou,
  family,
  workAndIncome,
  otherIncome,
  expenses,
  withholdingAndPayments,
  review,
}

enum TaxFactProvenance { userEntered, official, imported, calculated, inferred }

enum TaxFactConfidence { confirmed, likely, incomplete, unknown }

enum TaxMissingPriority { required, recommended, optional }

enum TaxNextActionKind {
  completeProfile,
  continueInterview,
  addIncome,
  reviewExpenses,
  reviewEfatura,
  reviewEstimate,
  noAction,
}

final class TaxQuestionOption {
  const TaxQuestionOption(this.value, this.labelKey);
  final Object value;
  final String labelKey;
}

final class TaxQuestion {
  const TaxQuestion({
    required this.id,
    required this.section,
    required this.type,
    required this.titleKey,
    required this.whyKey,
    this.options = const [],
    this.required = true,
  });

  final String id;
  final TaxInterviewSectionId section;
  final TaxQuestionType type;
  final String titleKey;
  final String whyKey;
  final List<TaxQuestionOption> options;
  final bool required;
}

final class TaxInterviewSection {
  const TaxInterviewSection({required this.id, required this.titleKey});
  final TaxInterviewSectionId id;
  final String titleKey;
}

final class TaxAnswer {
  const TaxAnswer({
    required this.questionId,
    required this.value,
    this.provenance = TaxFactProvenance.userEntered,
  });

  final String questionId;
  final Object? value;
  final TaxFactProvenance provenance;

  Map<String, Object?> toJson() => {
    'questionId': questionId,
    'value': value,
    'provenance': provenance.name,
  };

  factory TaxAnswer.fromJson(Map<String, Object?> json) => TaxAnswer(
    questionId: json['questionId'] as String,
    value: json['value'],
    provenance: TaxFactProvenance.values.byName(
      json['provenance'] as String? ?? TaxFactProvenance.userEntered.name,
    ),
  );
}

final class TaxFact {
  const TaxFact({
    required this.id,
    required this.value,
    required this.taxYear,
    required this.provenance,
    required this.confidence,
  });

  final String id;
  final Object? value;
  final int taxYear;
  final TaxFactProvenance provenance;
  final TaxFactConfidence confidence;
}

final class TaxMissingData {
  const TaxMissingData(this.factId, this.priority);
  final String factId;
  final TaxMissingPriority priority;
}

final class TaxInterviewProgress {
  const TaxInterviewProgress({
    required this.completedSections,
    required this.currentSection,
    required this.visibleQuestionCount,
    required this.answeredQuestionCount,
  });

  final Set<TaxInterviewSectionId> completedSections;
  final TaxInterviewSectionId currentSection;
  final int visibleQuestionCount;
  final int answeredQuestionCount;
}

final class TaxInterviewResult {
  const TaxInterviewResult({
    required this.facts,
    required this.missing,
    required this.nextAction,
    required this.canEstimate,
  });

  final List<TaxFact> facts;
  final List<TaxMissingData> missing;
  final TaxNextActionKind nextAction;
  final bool canEstimate;
}

final class TaxInterview {
  const TaxInterview({
    required this.taxYear,
    required this.answers,
    this.currentQuestionId,
    this.completed = false,
  });

  final int taxYear;
  final Map<String, TaxAnswer> answers;
  final String? currentQuestionId;
  final bool completed;

  TaxInterview copyWith({
    Map<String, TaxAnswer>? answers,
    String? currentQuestionId,
    bool? completed,
  }) => TaxInterview(
    taxYear: taxYear,
    answers: answers ?? this.answers,
    currentQuestionId: currentQuestionId ?? this.currentQuestionId,
    completed: completed ?? this.completed,
  );

  Map<String, Object?> toJson() => {
    'schemaVersion': 1,
    'taxYear': taxYear,
    'answers': answers.values.map((answer) => answer.toJson()).toList(),
    'currentQuestionId': currentQuestionId,
    'completed': completed,
  };

  factory TaxInterview.fromJson(Map<String, Object?> json) {
    if (json['schemaVersion'] != 1) throw const FormatException('schema');
    final answers = (json['answers'] as List? ?? const [])
        .map((value) => TaxAnswer.fromJson((value as Map).cast()))
        .toList();
    return TaxInterview(
      taxYear: json['taxYear'] as int,
      answers: {for (final answer in answers) answer.questionId: answer},
      currentQuestionId: json['currentQuestionId'] as String?,
      completed: json['completed'] as bool? ?? false,
    );
  }
}

final class TaxRule {
  const TaxRule({required this.questionId, required this.isVisible});
  final String questionId;
  final bool Function(Map<String, TaxAnswer> answers) isVisible;
}

final class DocumentInput {
  const DocumentInput({
    required this.type,
    required this.displayName,
    this.localReference,
    this.confirmed = false,
  });
  final String type;
  final String displayName;
  final String? localReference;
  final bool confirmed;
}

final class TaxEvent {
  const TaxEvent({required this.id, required this.taxYear, required this.kind});
  final String id;
  final int taxYear;
  final String kind;
}

final class TaxDeadline {
  const TaxDeadline({
    required this.id,
    required this.date,
    required this.source,
  });
  final String id;
  final DateTime date;
  final String source;
}

FiscalProfile profileFromInterview(TaxInterview interview, FiscalProfile base) {
  T? value<T>(String id) => interview.answers[id]?.value is T
      ? interview.answers[id]!.value as T
      : null;
  return base.copyWith(
    activeTaxYear: interview.taxYear,
    region: switch (value<String>('region')) {
      'madeira' => TaxRegion.madeira,
      'azores' => TaxRegion.azores,
      'continent' => TaxRegion.continent,
      _ => base.region,
    },
    civilStatus: switch (value<String>('civilStatus')) {
      'married' => CivilStatus.married,
      'deFacto' => CivilStatus.deFacto,
      'single' => CivilStatus.single,
      _ => base.civilStatus,
    },
    dependentCount: value<int>('dependentCount') ?? base.dependentCount,
    hasEmployment: value<bool>('employmentIncome') ?? base.hasEmployment,
    hasSelfEmployment:
        value<bool>('selfEmploymentIncome') ?? base.hasSelfEmployment,
  );
}
