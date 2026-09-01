import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/modules/efatura/domain/efatura_models.dart';
import 'package:taxy_pt/modules/efatura/infrastructure/efatura_runtime_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('pt.taxy.test/efatura');
  late AndroidEfaturaRuntimeBridge bridge;
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    bridge = AndroidEfaturaRuntimeBridge(
      channel: channel,
      enforceAndroid: false,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'getReadiness' => <String, Object>{
              'hasCredentials': true,
              'hasClientIdentity': true,
              'hasCipherCertificate': true,
            },
            'saveCredentials' || 'clearCredentials' => null,
            'loadOverview' => <String, Object>{
              'provisionalBenefitCents': 50339,
              'pendingValidation': 5,
              'pendingRevenueAssociation': 0,
              'sectors': <Object>[
                <String, Object>{'code': 'C05', 'provisionalBenefitCents': 234},
              ],
            },
            'loadPendingInvoices' || 'loadSectorInvoices' => <String, Object>{
              'invoices': <Object>[
                <String, Object>{
                  'date': '2026-08-29',
                  'totalCents': 2345,
                  'pendingClassification': call.method == 'loadPendingInvoices',
                },
              ],
            },
            _ => throw PlatformException(code: 'UNKNOWN_RESPONSE'),
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'credential save crosses channel once and has no read-secret method',
    () async {
      await bridge.save(
        const EfaturaCredentials(nif: '000000000', password: 'synthetic'),
      );
      expect(calls.single.method, 'saveCredentials');
      expect(
        calls.map((call) => call.method),
        isNot(contains('loadCredentials')),
      );
    },
  );

  test('readiness returns metadata without credentials', () async {
    final readiness = await bridge.load();
    expect(readiness.isReady, isTrue);
    expect(calls.single.method, 'getReadiness');
    expect(calls.single.arguments, isNull);
  });

  test('overview is normalized before reaching application service', () async {
    final overview = await bridge.fetchOverview();
    expect(overview.provisionalBenefitCents.value, 50339);
    expect(overview.pendingValidation.value, 5);
    expect(overview.sectors.value.single.code, 'C05');
  });

  test('overview missing optional aggregate is unavailable', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async => <String, Object>{
            'pendingValidation': 5,
            'pendingRevenueAssociation': 0,
            'sectors': <Object>[],
          },
        );
    final overview = await bridge.fetchOverview();
    expect(overview.provisionalBenefitCents.status, AtValueStatus.unavailable);
    expect(overview.pendingValidation.value, 5);
    expect(overview.outcome, EfaturaOverviewOutcome.partialSuccess);
  });

  test('pending and sector operations remain explicit and on-demand', () async {
    final pending = await bridge.fetchPendingInvoices();
    final sector = await bridge.fetchSectorInvoices('C05');
    expect(pending.single.pendingClassification, isTrue);
    expect(sector.single.totalCents, 2345);
    expect(calls.map((call) => call.method), [
      'loadPendingInvoices',
      'loadSectorInvoices',
    ]);
  });

  test('platform errors map to safe application taxonomy', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async => throw PlatformException(
            code: 'TLS_ERROR',
            message: 'Ligação segura indisponível.',
          ),
        );
    await expectLater(
      bridge.fetchOverview(),
      throwsA(
        predicate(
          (error) =>
              error is EfaturaServiceException &&
              error.kind == EfaturaFailureKind.tls &&
              !error.toString().contains('Ligação segura'),
        ),
      ),
    );
  });
}
