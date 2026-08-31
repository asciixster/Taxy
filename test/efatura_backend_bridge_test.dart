import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/modules/efatura/domain/efatura_models.dart';
import 'package:taxy_pt/modules/efatura/infrastructure/efatura_backend_bridge.dart';

void main() {
  late _Transport transport;
  late BackendEfaturaRuntimeBridge bridge;

  setUp(() {
    transport = _Transport();
    bridge = BackendEfaturaRuntimeBridge(
      baseUri: Uri.parse('https://backend.example.test/taxy/'),
      transport: transport,
    );
  });

  test('backend URL requires HTTPS and contains no embedded credentials', () {
    expect(
      () => BackendEfaturaRuntimeBridge(
        baseUri: Uri.parse('http://backend.example.test/'),
        transport: transport,
      ),
      throwsArgumentError,
    );
    expect(
      () => BackendEfaturaRuntimeBridge(
        baseUri: Uri.parse('https://user:secret@backend.example.test/'),
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

      final overview = await bridge.fetchOverview();
      await bridge.fetchPendingInvoices();

      expect(overview.pendingValidation, 5);
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

  test('missing required overview aggregate fails closed', () async {
    transport.sessionBody = <String, Object?>{
      'sessionToken': 'opaque-session',
      'overview': <String, Object?>{
        'pendingValidation': 5,
        'pendingRevenueAssociation': 0,
        'sectors': <Object?>[],
      },
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
              error.kind == EfaturaFailureKind.parsing,
        ),
      ),
    );
    expect(await bridge.hasCredentials(), isFalse);
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
      'provisionalBenefitCents': 50339,
      'pendingValidation': 5,
      'pendingRevenueAssociation': 0,
      'sectors': <Object?>[
        <String, Object?>{
          'code': 'C05',
          'label': 'Saúde',
          'provisionalBenefitCents': 234,
          'invoiceCount': 1,
        },
      ],
    },
  };
  bool malformedInvoices = false;

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
        statusCode: 200,
        body: <String, Object?>{'overview': sessionBody['overview']!},
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
