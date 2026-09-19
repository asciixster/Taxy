enum OfficialPrefillConfidence { exact, highConfidence }

enum OfficialPrefillProvenance { officialAtPrefill }

final class OfficialCategoryARow {
  const OfficialCategoryARow({
    required this.incomeCode,
    required this.holder,
    required this.grossIncomeCents,
    required this.withholdingCents,
    required this.socialSecurityCents,
    required this.unionDuesCents,
  });

  final String? incomeCode;
  final String? holder;
  final int? grossIncomeCents;
  final int? withholdingCents;
  final int? socialSecurityCents;
  final int? unionDuesCents;
}

final class OfficialCategoryATotals {
  const OfficialCategoryATotals({
    required this.grossIncomeCents,
    required this.withholdingCents,
    required this.socialSecurityCents,
    required this.unionDuesCents,
  });

  final int grossIncomeCents;
  final int withholdingCents;
  final int socialSecurityCents;
  final int unionDuesCents;
}

final class OfficialCategoryBEvidence {
  const OfficialCategoryBEvidence({
    required this.regime,
    this.incomeSubjectToWithholdingCents,
    this.withholdingCents,
    this.paymentsOnAccountCents,
    this.investmentTaxCreditCents,
  });

  final String regime;
  final int? incomeSubjectToWithholdingCents;
  final int? withholdingCents;
  final int? paymentsOnAccountCents;
  final int? investmentTaxCreditCents;
}

/// Normalized read-only evidence returned by the Taxy AT connector.
///
/// It is deliberately not a TaxFact. No value may enter the interview or tax
/// engine until the user confirms it for the relevant tax year.
final class OfficialPrefillEvidence {
  const OfficialPrefillEvidence({
    required this.taxYear,
    required this.annexes,
    required this.householdMemberCount,
    required this.categoryARows,
    required this.categoryATotals,
    required this.categoryATotalsMatchOfficialSummary,
    required this.categoryB,
    required this.candidateFields,
    this.provenance = OfficialPrefillProvenance.officialAtPrefill,
    this.confidence = OfficialPrefillConfidence.exact,
  });

  final int taxYear;
  final Set<String> annexes;
  final int householdMemberCount;
  final List<OfficialCategoryARow> categoryARows;
  final OfficialCategoryATotals categoryATotals;
  final bool categoryATotalsMatchOfficialSummary;
  final OfficialCategoryBEvidence? categoryB;
  final Set<String> candidateFields;
  final OfficialPrefillProvenance provenance;
  final OfficialPrefillConfidence confidence;

  bool get hasCategoryA => categoryARows.isNotEmpty;
  bool get hasCategoryB => categoryB != null;

  factory OfficialPrefillEvidence.fromJson(Map<String, Object?> json) {
    _rejectSensitiveKeys(json);
    if (json['schemaVersion'] != 1 || json['source'] != 'OFFICIAL_AT_PREFILL') {
      throw const FormatException('unsupported official prefill schema');
    }
    final taxYear = _year(json['taxYear']);
    final annexes = _stringSet(json['annexes'], const {'A', 'C', 'H'});
    final household = _map(json['household'], 'household');
    final householdMemberCount = _nonNegativeInt(
      household['memberCount'],
      'household.memberCount',
    );
    final categoryA = _map(json['categoryA'], 'categoryA');
    final rawRows = categoryA['rows'];
    if (rawRows is! List) throw const FormatException('categoryA.rows');
    final rows = rawRows
        .map((value) {
          final row = _map(value, 'categoryA.row');
          return OfficialCategoryARow(
            incomeCode: _optionalCode(row['incomeCode'], 'incomeCode'),
            holder: _optionalCode(row['holder'], 'holder'),
            grossIncomeCents: _optionalMoney(
              row['grossIncomeCents'],
              'grossIncome',
            ),
            withholdingCents: _optionalMoney(
              row['withholdingCents'],
              'withholding',
            ),
            socialSecurityCents: _optionalMoney(
              row['socialSecurityCents'],
              'socialSecurity',
            ),
            unionDuesCents: _optionalMoney(row['unionDuesCents'], 'unionDues'),
          );
        })
        .toList(growable: false);
    final rawTotals = _map(categoryA['totals'], 'categoryA.totals');
    final totals = OfficialCategoryATotals(
      grossIncomeCents: _nonNegativeInt(
        rawTotals['grossIncomeCents'],
        'totals.grossIncome',
      ),
      withholdingCents: _nonNegativeInt(
        rawTotals['withholdingCents'],
        'totals.withholding',
      ),
      socialSecurityCents: _nonNegativeInt(
        rawTotals['socialSecurityCents'],
        'totals.socialSecurity',
      ),
      unionDuesCents: _nonNegativeInt(
        rawTotals['unionDuesCents'],
        'totals.unionDues',
      ),
    );
    final totalsMatch = categoryA['totalsMatchOfficialSummary'];
    if (totalsMatch is! bool) {
      throw const FormatException('categoryA totals confidence');
    }
    if (_sum(rows, (row) => row.grossIncomeCents) != totals.grossIncomeCents ||
        _sum(rows, (row) => row.withholdingCents) != totals.withholdingCents ||
        _sum(rows, (row) => row.socialSecurityCents) !=
            totals.socialSecurityCents ||
        _sum(rows, (row) => row.unionDuesCents) != totals.unionDuesCents) {
      throw const FormatException('categoryA total mismatch');
    }
    final rawCategoryB = json['categoryB'];
    final categoryB = rawCategoryB == null
        ? null
        : _categoryB(_map(rawCategoryB, 'categoryB'));
    final rawCandidates = json['candidates'];
    if (rawCandidates is! List) throw const FormatException('candidates');
    final candidateFields = <String>{};
    for (final value in rawCandidates) {
      final candidate = _map(value, 'candidate');
      if (candidate['requiresUserConfirmation'] != true ||
          candidate['provenance'] != 'OFFICIAL_AT_PREFILL' ||
          candidate['confidence'] != 'EXACT') {
        throw const FormatException('unsafe official candidate');
      }
      final field = candidate['field'];
      if (field is! String || field.isEmpty) {
        throw const FormatException('candidate field');
      }
      candidateFields.add(field);
    }
    return OfficialPrefillEvidence(
      taxYear: taxYear,
      annexes: Set.unmodifiable(annexes),
      householdMemberCount: householdMemberCount,
      categoryARows: List.unmodifiable(rows),
      categoryATotals: totals,
      categoryATotalsMatchOfficialSummary: totalsMatch,
      categoryB: categoryB,
      candidateFields: Set.unmodifiable(candidateFields),
    );
  }
}

OfficialCategoryBEvidence _categoryB(Map<String, Object?> value) {
  if (value['present'] != true || value['regime'] != 'ORGANIZED_ACCOUNTING') {
    throw const FormatException('unsupported Category B evidence');
  }
  return OfficialCategoryBEvidence(
    regime: value['regime']! as String,
    incomeSubjectToWithholdingCents: _optionalMoney(
      value['incomeSubjectToWithholdingCents'],
      'categoryB.601',
    ),
    withholdingCents: _optionalMoney(
      value['withholdingCents'],
      'categoryB.602',
    ),
    paymentsOnAccountCents: _optionalMoney(
      value['paymentsOnAccountCents'],
      'categoryB.603',
    ),
    investmentTaxCreditCents: _optionalMoney(
      value['investmentTaxCreditCents'],
      'categoryB.604',
    ),
  );
}

Map<String, Object?> _map(Object? value, String field) {
  if (value is! Map) throw FormatException(field);
  return value.cast<String, Object?>();
}

int _year(Object? value) {
  if (value is! int || value < 2000 || value > 2100) {
    throw const FormatException('taxYear');
  }
  return value;
}

int _nonNegativeInt(Object? value, String field) {
  if (value is! int || value < 0) throw FormatException(field);
  return value;
}

int? _optionalMoney(Object? value, String field) =>
    value == null ? null : _nonNegativeInt(value, field);

String? _optionalCode(Object? value, String field) {
  if (value == null) return null;
  if (value is! String || !RegExp(r'^[A-Za-z0-9]+$').hasMatch(value)) {
    throw FormatException(field);
  }
  return value;
}

Set<String> _stringSet(Object? value, Set<String> allowed) {
  if (value is! List ||
      value.any((item) => item is! String || !allowed.contains(item))) {
    throw const FormatException('annexes');
  }
  return value.cast<String>().toSet();
}

int _sum(
  List<OfficialCategoryARow> rows,
  int? Function(OfficialCategoryARow row) select,
) => rows.fold(0, (total, row) => total + (select(row) ?? 0));

void _rejectSensitiveKeys(Object? value) {
  if (value is List) {
    for (final item in value) {
      _rejectSensitiveKeys(item);
    }
    return;
  }
  if (value is! Map) return;
  for (final entry in value.entries) {
    final key = entry.key.toString().toLowerCase();
    if (key.contains('nif') ||
        key.contains('password') ||
        key.contains('token') ||
        key.contains('cookie') ||
        key.contains('iban')) {
      throw const FormatException('sensitive field in prefill response');
    }
    _rejectSensitiveKeys(entry.value);
  }
}
