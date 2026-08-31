import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/modules/efatura/domain/efatura_models.dart';
import 'package:taxy_pt/modules/efatura/infrastructure/efatura_wire_mapping.dart';

void main() {
  Map<String, Object?> overview(Object? benefit) {
    final result = <String, Object?>{
      'pendingValidation': <String, Object?>{
        'status': 'available',
        'value': 5,
      },
      'pendingRevenueAssociation': <String, Object?>{
        'status': 'unavailable',
      },
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
        overview(<String, Object?>{
          'status': 'available',
          'value': '503.39',
        }),
      ),
      throwsA(isA<EfaturaServiceException>()),
    );
  });

  test('sector aggregates preserve independent availability', () {
    final parsed = efaturaOverviewFromMap(<String, Object?>{
      'provisionalBenefitCents': <String, Object?>{
        'status': 'unavailable',
      },
      'pendingValidation': <String, Object?>{
        'status': 'available',
        'value': 5,
      },
      'pendingRevenueAssociation': <String, Object?>{
        'status': 'unavailable',
      },
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
            'activity': 'inactive',
          },
        ],
      },
    });
    final sector = parsed.sectors.value.single;
    expect(sector.provisionalBenefitCents.value, 0);
    expect(sector.invoiceCount.status, AtValueStatus.unavailable);
    expect(sector.activity, AtExpenseSectorActivity.inactive);
  });
}
