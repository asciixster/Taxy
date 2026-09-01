import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/modules/efatura/domain/efatura_models.dart';
import 'package:taxy_pt/modules/efatura/infrastructure/efatura_wire_mapping.dart';

void main() {
  Map<String, Object?> overview(Object? benefit) {
    final result = <String, Object?>{
      'pendingValidation': <String, Object?>{'status': 'available', 'value': 5},
      'pendingRevenueAssociation': <String, Object?>{'status': 'unavailable'},
      'sectors': <String, Object?>{'status': 'unavailable'},
    };
    if (benefit != null) result['provisionalBenefitCents'] = benefit;
    return result;
  }

  test('available monetary zero remains a real zero', () {
    final parsed = efaturaOverviewFromMap(
      overview(<String, Object?>{'status': 'available', 'value': 0}),
    );
    expect(parsed.provisionalBenefitCents.status, AtValueStatus.available);
    expect(parsed.provisionalBenefitCents.value, 0);
  });

  test('available monetary value is preserved in integer cents', () {
    final parsed = efaturaOverviewFromMap(
      overview(<String, Object?>{'status': 'available', 'value': 50339}),
    );
    expect(parsed.provisionalBenefitCents.value, 50339);
  });

  test('absent optional aggregate is unavailable rather than zero', () {
    final parsed = efaturaOverviewFromMap(overview(null));
    expect(parsed.provisionalBenefitCents.status, AtValueStatus.unavailable);
    expect(parsed.provisionalBenefitCents.valueOrNull, isNull);
    expect(parsed.outcome, EfaturaOverviewOutcome.partialSuccess);
  });

  test('invalid available aggregate fails closed', () {
    expect(
      () => efaturaOverviewFromMap(
        overview(<String, Object?>{'status': 'available', 'value': '503.39'}),
      ),
      throwsA(isA<EfaturaServiceException>()),
    );
  });

  test('sector aggregates preserve independent availability', () {
    final parsed = efaturaOverviewFromMap(<String, Object?>{
      'provisionalBenefitCents': <String, Object?>{'status': 'unavailable'},
      'pendingValidation': <String, Object?>{'status': 'available', 'value': 5},
      'pendingRevenueAssociation': <String, Object?>{'status': 'unavailable'},
      'sectors': <String, Object?>{
        'status': 'available',
        'items': <Object?>[
          <String, Object?>{
            'code': 'C05',
            'provisionalBenefit': <String, Object?>{
              'status': 'available',
              'value': 0,
            },
            'invoiceCount': <String, Object?>{'status': 'unavailable'},
            'totalExpenses': <String, Object?>{
              'status': 'available',
              'value': 12345,
            },
            'totalVatExpenses': <String, Object?>{
              'status': 'available',
              'value': 2345,
            },
            'activity': 'inactive',
          },
        ],
      },
    });
    final sector = parsed.sectors.value.single;
    expect(sector.provisionalBenefitCents.value, 0);
    expect(sector.invoiceCount.status, AtValueStatus.unavailable);
    expect(sector.totalExpensesCents.value, 12345);
    expect(sector.totalVatExpensesCents.value, 2345);
    expect(sector.activity, AtExpenseSectorActivity.inactive);
  });

  test('IRS evidence sums only complete sector totals', () {
    const complete = EfaturaOverview(
      provisionalBenefitCents: AtValue.available(50339),
      pendingValidation: AtValue.available(5),
      pendingRevenueAssociation: AtValue.available(0),
      sectors: AtValue.available([
        AtExpenseSector(
          code: 'C05',
          totalExpensesCents: AtValue.available(10000),
          totalVatExpensesCents: AtValue.available(2300),
        ),
        AtExpenseSector(
          code: 'C06',
          totalExpensesCents: AtValue.available(2500),
          totalVatExpensesCents: AtValue.available(0),
        ),
      ]),
    );
    expect(complete.irsEvidence.listedExpensesCents.value, 12500);
    expect(complete.irsEvidence.listedVatCents.value, 2300);
    expect(complete.irsEvidence.hasOfficialBenefit, isTrue);
    expect(complete.irsEvidence.hasCompleteExpenseTotals, isTrue);

    const partial = EfaturaOverview(
      provisionalBenefitCents: AtValue.unavailable(),
      pendingValidation: AtValue.available(0),
      pendingRevenueAssociation: AtValue.unavailable(),
      sectors: AtValue.available([
        AtExpenseSector(
          code: 'C05',
          totalExpensesCents: AtValue.available(10000),
        ),
      ]),
    );
    expect(partial.irsEvidence.listedExpensesCents.value, 10000);
    expect(
      partial.irsEvidence.listedVatCents.status,
      AtValueStatus.unavailable,
    );
    expect(partial.irsEvidence.hasCompleteExpenseTotals, isFalse);
  });
}
