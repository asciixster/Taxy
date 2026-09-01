import '../domain/money.dart';
import '../domain/models.dart';

enum DataAvailability { unknown, available }

enum EntryProvenance { manual, imported, externalSource, calculated }

enum EntryStatus { confirmed, estimated, possibleDuplicate }

enum IncomeCategory { employment, selfEmployment, pension, other }

enum ExpenseCategory {
  general,
  health,
  education,
  housing,
  professional,
  other,
}

final class FiscalProfile {
  const FiscalProfile({
    required this.activeTaxYear,
    this.region,
    this.civilStatus,
    this.dependentCount,
    this.hasEmployment,
    this.hasSelfEmployment,
  });

  final int activeTaxYear;
  final TaxRegion? region;
  final CivilStatus? civilStatus;
  final int? dependentCount;
  final bool? hasEmployment;
  final bool? hasSelfEmployment;

  bool get isComplete =>
      region != null &&
      civilStatus != null &&
      dependentCount != null &&
      hasEmployment != null &&
      hasSelfEmployment != null;

  List<String> get missingFields => [
    if (region == null) 'region',
    if (civilStatus == null) 'civilStatus',
    if (dependentCount == null) 'dependentCount',
    if (hasEmployment == null) 'hasEmployment',
    if (hasSelfEmployment == null) 'hasSelfEmployment',
  ];

  FiscalProfile copyWith({
    int? activeTaxYear,
    TaxRegion? region,
    CivilStatus? civilStatus,
    int? dependentCount,
    bool? hasEmployment,
    bool? hasSelfEmployment,
  }) => FiscalProfile(
    activeTaxYear: activeTaxYear ?? this.activeTaxYear,
    region: region ?? this.region,
    civilStatus: civilStatus ?? this.civilStatus,
    dependentCount: dependentCount ?? this.dependentCount,
    hasEmployment: hasEmployment ?? this.hasEmployment,
    hasSelfEmployment: hasSelfEmployment ?? this.hasSelfEmployment,
  );

  Map<String, Object?> toJson() => {
    'activeTaxYear': activeTaxYear,
    'region': region?.name,
    'civilStatus': civilStatus?.name,
    'dependentCount': dependentCount,
    'hasEmployment': hasEmployment,
    'hasSelfEmployment': hasSelfEmployment,
  };

  factory FiscalProfile.fromJson(Map<String, Object?> json) => FiscalProfile(
    activeTaxYear: json['activeTaxYear'] as int,
    region: _enumOrNull(TaxRegion.values, json['region']),
    civilStatus: _enumOrNull(CivilStatus.values, json['civilStatus']),
    dependentCount: json['dependentCount'] as int?,
    hasEmployment: json['hasEmployment'] as bool?,
    hasSelfEmployment: json['hasSelfEmployment'] as bool?,
  );
}

final class IncomeEntry {
  const IncomeEntry({
    required this.id,
    required this.category,
    required this.amount,
    required this.year,
    required this.provenance,
    required this.status,
    this.period,
    this.supportingReference,
    this.deduplicationIdentity,
  });

  final String id;
  final IncomeCategory category;
  final Money amount;
  final int year;
  final DateTime? period;
  final EntryProvenance provenance;
  final EntryStatus status;
  final String? supportingReference;
  final String? deduplicationIdentity;

  Map<String, Object?> toJson() => {
    'id': id,
    'category': category.name,
    'amountCents': amount.cents,
    'year': year,
    'period': period?.toIso8601String(),
    'provenance': provenance.name,
    'status': status.name,
    'supportingReference': supportingReference,
    'deduplicationIdentity': deduplicationIdentity,
  };

  factory IncomeEntry.fromJson(Map<String, Object?> json) => IncomeEntry(
    id: json['id'] as String,
    category: IncomeCategory.values.byName(json['category'] as String),
    amount: Money.fromCents(json['amountCents'] as int),
    year: json['year'] as int,
    period: json['period'] == null
        ? null
        : DateTime.parse(json['period'] as String),
    provenance: EntryProvenance.values.byName(json['provenance'] as String),
    status: EntryStatus.values.byName(json['status'] as String),
    supportingReference: json['supportingReference'] as String?,
    deduplicationIdentity: json['deduplicationIdentity'] as String?,
  );
}

final class ExpenseEntry {
  const ExpenseEntry({
    required this.id,
    required this.category,
    required this.amount,
    required this.year,
    required this.provenance,
    required this.status,
    this.date,
    this.vat,
    this.possibleMatchIdentity,
  });

  final String id;
  final ExpenseCategory category;
  final Money amount;
  final Money? vat;
  final int year;
  final DateTime? date;
  final EntryProvenance provenance;
  final EntryStatus status;
  final String? possibleMatchIdentity;

  Map<String, Object?> toJson() => {
    'id': id,
    'category': category.name,
    'amountCents': amount.cents,
    'vatCents': vat?.cents,
    'year': year,
    'date': date?.toIso8601String(),
    'provenance': provenance.name,
    'status': status.name,
    'possibleMatchIdentity': possibleMatchIdentity,
  };

  factory ExpenseEntry.fromJson(Map<String, Object?> json) => ExpenseEntry(
    id: json['id'] as String,
    category: ExpenseCategory.values.byName(json['category'] as String),
    amount: Money.fromCents(json['amountCents'] as int),
    vat: json['vatCents'] == null
        ? null
        : Money.fromCents(json['vatCents'] as int),
    year: json['year'] as int,
    date: json['date'] == null ? null : DateTime.parse(json['date'] as String),
    provenance: EntryProvenance.values.byName(json['provenance'] as String),
    status: EntryStatus.values.byName(json['status'] as String),
    possibleMatchIdentity: json['possibleMatchIdentity'] as String?,
  );
}

final class ProductState {
  const ProductState({
    required this.profile,
    this.incomes = const [],
    this.expenses = const [],
  });

  factory ProductState.initial([int year = 2026]) =>
      ProductState(profile: FiscalProfile(activeTaxYear: year));

  final FiscalProfile profile;
  final List<IncomeEntry> incomes;
  final List<ExpenseEntry> expenses;

  Money get incomeTotal => Money.fromCents(
    incomes
        .where((entry) => entry.year == profile.activeTaxYear)
        .fold(0, (sum, entry) => sum + entry.amount.cents),
  );

  Money get expenseTotal => Money.fromCents(
    expenses
        .where((entry) => entry.year == profile.activeTaxYear)
        .fold(0, (sum, entry) => sum + entry.amount.cents),
  );

  ProductState copyWith({
    FiscalProfile? profile,
    List<IncomeEntry>? incomes,
    List<ExpenseEntry>? expenses,
  }) => ProductState(
    profile: profile ?? this.profile,
    incomes: incomes ?? this.incomes,
    expenses: expenses ?? this.expenses,
  );

  Map<String, Object?> toJson() => {
    'schemaVersion': 1,
    'profile': profile.toJson(),
    'incomes': incomes.map((entry) => entry.toJson()).toList(),
    'expenses': expenses.map((entry) => entry.toJson()).toList(),
  };

  factory ProductState.fromJson(Map<String, Object?> json) {
    if (json['schemaVersion'] != 1) throw const FormatException('schema');
    return ProductState(
      profile: FiscalProfile.fromJson(
        (json['profile'] as Map).cast<String, Object?>(),
      ),
      incomes: (json['incomes'] as List? ?? const [])
          .map((value) => IncomeEntry.fromJson((value as Map).cast()))
          .toList(growable: false),
      expenses: (json['expenses'] as List? ?? const [])
          .map((value) => ExpenseEntry.fromJson((value as Map).cast()))
          .toList(growable: false),
    );
  }
}

T? _enumOrNull<T extends Enum>(List<T> values, Object? name) {
  if (name is! String) return null;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}

List<IncomeEntry> flagPossibleIncomeDuplicates(List<IncomeEntry> entries) {
  final identities = <String, int>{};
  for (final entry in entries) {
    final identity = entry.deduplicationIdentity;
    if (identity != null && identity.isNotEmpty) {
      identities[identity] = (identities[identity] ?? 0) + 1;
    }
  }
  return entries
      .map((entry) {
        final count = identities[entry.deduplicationIdentity] ?? 0;
        if (count <= 1) return entry;
        return IncomeEntry(
          id: entry.id,
          category: entry.category,
          amount: entry.amount,
          year: entry.year,
          provenance: entry.provenance,
          status: EntryStatus.possibleDuplicate,
          period: entry.period,
          supportingReference: entry.supportingReference,
          deduplicationIdentity: entry.deduplicationIdentity,
        );
      })
      .toList(growable: false);
}
