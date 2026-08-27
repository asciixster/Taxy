import 'dart:convert';

import 'money.dart';

enum TaxRegion { continent, madeira, azores }

enum CivilStatus { single, married, deFacto }

enum FilingMode { separate, joint }

enum IncomeEntryMode { annual, monthly }

enum IncomeType {
  employment,
  selfEmployment,
  pensions,
  property,
  capital,
  securities,
  crypto,
  foreign,
  other,
}

enum DependentAllocation { household, taxpayerA, taxpayerB }

final class Dependent {
  const Dependent({
    required this.id,
    required this.ageAtYearEnd,
    this.sharedCustody = false,
    this.alternatingResidence = false,
    this.allocation = DependentAllocation.household,
  });

  final String id;
  final int ageAtYearEnd;
  final bool sharedCustody;
  final bool alternatingResidence;
  final DependentAllocation allocation;

  Map<String, Object?> toJson() => {
    'id': id,
    'ageAtYearEnd': ageAtYearEnd,
    'sharedCustody': sharedCustody,
    'alternatingResidence': alternatingResidence,
    'allocation': allocation.name,
  };

  factory Dependent.fromJson(Map<String, Object?> json) => Dependent(
    id: json['id'] as String,
    ageAtYearEnd: json['ageAtYearEnd'] as int,
    sharedCustody: json['sharedCustody'] as bool? ?? false,
    alternatingResidence: json['alternatingResidence'] as bool? ?? false,
    allocation: DependentAllocation.values.byName(
      json['allocation'] as String? ?? DependentAllocation.household.name,
    ),
  );
}

enum IrsJovemEligibility {
  notRequested,
  needsMoreInformation,
  notEligible,
  eligible,
}

final class IrsJovemIncomeYear {
  const IrsJovemIncomeYear({
    required this.year,
    required this.hadCategoryAIncome,
    required this.hadCategoryBIncome,
    required this.wasDependent,
    required this.residentInPortugal,
    this.usedIncompatibleRegime = false,
  });

  final int year;
  final bool hadCategoryAIncome;
  final bool hadCategoryBIncome;
  final bool wasDependent;
  final bool residentInPortugal;
  final bool usedIncompatibleRegime;

  bool get hadCategoryAOrBIncome => hadCategoryAIncome || hadCategoryBIncome;

  Map<String, Object?> toJson() => {
    'year': year,
    'hadCategoryAIncome': hadCategoryAIncome,
    'hadCategoryBIncome': hadCategoryBIncome,
    'wasDependent': wasDependent,
    'residentInPortugal': residentInPortugal,
    'usedIncompatibleRegime': usedIncompatibleRegime,
  };

  factory IrsJovemIncomeYear.fromJson(Map<String, Object?> json) =>
      IrsJovemIncomeYear(
        year: json['year'] as int,
        // Migra o modelo transitório da 0.3 sem inventar Categoria B.
        hadCategoryAIncome:
            json['hadCategoryAIncome'] as bool? ??
            json['hadCategoryAOrBIncome'] as bool? ??
            false,
        hadCategoryBIncome: json['hadCategoryBIncome'] as bool? ?? false,
        wasDependent: json['wasDependent'] as bool,
        residentInPortugal: json['residentInPortugal'] as bool? ?? true,
        usedIncompatibleRegime:
            json['usedIncompatibleRegime'] as bool? ?? false,
      );
}

final class IrsJovemAnswers {
  const IrsJovemAnswers({
    this.requested = false,
    this.wasDependentAtYearEnd,
    this.qualifyingIncomeYears,
    this.taxSituationRegularized,
    this.usedRnhOrIfici = false,
    this.usedReturnProgram = false,
    this.incomeHistory = const [],
    this.historyConfirmedComplete = false,
  });

  final bool requested;
  final bool? wasDependentAtYearEnd;
  final int? qualifyingIncomeYears;
  final bool? taxSituationRegularized;
  final bool usedRnhOrIfici;
  final bool usedReturnProgram;

  /// Estrutura futura preferida. `qualifyingIncomeYears` mantém compatibilidade
  /// transitória até a UX recolher um histórico anual objetivo.
  final List<IrsJovemIncomeYear> incomeHistory;

  /// Confirma que o histórico cobre todos os anos desde o primeiro rendimento
  /// A/B como sujeito passivo até ao ano simulado, incluindo anos sem rendimento.
  final bool historyConfirmedComplete;

  Map<String, Object?> toJson() => {
    'requested': requested,
    'wasDependentAtYearEnd': wasDependentAtYearEnd,
    'qualifyingIncomeYears': qualifyingIncomeYears,
    'taxSituationRegularized': taxSituationRegularized,
    'usedRnhOrIfici': usedRnhOrIfici,
    'usedReturnProgram': usedReturnProgram,
    'incomeHistory': incomeHistory.map((value) => value.toJson()).toList(),
    'historyConfirmedComplete': historyConfirmedComplete,
  };

  factory IrsJovemAnswers.fromJson(Map<String, Object?> json) =>
      IrsJovemAnswers(
        requested: json['requested'] as bool? ?? false,
        wasDependentAtYearEnd: json['wasDependentAtYearEnd'] as bool?,
        qualifyingIncomeYears: json['qualifyingIncomeYears'] as int?,
        taxSituationRegularized: json['taxSituationRegularized'] as bool?,
        usedRnhOrIfici: json['usedRnhOrIfici'] as bool? ?? false,
        usedReturnProgram: json['usedReturnProgram'] as bool? ?? false,
        incomeHistory: (json['incomeHistory'] as List? ?? const [])
            .map(
              (value) => IrsJovemIncomeYear.fromJson(
                (value as Map).cast<String, Object?>(),
              ),
            )
            .toList(growable: false),
        historyConfirmedComplete:
            json['historyConfirmedComplete'] as bool? ?? false,
      );
}

final class TaxpayerProfile {
  const TaxpayerProfile({
    required this.taxYear,
    required this.age,
    required this.civilStatus,
    required this.dependentAges,
    required this.fullYearResident,
    required this.region,
    required this.filingMode,
    this.isSingleParentHousehold = false,
  });

  final int taxYear;
  final int age;
  final CivilStatus civilStatus;
  final List<int> dependentAges;
  final bool fullYearResident;
  final TaxRegion region;
  final FilingMode filingMode;
  final bool isSingleParentHousehold;

  int get dependents => dependentAges.length;

  TaxpayerProfile copyWith({
    int? taxYear,
    int? age,
    CivilStatus? civilStatus,
    List<int>? dependentAges,
    bool? fullYearResident,
    TaxRegion? region,
    FilingMode? filingMode,
    bool? isSingleParentHousehold,
  }) => TaxpayerProfile(
    taxYear: taxYear ?? this.taxYear,
    age: age ?? this.age,
    civilStatus: civilStatus ?? this.civilStatus,
    dependentAges: dependentAges ?? this.dependentAges,
    fullYearResident: fullYearResident ?? this.fullYearResident,
    region: region ?? this.region,
    filingMode: filingMode ?? this.filingMode,
    isSingleParentHousehold:
        isSingleParentHousehold ?? this.isSingleParentHousehold,
  );

  Map<String, Object?> toJson() => {
    'taxYear': taxYear,
    'age': age,
    'civilStatus': civilStatus.name,
    'dependentAges': dependentAges,
    'fullYearResident': fullYearResident,
    'region': region.name,
    'filingMode': filingMode.name,
    'isSingleParentHousehold': isSingleParentHousehold,
  };

  factory TaxpayerProfile.fromJson(Map<String, Object?> json) =>
      TaxpayerProfile(
        taxYear: json['taxYear'] as int,
        age: json['age'] as int,
        civilStatus: CivilStatus.values.byName(json['civilStatus'] as String),
        dependentAges: (json['dependentAges'] as List).cast<int>(),
        fullYearResident: json['fullYearResident'] as bool,
        region: TaxRegion.values.byName(json['region'] as String),
        filingMode: FilingMode.values.byName(json['filingMode'] as String),
        isSingleParentHousehold:
            json['isSingleParentHousehold'] as bool? ?? false,
      );
}

/// Flags explícitas para situações que alteram materialmente a liquidação.
/// O motor 0.2 recusa qualquer flag ativa até existir um módulo validado.
final class TaxSituationFlags {
  const TaxSituationFlags({
    this.irsJovem = false,
    this.categoryB = false,
    this.pensions = false,
    this.foreignIncome = false,
    this.capitalIncome = false,
    this.propertyIncome = false,
    this.capitalGains = false,
    this.disability = false,
    this.displacedStudent = false,
    this.sharedCustody = false,
    this.otherSpecialSituation = false,
  });

  final bool irsJovem;
  final bool categoryB;
  final bool pensions;
  final bool foreignIncome;
  final bool capitalIncome;
  final bool propertyIncome;
  final bool capitalGains;
  final bool disability;
  final bool displacedStudent;
  final bool sharedCustody;
  final bool otherSpecialSituation;

  Map<String, Object?> toJson() => {
    'irsJovem': irsJovem,
    'categoryB': categoryB,
    'pensions': pensions,
    'foreignIncome': foreignIncome,
    'capitalIncome': capitalIncome,
    'propertyIncome': propertyIncome,
    'capitalGains': capitalGains,
    'disability': disability,
    'displacedStudent': displacedStudent,
    'sharedCustody': sharedCustody,
    'otherSpecialSituation': otherSpecialSituation,
  };

  factory TaxSituationFlags.fromJson(Map<String, Object?> json) =>
      TaxSituationFlags(
        irsJovem: json['irsJovem'] as bool? ?? false,
        categoryB: json['categoryB'] as bool? ?? false,
        pensions: json['pensions'] as bool? ?? false,
        foreignIncome: json['foreignIncome'] as bool? ?? false,
        capitalIncome: json['capitalIncome'] as bool? ?? false,
        propertyIncome: json['propertyIncome'] as bool? ?? false,
        capitalGains: json['capitalGains'] as bool? ?? false,
        disability: json['disability'] as bool? ?? false,
        displacedStudent: json['displacedStudent'] as bool? ?? false,
        sharedCustody: json['sharedCustody'] as bool? ?? false,
        otherSpecialSituation: json['otherSpecialSituation'] as bool? ?? false,
      );
}

final class EmploymentIncome {
  const EmploymentIncome({
    required this.entryMode,
    required this.gross,
    required this.withholding,
    required this.socialSecurity,
    this.monthlyAmount = Money.zero,
    this.months = 14,
  });

  final IncomeEntryMode entryMode;
  final Money gross;
  final Money withholding;
  final Money socialSecurity;
  final Money monthlyAmount;
  final int months;

  EmploymentIncome copyWith({
    IncomeEntryMode? entryMode,
    Money? gross,
    Money? withholding,
    Money? socialSecurity,
    Money? monthlyAmount,
    int? months,
  }) => EmploymentIncome(
    entryMode: entryMode ?? this.entryMode,
    gross: gross ?? this.gross,
    withholding: withholding ?? this.withholding,
    socialSecurity: socialSecurity ?? this.socialSecurity,
    monthlyAmount: monthlyAmount ?? this.monthlyAmount,
    months: months ?? this.months,
  );

  Map<String, Object?> toJson() => {
    'entryMode': entryMode.name,
    'grossCents': gross.cents,
    'withholdingCents': withholding.cents,
    'socialSecurityCents': socialSecurity.cents,
    'monthlyAmountCents': monthlyAmount.cents,
    'months': months,
  };

  factory EmploymentIncome.fromJson(Map<String, Object?> json) =>
      EmploymentIncome(
        entryMode: IncomeEntryMode.values.byName(json['entryMode'] as String),
        gross: Money.fromCents(json['grossCents'] as int),
        withholding: Money.fromCents(json['withholdingCents'] as int),
        socialSecurity: Money.fromCents(json['socialSecurityCents'] as int),
        monthlyAmount: Money.fromCents(json['monthlyAmountCents'] as int? ?? 0),
        months: json['months'] as int? ?? 14,
      );
}

final class DeductionInput {
  const DeductionInput({
    this.general = Money.zero,
    this.health = Money.zero,
    this.education = Money.zero,
    this.rent = Money.zero,
    this.careHomes = Money.zero,
    this.invoiceVat15 = Money.zero,
    this.invoiceVat30 = Money.zero,
    this.invoiceVat35 = Money.zero,
    this.invoiceVat100 = Money.zero,
    this.ppr = Money.zero,
  });

  final Money general;
  final Money health;
  final Money education;
  final Money rent;
  final Money careHomes;
  final Money invoiceVat15;
  final Money invoiceVat30;
  final Money invoiceVat35;
  final Money invoiceVat100;
  final Money ppr;

  DeductionInput copyWith({
    Money? general,
    Money? health,
    Money? education,
    Money? rent,
    Money? careHomes,
    Money? invoiceVat15,
    Money? invoiceVat30,
    Money? invoiceVat35,
    Money? invoiceVat100,
    Money? ppr,
  }) => DeductionInput(
    general: general ?? this.general,
    health: health ?? this.health,
    education: education ?? this.education,
    rent: rent ?? this.rent,
    careHomes: careHomes ?? this.careHomes,
    invoiceVat15: invoiceVat15 ?? this.invoiceVat15,
    invoiceVat30: invoiceVat30 ?? this.invoiceVat30,
    invoiceVat35: invoiceVat35 ?? this.invoiceVat35,
    invoiceVat100: invoiceVat100 ?? this.invoiceVat100,
    ppr: ppr ?? this.ppr,
  );

  Map<String, Object?> toJson() => {
    'generalCents': general.cents,
    'healthCents': health.cents,
    'educationCents': education.cents,
    'rentCents': rent.cents,
    'careHomesCents': careHomes.cents,
    'invoiceVat15Cents': invoiceVat15.cents,
    'invoiceVat30Cents': invoiceVat30.cents,
    'invoiceVat35Cents': invoiceVat35.cents,
    'invoiceVat100Cents': invoiceVat100.cents,
    'pprCents': ppr.cents,
  };

  factory DeductionInput.fromJson(Map<String, Object?> json) => DeductionInput(
    general: Money.fromCents(json['generalCents'] as int? ?? 0),
    health: Money.fromCents(json['healthCents'] as int? ?? 0),
    education: Money.fromCents(json['educationCents'] as int? ?? 0),
    rent: Money.fromCents(json['rentCents'] as int? ?? 0),
    careHomes: Money.fromCents(json['careHomesCents'] as int? ?? 0),
    // Migração fail-safe: o antigo campo genérico só pode representar a
    // categoria de 15%, que era a única taxa então apresentada pela UI.
    invoiceVat15: Money.fromCents(
      json['invoiceVat15Cents'] as int? ??
          json['eligibleInvoiceVatCents'] as int? ??
          0,
    ),
    invoiceVat30: Money.fromCents(json['invoiceVat30Cents'] as int? ?? 0),
    invoiceVat35: Money.fromCents(json['invoiceVat35Cents'] as int? ?? 0),
    invoiceVat100: Money.fromCents(json['invoiceVat100Cents'] as int? ?? 0),
    ppr: Money.fromCents(json['pprCents'] as int? ?? 0),
  );
}

final class TaxpayerInput {
  const TaxpayerInput({
    required this.id,
    required this.age,
    required this.income,
    required this.deductions,
    this.irsJovem = const IrsJovemAnswers(),
  });

  final String id;
  final int age;
  final EmploymentIncome income;
  final DeductionInput deductions;
  final IrsJovemAnswers irsJovem;

  Map<String, Object?> toJson() => {
    'id': id,
    'age': age,
    'income': income.toJson(),
    'deductions': deductions.toJson(),
    'irsJovem': irsJovem.toJson(),
  };

  factory TaxpayerInput.fromJson(Map<String, Object?> json) => TaxpayerInput(
    id: json['id'] as String,
    age: json['age'] as int,
    income: EmploymentIncome.fromJson(
      (json['income'] as Map).cast<String, Object?>(),
    ),
    deductions: DeductionInput.fromJson(
      (json['deductions'] as Map).cast<String, Object?>(),
    ),
    irsJovem: json['irsJovem'] == null
        ? const IrsJovemAnswers()
        : IrsJovemAnswers.fromJson(
            (json['irsJovem'] as Map).cast<String, Object?>(),
          ),
  );
}

final class TaxSimulation {
  const TaxSimulation({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.profile,
    required this.income,
    required this.deductions,
    this.situations = const TaxSituationFlags(),
    this.secondaryTaxpayer,
    this.dependents = const [],
    this.dependentDeductions = const DeductionInput(),
    this.incomeTypes = const {IncomeType.employment},
    this.primaryIrsJovem = const IrsJovemAnswers(),
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TaxpayerProfile profile;
  final EmploymentIncome income;
  final DeductionInput deductions;
  final TaxSituationFlags situations;
  final TaxpayerInput? secondaryTaxpayer;
  final List<Dependent> dependents;
  final DeductionInput dependentDeductions;
  final Set<IncomeType> incomeTypes;
  final IrsJovemAnswers primaryIrsJovem;

  TaxSimulation copyWith({
    String? id,
    String? name,
    DateTime? updatedAt,
    TaxpayerProfile? profile,
    EmploymentIncome? income,
    DeductionInput? deductions,
    TaxSituationFlags? situations,
    TaxpayerInput? secondaryTaxpayer,
    bool clearSecondaryTaxpayer = false,
    List<Dependent>? dependents,
    DeductionInput? dependentDeductions,
    Set<IncomeType>? incomeTypes,
    IrsJovemAnswers? primaryIrsJovem,
  }) => TaxSimulation(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    profile: profile ?? this.profile,
    income: income ?? this.income,
    deductions: deductions ?? this.deductions,
    situations: situations ?? this.situations,
    secondaryTaxpayer: clearSecondaryTaxpayer
        ? null
        : secondaryTaxpayer ?? this.secondaryTaxpayer,
    dependents: dependents ?? this.dependents,
    dependentDeductions: dependentDeductions ?? this.dependentDeductions,
    incomeTypes: incomeTypes ?? this.incomeTypes,
    primaryIrsJovem: primaryIrsJovem ?? this.primaryIrsJovem,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'profile': profile.toJson(),
    'income': income.toJson(),
    'deductions': deductions.toJson(),
    'situations': situations.toJson(),
    'secondaryTaxpayer': secondaryTaxpayer?.toJson(),
    'dependents': dependents.map((value) => value.toJson()).toList(),
    'dependentDeductions': dependentDeductions.toJson(),
    'incomeTypes': incomeTypes.map((value) => value.name).toList(),
    'primaryIrsJovem': primaryIrsJovem.toJson(),
  };

  String encode() => jsonEncode(toJson());

  factory TaxSimulation.fromJson(Map<String, Object?> json) => TaxSimulation(
    id: json['id'] as String,
    name: json['name'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    profile: TaxpayerProfile.fromJson(
      (json['profile'] as Map).cast<String, Object?>(),
    ),
    income: EmploymentIncome.fromJson(
      (json['income'] as Map).cast<String, Object?>(),
    ),
    deductions: DeductionInput.fromJson(
      (json['deductions'] as Map).cast<String, Object?>(),
    ),
    situations: json['situations'] == null
        ? const TaxSituationFlags()
        : TaxSituationFlags.fromJson(
            (json['situations'] as Map).cast<String, Object?>(),
          ),
    secondaryTaxpayer: json['secondaryTaxpayer'] == null
        ? null
        : TaxpayerInput.fromJson(
            (json['secondaryTaxpayer'] as Map).cast<String, Object?>(),
          ),
    dependents: json['dependents'] == null
        ? List.generate(
            ((json['profile'] as Map)['dependentAges'] as List).length,
            (index) => Dependent(
              id: 'legacy-$index',
              ageAtYearEnd:
                  ((json['profile'] as Map)['dependentAges'] as List)[index]
                      as int,
            ),
          )
        : (json['dependents'] as List)
              .map(
                (value) =>
                    Dependent.fromJson((value as Map).cast<String, Object?>()),
              )
              .toList(growable: false),
    dependentDeductions: json['dependentDeductions'] == null
        ? const DeductionInput()
        : DeductionInput.fromJson(
            (json['dependentDeductions'] as Map).cast<String, Object?>(),
          ),
    incomeTypes: json['incomeTypes'] == null
        ? const {IncomeType.employment}
        : (json['incomeTypes'] as List)
              .map((value) => IncomeType.values.byName(value as String))
              .toSet(),
    primaryIrsJovem: json['primaryIrsJovem'] == null
        ? const IrsJovemAnswers()
        : IrsJovemAnswers.fromJson(
            (json['primaryIrsJovem'] as Map).cast<String, Object?>(),
          ),
  );

  factory TaxSimulation.decode(String value) => TaxSimulation.fromJson(
    (jsonDecode(value) as Map).cast<String, Object?>(),
  );
}

final class TaxBreakdown {
  const TaxBreakdown(this.label, this.amount, this.explanation);
  final String label;
  final Money amount;
  final String explanation;
}

/// Structural, presentation-independent audit data for one IRS calculation.
///
/// Monetary values use integer cents through [Money]. Human-readable labels
/// remain in [TaxBreakdown] and must never be used to reconstruct this trace.
final class TaxCalculationTrace {
  const TaxCalculationTrace({
    required this.grossIncome,
    required this.specificDeduction,
    required this.minimumExistenceAllowance,
    required this.taxableIncome,
    required this.maritalQuotient,
    required this.rateDeterminingIncome,
    required this.rateDeterminingQuotient,
    required this.bracketBaseTax,
    required this.bracketExcess,
    required this.marginalRatePpm,
    required this.taxBeforeExemption,
    required this.exemptIncome,
    required this.taxAllocatedToExemptIncome,
    required this.grossTaxAfterExemption,
    required this.dependentCredits,
    required this.generalExpenseCredit,
    required this.healthCredit,
    required this.educationCredit,
    required this.careHomeCredit,
    required this.rentCredit,
    required this.invoiceVatCredit,
    required this.pprCredit,
    required this.overallDeductionsCap,
    required this.totalTaxCredits,
    required this.solidarityTax,
    required this.finalTaxDue,
    required this.withholding,
    required this.balance,
  }) : assert(maritalQuotient == 1 || maritalQuotient == 2);

  final Money grossIncome;
  final Money specificDeduction;
  final Money minimumExistenceAllowance;
  final Money taxableIncome;

  /// Divisor fiscal: 1 for individual/separate calculations, 2 for joint.
  final int maritalQuotient;
  final Money rateDeterminingIncome;
  final Money rateDeterminingQuotient;
  final Money bracketBaseTax;
  final Money bracketExcess;
  final int marginalRatePpm;
  final Money taxBeforeExemption;
  final Money exemptIncome;
  final Money taxAllocatedToExemptIncome;
  final Money grossTaxAfterExemption;
  final Money dependentCredits;
  final Money generalExpenseCredit;
  final Money healthCredit;
  final Money educationCredit;
  final Money careHomeCredit;
  final Money rentCredit;
  final Money invoiceVatCredit;
  final Money pprCredit;
  final Money? overallDeductionsCap;
  final Money totalTaxCredits;
  final Money solidarityTax;
  final Money finalTaxDue;
  final Money withholding;
  final Money balance;

  Money get netIncome => grossIncome - specificDeduction;
}

final class TaxResult {
  const TaxResult({
    required this.available,
    required this.grossIncome,
    required this.specificDeduction,
    required this.minimumExistenceAllowance,
    required this.taxableIncome,
    required this.grossTax,
    required this.taxCredits,
    required this.solidarityTax,
    required this.taxDue,
    required this.withholding,
    required this.balance,
    required this.breakdown,
    required this.warnings,
    required this.assumptions,
    required this.creditBreakdown,
    required this.bracketBaseTax,
    required this.bracketExcess,
    required this.marginalRatePpm,
    required this.overallDeductionsCap,
    required this.trace,
  });

  final bool available;
  final Money grossIncome;
  final Money specificDeduction;
  final Money minimumExistenceAllowance;
  final Money taxableIncome;
  final Money grossTax;
  final Money taxCredits;
  final Money solidarityTax;
  final Money taxDue;
  final Money withholding;

  /// Positivo = reembolso; negativo = imposto adicional a pagar.
  final Money balance;
  final List<TaxBreakdown> breakdown;
  final List<String> warnings;
  final List<String> assumptions;
  final List<TaxBreakdown> creditBreakdown;
  final Money bracketBaseTax;
  final Money bracketExcess;
  final int marginalRatePpm;
  final Money? overallDeductionsCap;
  final TaxCalculationTrace trace;

  bool get isRefund => balance.cents >= 0;
}
