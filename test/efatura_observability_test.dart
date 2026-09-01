import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/modules/efatura/infrastructure/efatura_observability.dart';

void main() {
  test(
    'correlation ids are opaque, fixed-size and contain no personal input',
    () {
      final factory = EfaturaCorrelationIdFactory(random: Random(42));
      final first = factory.create();
      final second = factory.create();
      expect(first, matches(RegExp(r'^[a-f0-9]{32}$')));
      expect(second, matches(RegExp(r'^[a-f0-9]{32}$')));
      expect(second, isNot(first));
    },
  );

  test('routes are normalized and never retain dynamic path values', () {
    expect(
      normalizeEfaturaRoute(
        Uri.parse('https://api.taxy.pt/v1/efatura/sectors/C05/invoices'),
      ),
      '/v1/efatura/sectors/:sector/invoices',
    );
    expect(
      normalizeEfaturaRoute(Uri.parse('https://api.taxy.pt/private/value')),
      '/unknown',
    );
  });

  test('sanitized observation contains only the approved metadata', () {
    const observation = EfaturaApiObservation(
      correlationId: '00112233445566778899aabbccddeeff',
      route: '/v1/efatura/overview',
      httpStatus: 503,
      latencyMs: 812,
      errorCategory: EfaturaApiErrorCategory.backendUnavailable,
      manualAttempt: true,
      attempt: 1,
    );
    expect(observation.toSanitizedMap(), <String, Object?>{
      'correlationId': '00112233445566778899aabbccddeeff',
      'route': '/v1/efatura/overview',
      'httpStatus': 503,
      'latencyMs': 812,
      'errorCategory': 'BACKEND_UNAVAILABLE',
      'manualAttempt': true,
      'attempt': 1,
    });
    expect(observation.toSanitizedMap().keys, hasLength(7));
  });

  test('all public error categories use stable diagnostic codes', () {
    expect(
      EfaturaApiErrorCategory.values.map((value) => value.code).toSet(),
      containsAll(<String>{
        'NETWORK_OFFLINE',
        'DNS_ERROR',
        'TLS_ERROR',
        'TIMEOUT',
        'AUTH_FAILED',
        'SESSION_EXPIRED',
        'RATE_LIMITED',
        'BACKEND_UNAVAILABLE',
        'UPSTREAM_PORTAL_UNAVAILABLE',
        'MALFORMED_RESPONSE',
        'UNKNOWN',
      }),
    );
  });
}
