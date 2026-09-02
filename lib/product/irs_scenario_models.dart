import '../domain/money.dart';
import '../domain/models.dart';

/// Explicit hypothetical values layered over an existing simulation.
/// Null means "use the confirmed base value".
final class ScenarioOverrides {
  const ScenarioOverrides({
    this.grossIncomeCents,
    this.withholdingCents,
    this.generalExpensesCents,
    this.healthExpensesCents,
    this.educationExpensesCents,
    this.rentExpensesCents,
    this.pprCents,
    this.civilStatus,
  });

  final int? grossIncomeCents;
  final int? withholdingCents;
  final int? generalExpensesCents;
  final int? healthExpensesCents;
  final int? educationExpensesCents;
  final int? rentExpensesCents;
  final int? pprCents;
  final CivilStatus? civilStatus;

  bool get isEmpty =>
      grossIncomeCents == null &&
      withholdingCents == null &&
      generalExpensesCents == null &&
      healthExpensesCents == null &&
      educationExpensesCents == null &&
      rentExpensesCents == null &&
      pprCents == null &&
      civilStatus == null;

  TaxSimulation applyTo(TaxSimulation base) => base.copyWith(
    profile: civilStatus == null
        ? base.profile
        : base.profile.copyWith(civilStatus: civilStatus),
    income: base.income.copyWith(
      gross: grossIncomeCents == null
          ? base.income.gross
          : Money.fromCents(grossIncomeCents!),
      withholding: withholdingCents == null
          ? base.income.withholding
          : Money.fromCents(withholdingCents!),
    ),
    deductions: base.deductions.copyWith(
      general: generalExpensesCents == null
          ? base.deductions.general
          : Money.fromCents(generalExpensesCents!),
      health: healthExpensesCents == null
          ? base.deductions.health
          : Money.fromCents(healthExpensesCents!),
      education: educationExpensesCents == null
          ? base.deductions.education
          : Money.fromCents(educationExpensesCents!),
      rent: rentExpensesCents == null
          ? base.deductions.rent
          : Money.fromCents(rentExpensesCents!),
      ppr: pprCents == null ? base.deductions.ppr : Money.fromCents(pprCents!),
    ),
  );

  List<ScenarioChange> changesFrom(TaxSimulation base) => [
    if (grossIncomeCents != null && grossIncomeCents != base.income.gross.cents)
      ScenarioChange('grossIncome', base.income.gross.cents, grossIncomeCents!),
    if (withholdingCents != null &&
        withholdingCents != base.income.withholding.cents)
      ScenarioChange(
        'withholding',
        base.income.withholding.cents,
        withholdingCents!,
      ),
    if (generalExpensesCents != null &&
        generalExpensesCents != base.deductions.general.cents)
      ScenarioChange(
        'generalExpenses',
        base.deductions.general.cents,
        generalExpensesCents!,
      ),
    if (healthExpensesCents != null &&
        healthExpensesCents != base.deductions.health.cents)
      ScenarioChange(
        'healthExpenses',
        base.deductions.health.cents,
        healthExpensesCents!,
      ),
    if (educationExpensesCents != null &&
        educationExpensesCents != base.deductions.education.cents)
      ScenarioChange(
        'educationExpenses',
        base.deductions.education.cents,
        educationExpensesCents!,
      ),
    if (rentExpensesCents != null &&
        rentExpensesCents != base.deductions.rent.cents)
      ScenarioChange(
        'rentExpenses',
        base.deductions.rent.cents,
        rentExpensesCents!,
      ),
    if (pprCents != null && pprCents != base.deductions.ppr.cents)
      ScenarioChange('ppr', base.deductions.ppr.cents, pprCents!),
  ];

  Map<String, Object?> toJson() => {
    'grossIncomeCents': grossIncomeCents,
    'withholdingCents': withholdingCents,
    'generalExpensesCents': generalExpensesCents,
    'healthExpensesCents': healthExpensesCents,
    'educationExpensesCents': educationExpensesCents,
    'rentExpensesCents': rentExpensesCents,
    'pprCents': pprCents,
    'civilStatus': civilStatus?.name,
  };

  factory ScenarioOverrides.fromJson(Map<String, Object?> json) =>
      ScenarioOverrides(
        grossIncomeCents: json['grossIncomeCents'] as int?,
        withholdingCents: json['withholdingCents'] as int?,
        generalExpensesCents: json['generalExpensesCents'] as int?,
        healthExpensesCents: json['healthExpensesCents'] as int?,
        educationExpensesCents: json['educationExpensesCents'] as int?,
        rentExpensesCents: json['rentExpensesCents'] as int?,
        pprCents: json['pprCents'] as int?,
        civilStatus: json['civilStatus'] == null
            ? null
            : CivilStatus.values.byName(json['civilStatus'] as String),
      );
}

final class ScenarioChange {
  const ScenarioChange(this.field, this.baseCents, this.scenarioCents);
  final String field;
  final int baseCents;
  final int scenarioCents;
  int get differenceCents => scenarioCents - baseCents;
}

/// Immutable historical estimate. It is never silently recalculated.
final class IrsSnapshot {
  const IrsSnapshot({
    required this.id,
    required this.label,
    required this.createdAt,
    required this.taxYear,
    required this.calculationModelVersion,
    required this.inputSchemaVersion,
    required this.simulation,
    required this.balanceCents,
    required this.grossIncomeCents,
    required this.withholdingCents,
    required this.taxCreditsCents,
  });

  final String id;
  final String label;
  final DateTime createdAt;
  final int taxYear;
  final String calculationModelVersion;
  final int inputSchemaVersion;
  final TaxSimulation simulation;
  final int balanceCents;
  final int grossIncomeCents;
  final int withholdingCents;
  final int taxCreditsCents;

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'taxYear': taxYear,
    'calculationModelVersion': calculationModelVersion,
    'inputSchemaVersion': inputSchemaVersion,
    'simulation': simulation.toJson(),
    'balanceCents': balanceCents,
    'grossIncomeCents': grossIncomeCents,
    'withholdingCents': withholdingCents,
    'taxCreditsCents': taxCreditsCents,
  };

  factory IrsSnapshot.fromJson(Map<String, Object?> json) => IrsSnapshot(
    id: json['id'] as String,
    label: json['label'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    taxYear: json['taxYear'] as int,
    calculationModelVersion: json['calculationModelVersion'] as String,
    inputSchemaVersion: json['inputSchemaVersion'] as int,
    simulation: TaxSimulation.fromJson(
      (json['simulation'] as Map).cast<String, Object?>(),
    ),
    balanceCents: json['balanceCents'] as int,
    grossIncomeCents: json['grossIncomeCents'] as int,
    withholdingCents: json['withholdingCents'] as int,
    taxCreditsCents: json['taxCreditsCents'] as int,
  );
}
