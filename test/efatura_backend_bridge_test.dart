import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/modules/efatura/domain/efatura_models.dart';
import 'package:taxy_pt/modules/efatura/infrastructure/efatura_backend_bridge.dart';
import 'package:taxy_pt/modules/efatura/infrastructure/efatura_session_token_store.dart';

void main() {
  late _Transport transport;
  late _TokenStore tokenStore;
  late BackendEfaturaRuntimeBridge bridge;

  setUp(() {
    transport = _Transport();
    tokenStore = _TokenStore();
    bridge = BackendEfaturaRuntimeBridge(
      baseUri: Uri.parse('https://backend.example.test/taxy/'),
      sessionTokenStore: tokenStore,
      transport: transport,
    );
  });

  test('backend URL requires HTTPS and contains no embedded credentials', () {
    expect(
      () => BackendEfaturaRuntimeBridge(
        baseUri: Uri.parse('http://backend.example.test/'),
        sessionTokenStore: tokenStore,
        transport: transport,
      ),
      throwsArgumentError,
    );
    expect(
      () => BackendEfaturaRuntimeBridge(
        baseUri: Uri.parse('https://user:secret@backend.example.test/'),
        sessionTokenStore: tokenStore,
        transport: transport,
      ),
      throwsArgumentError,
    );
  });

  test(
    'connect sends credentials once and retains only opaque session',
    () async {
      await bridge.save(
        const EfaturaCredentials(
          nif: '000000000',
          password: 'synthetic-secret',
        ),
      );
      expect((await bridge.load()).isReady, isTrue);
      expect(tokenStore.token, 'opaque-session');

      final overview = await bridge.fetchOverview();
      await bridge.fetchPendingInvoices();

      expect(overview.pendingValidation.value, 5);
      expect(overview.sectors.value.single.totalExpensesCents.value, 2345);
      expect(overview.sectors.value.single.totalVatExpensesCents.value, 439);
      expect(overview.irsEvidence.listedExpensesCents.value, 2345);
      expect(transport.requests, hasLength(2));
      expect(transport.requests.first.path, '/taxy/v1/efatura/sessions');
      expect(transport.requests.first.body?['password'], 'synthetic-secret');
      expect(transport.requests.last.body, isNull);
      expect(transport.requests.last.bearerToken, 'opaque-session');
      expect(
        transport.requests.skip(1).toString(),
        isNot(contains('synthetic-secret')),
      );
    },
  );

  test(
    'connect overview is reused without duplicate network request',
    () async {
      await bridge.save(
        const EfaturaCredentials(
          nif: '000000000',
          password: 'synthetic-secret',
        ),
      );
      await bridge.fetchOverview();
      expect(transport.requests, hasLength(1));

      await bridge.fetchOverview();
      expect(transport.requests, hasLength(2));
      expect(transport.requests.last.path, '/taxy/v1/efatura/overview');
    },
  );

  test('disconnect clears local capability before remote revocation', () async {
    await bridge.save(
      const EfaturaCredentials(nif: '000000000', password: 'synthetic-secret'),
    );
    await bridge.clear();
    expect(await bridge.hasCredentials(), isFalse);
    expect(tokenStore.token, isNull);
    expect(transport.requests.last.method, 'DELETE');
    await expectLater(
      bridge.fetchOverview(),
      throwsA(
        predicate(
          (error) =>
              error is EfaturaServiceException &&
              error.kind == EfaturaFailureKind.notConfigured,
        ),
      ),
    );
  });

  test('opaque session survives bridge recreation in secure store', () async {
    await bridge.save(
      const EfaturaCredentials(nif: '000000000', password: 'synthetic-secret'),
    );
    final reopened = BackendEfaturaRuntimeBridge(
      baseUri: Uri.parse('https://backend.example.test/taxy/'),
      sessionTokenStore: tokenStore,
      transport: transport,
    );
    expect((await reopened.load()).isReady, isTrue);
    await reopened.fetchOverview();
    expect(transport.requests.last.bearerToken, 'opaque-session');
  });

  test(
    'expired session is removed and cannot leave false connected state',
    () async {
      tokenStore.token = 'expired-session';
      transport.overviewStatus = 401;
      transport.overviewBody = const <String, Object?>{
        'code': 'SESSION_EXPIRED',
      };
      await expectLater(
        bridge.fetchOverview(),
        throwsA(
          predicate(
            (error) =>
                error is EfaturaServiceException &&
                error.kind == EfaturaFailureKind.expired,
          ),
        ),
      );
      expect(tokenStore.token, isNull);
      expect((await bridge.load()).hasCredentials, isFalse);
    },
  );

  test(
    'health distinguishes reachable, auth-required and unavailable',
    () async {
      expect(
        await bridge.checkReachability(),
        EfaturaApiReachability.reachable,
      );
      transport.healthStatus = 401;
      expect(
        await bridge.checkReachability(),
        EfaturaApiReachability.authenticationRequired,
      );
      transport.healthStatus = 503;
      expect(
        await bridge.checkReachability(),
        EfaturaApiReachability.serviceUnavailable,
      );
    },
  );

  for (final entry in <int, EfaturaFailureKind>{
    403: EfaturaFailureKind.authorization,
    404: EfaturaFailureKind.operationUnavailable,
    429: EfaturaFailureKind.rateLimited,
    502: EfaturaFailureKind.serviceUnavailable,
    503: EfaturaFailureKind.serviceUnavailable,
    504: EfaturaFailureKind.serviceUnavailable,
  }.entries) {
    test('HTTP ${entry.key} maps to ${entry.value}', () async {
      tokenStore.token = 'opaque-session';
      transport.overviewStatus = entry.key;
      transport.overviewBody = const <String, Object?>{};
      await expectLater(
        bridge.fetchOverview(),
        throwsA(
          predicate(
            (error) =>
                error is EfaturaServiceException && error.kind == entry.value,
          ),
        ),
      );
    });
  }

  test('sector invoice response is normalized without technical ids', () async {
    await bridge.save(
      const EfaturaCredentials(nif: '000000000', password: 'synthetic-secret'),
    );
    final invoices = await bridge.fetchSectorInvoices('C05');
    expect(invoices.single.totalCents, 2345);
    expect(invoices.single.issuerDisplayName, 'Emitente sintético');
    expect(transport.requests.last.path, endsWith('/C05/invoices'));
  });

  test('backend authentication error maps to safe application error', () async {
    transport.sessionStatus = 401;
    transport.sessionBody = const <String, Object?>{
      'code': 'AUTH_ERROR',
      'message': 'Não foi possível autenticar no Portal das Finanças.',
    };
    await expectLater(
      bridge.save(
        const EfaturaCredentials(
          nif: '000000000',
          password: 'synthetic-secret',
        ),
      ),
      throwsA(
        predicate(
          (error) =>
              error is EfaturaServiceException &&
              error.kind == EfaturaFailureKind.authentication &&
              !error.toString().contains('synthetic-secret'),
        ),
      ),
    );
    expect(await bridge.hasCredentials(), isFalse);
  });

  test(
    'missing optional overview aggregate is explicitly unavailable',
    () async {
      transport.sessionBody = <String, Object?>{
        'sessionToken': 'opaque-session',
        'overview': <String, Object?>{
          'pendingValidation': 5,
          'pendingRevenueAssociation': 0,
          'sectors': <Object?>[],
        },
      };
      await bridge.save(
        const EfaturaCredentials(
          nif: '000000000',
          password: 'synthetic-secret',
        ),
      );
      final overview = await bridge.fetchOverview();
      expect(
        overview.provisionalBenefitCents.status,
        AtValueStatus.unavailable,
      );
      expect(overview.outcome, EfaturaOverviewOutcome.partialSuccess);
    },
  );

  test('malformed available aggregate fails closed', () async {
    transport.sessionBody = <String, Object?>{
      'sessionToken': 'opaque-session',
      'overview': <String, Object?>{
        'provisionalBenefitCents': <String, Object?>{
          'status': 'available',
          'value': 'not-money',
        },
        'pendingValidation': <String, Object?>{
          'status': 'available',
          'value': 5,
        },
        'pendingRevenueAssociation': <String, Object?>{'status': 'unavailable'},
        'sectors': <String, Object?>{'status': 'unavailable'},
      },
    };
    await expectLater(
      bridge.save(
        const EfaturaCredentials(
          nif: '000000000',
          password: 'synthetic-secret',
        ),
      ),
      throwsA(isA<EfaturaServiceException>()),
    );
  });

  test('malformed invoice cannot disappear silently', () async {
    await bridge.save(
      const EfaturaCredentials(nif: '000000000', password: 'synthetic-secret'),
    );
    transport.malformedInvoices = true;
    await expectLater(
      bridge.fetchPendingInvoices(),
      throwsA(
        predicate(
          (error) =>
              error is EfaturaServiceException &&
              error.kind == EfaturaFailureKind.parsing,
        ),
      ),
    );
  });
}

final class _Request {
  const _Request({
    required this.method,
    required this.uri,
    required this.bearerToken,
    required this.body,
  });

  final String method;
  final Uri uri;
  final String? bearerToken;
  final Map<String, Object?>? body;
  String get path => uri.path;

  @override
  String toString() => '$method $path token=${bearerToken != null}';
}

final class _Transport implements EfaturaBackendTransport {
  final requests = <_Request>[];
  int sessionStatus = 201;
  Map<String, Object?> sessionBody = <String, Object?>{
    'sessionToken': 'opaque-session',
    'overview': <String, Object?>{
      'provisionalBenefitCents': <String, Object?>{
        'status': 'available',
        'value': 50339,
      },
      'pendingValidation': <String, Object?>{'status': 'available', 'value': 5},
      'pendingRevenueAssociation': <String, Object?>{
        'status': 'available',
        'value': 0,
      },
      'sectors': <String, Object?>{
        'status': 'available',
        'items': <Object?>[
          <String, Object?>{
            'code': 'C05',
            'label': 'Saúde',
            'provisionalBenefit': <String, Object?>{
              'status': 'available',
              'value': 234,
            },
            'totalExpenses': <String, Object?>{
              'status': 'available',
              'value': 2345,
            },
            'totalVatExpenses': <String, Object?>{
              'status': 'available',
              'value': 439,
            },
            'invoiceCount': <String, Object?>{
              'status': 'available',
              'value': 1,
            },
            'activity': 'active',
          },
        ],
      },
    },
  };
  bool malformedInvoices = false;
  int healthStatus = 200;
  int overviewStatus = 200;
  Map<String, Object?>? overviewBody;

  @override
  Future<EfaturaBackendResponse> send({
    required String method,
    required Uri uri,
    String? bearerToken,
    Map<String, Object?>? body,
  }) async {
    requests.add(
      _Request(method: method, uri: uri, bearerToken: bearerToken, body: body),
    );
    if (uri.path.endsWith('/health')) {
      return EfaturaBackendResponse(
        statusCode: healthStatus,
        body: const <String, Object?>{'status': 'ok'},
      );
    }
    if (uri.path.endsWith('/sessions')) {
      return EfaturaBackendResponse(
        statusCode: sessionStatus,
        body: sessionBody,
      );
    }
    if (method == 'DELETE') {
      return const EfaturaBackendResponse(statusCode: 204, body: {});
    }
    if (uri.path.endsWith('/overview')) {
      return EfaturaBackendResponse(
        statusCode: overviewStatus,
        body:
            overviewBody ??
            <String, Object?>{'overview': sessionBody['overview']!},
      );
    }
    if (malformedInvoices) {
      return const EfaturaBackendResponse(
        statusCode: 200,
        body: <String, Object?>{
          'invoices': <Object?>[
            <String, Object?>{'date': '2026-08-29'},
          ],
        },
      );
    }
    return const EfaturaBackendResponse(
      statusCode: 200,
      body: <String, Object?>{
        'invoices': <Object?>[
          <String, Object?>{
            'date': '2026-08-29',
            'totalCents': 2345,
            'vatCents': 439,
            'issuerDisplayName': 'Emitente sintético',
            'sectorCode': 'C05',
            'pendingClassification': true,
          },
        ],
      },
    );
  }
}

final class _TokenStore implements EfaturaSessionTokenStore {
  String? token;

  @override
  Future<void> delete() async => token = null;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async => token = value;
}
