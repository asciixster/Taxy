import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/modules/efatura/domain/efatura_models.dart';
import 'package:taxy_pt/modules/efatura/infrastructure/efatura_wire_mapping.dart';

Map<String, Object?> fixture(String name) => jsonDecode(
  File('test/fixtures/efatura_backend/$name.json').readAsStringSync(),
) as Map<String, Object?>;

void main() {
  test('auth fixture preserves unavailable separately from observed zero', () {
    final response = fixture('auth_success');
    final overview = efaturaOverviewFromMap(
      response['overview']! as Map<String, Object?>,
    );
    expect(overview.pendingValidation.value, 3);
    expect(overview.provisionalBenefitCents.status, AtValueStatus.unavailable);
    expect(
      overview.pendingRevenueAssociation.status,
      AtValueStatus.unavailable,
    );
    expect(overview.sectors.status, AtValueStatus.unavailable);
  });

  test('available aggregate fixture reaches the normalized overview', () {
    final response = fixture('overview_available');
    final overview = efaturaOverviewFromMap(
      response['overview']! as Map<String, Object?>,
    );
    expect(overview.pendingValidation.value, 2);
    expect(overview.provisionalBenefitCents.value, 12345);
    expect(
      overview.pendingRevenueAssociation.status,
      AtValueStatus.unavailable,
    );
    expect(overview.sectors.value, hasLength(1));
    expect(overview.sectors.value.single.code, 'C05');
    expect(overview.sectors.value.single.provisionalBenefitCents.value, 2345);
  });

  test(
    'real-shape synthetic invoice fixture maps only display-safe fields',
    () {
      final invoices = efaturaInvoiceList(
        fixture('pending_invoices')['invoices'],
      );
      expect(invoices, hasLength(1));
      expect(invoices.single.issuerDisplayName, 'Emitente sintético');
      expect(invoices.single.totalCents, 2345);
      expect(invoices.single.pendingClassification, isTrue);
    },
  );

  test('malformed contract fixture fails closed', () {
    final response = fixture('malformed_response');
    expect(
      () =>
          efaturaOverviewFromMap(response['overview']! as Map<String, Object?>),
      throwsA(isA<EfaturaServiceException>()),
    );
  });

  test('error fixtures carry only sanitized public contract codes', () {
    expect(fixture('unauthorized')['code'], 'AUTH_ERROR');
    expect(fixture('expired_session')['code'], 'SESSION_EXPIRED');
    expect(fixture('service_unavailable')['code'], 'SERVICE_ERROR');
  });
}
