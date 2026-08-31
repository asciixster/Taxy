import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/modules/efatura/application/efatura_read_only_service.dart';
import 'package:taxy_pt/modules/efatura/domain/efatura_models.dart';

void main() {
  const overview = EfaturaOverview(
    provisionalBenefitCents: AtValue.available(1234),
    pendingValidation: AtValue.available(1),
    pendingRevenueAssociation: AtValue.available(0),
    sectors: AtValue.available([
      AtExpenseSector(
        code: 'C05',
        label: 'Saúde',
        provisionalBenefitCents: AtValue.available(234),
      ),
    ]),
  );
  const invoice = EfaturaInvoice(
    date: '2026-08-29',
    totalCents: 2345,
    issuerDisplayName: 'Emitente sintético',
    sectorCode: 'C05',
    sectorLabel: 'Saúde',
  );

  test('loadOverview devolve apenas modelo normalizado', () async {
    final gateway = _Gateway(overview: overview);
    final result = await EfaturaReadOnlyService(gateway).loadOverview();
    expect(result.provisionalBenefitCents.value, 1234);
    expect(gateway.overviewCalls, 1);
  });
  test('loadPendingInvoices preserva empty state', () async {
    final result = await EfaturaReadOnlyService(_Gateway(overview: overview))
        .loadPendingInvoices();
    expect(result, isEmpty);
  });
  test('loadPendingInvoices devolve fatura sintética', () async {
    final result = await EfaturaReadOnlyService(
      _Gateway(overview: overview, pending: const [invoice]),
    ).loadPendingInvoices();
    expect(result.single.totalCents, 2345);
  });
  test(
    'pending gating não chama serviço quando overview indica zero',
    () async {
      final gateway = _Gateway(overview: overview);
      final result = await EfaturaReadOnlyService(gateway)
          .loadPendingInvoicesIfNeeded(
            const EfaturaOverview(
              provisionalBenefitCents: AtValue.available(0),
              pendingValidation: AtValue.available(0),
              pendingRevenueAssociation: AtValue.available(0),
              sectors: AtValue.available([]),
            ),
          );
      expect(result, isEmpty);
      expect(gateway.pendingCalls, 0);
    },
  );
  test('pending gating chama uma vez quando existem pendentes', () async {
    final gateway = _Gateway(overview: overview, pending: const [invoice]);
    final result = await EfaturaReadOnlyService(gateway)
        .loadPendingInvoicesIfNeeded(overview);
    expect(result, hasLength(1));
    expect(gateway.pendingCalls, 1);
  });
  test('connect guarda e valida credenciais com EcraInicial', () async {
    final gateway = _Gateway(overview: overview);
    final store = _Store();
    final result = await EfaturaReadOnlyService(gateway, store).connect(
      const EfaturaCredentials(nif: '000000000', password: 'synthetic'),
    );
    expect(result, overview);
    expect(store.saveCalls, 1);
    expect(gateway.overviewCalls, 1);
  });
  test('auth failure limpa credenciais e não cria sessão falsa', () async {
    final store = _Store();
    final service = EfaturaReadOnlyService(
      const _ErrorGateway(EfaturaFailureKind.authentication),
      store,
    );
    await expectLater(
      service.connect(
        const EfaturaCredentials(nif: '000000000', password: 'synthetic'),
      ),
      throwsA(isA<EfaturaServiceException>()),
    );
    expect(store.clearCalls, 1);
  });
  test('disconnect limpa apenas o credential store', () async {
    final store = _Store();
    await EfaturaReadOnlyService(
      _Gateway(overview: overview),
      store,
    ).disconnect();
    expect(store.clearCalls, 1);
  });
  test('loadSectorInvoices usa código validado', () async {
    final gateway = _Gateway(overview: overview, sector: const [invoice]);
    final result = await EfaturaReadOnlyService(gateway)
        .loadSectorInvoices(overview.sectors.value.single);
    expect(result.single.sectorCode, 'C05');
    expect(gateway.lastSector, 'C05');
  });
  test('unknown sector falha antes do gateway', () {
    final gateway = _Gateway(overview: overview);
    expect(
      () =>
          EfaturaReadOnlyService(gateway)
              .loadSectorInvoices(const AtExpenseSector(code: 'UNKNOWN')),
      throwsA(isA<EfaturaServiceException>()),
    );
    expect(gateway.lastSector, isNull);
  });
  test('gateway não configurado devolve estado próprio', () async {
    await expectLater(
      const EfaturaReadOnlyService(UnconfiguredEfaturaGateway()).loadOverview(),
      throwsA(
        predicate(
          (error) =>
              error is EfaturaServiceException &&
              error.kind == EfaturaFailureKind.notConfigured,
        ),
      ),
    );
  });
  test('modelo de UI não contém credenciais ou identificadores técnicos', () {
    final keys = <String>[
      'date',
      'totalCents',
      'issuerDisplayName',
      'vatCents',
      'sectorCode',
      'sectorLabel',
      'classificationStatus',
      'pendingClassification',
    ];
    expect(keys, isNot(contains('password')));
    expect(keys, isNot(contains('pfxPath')));
    expect(keys, isNot(contains('documentId')));
    expect(keys, isNot(contains('nif')));
  });
  test('feature experimental está desligada por defeito', () {
    expect(EfaturaFeatureFlags.experimental, isFalse);
  });
  for (final kind in EfaturaFailureKind.values) {
    test('erro $kind mantém mensagem segura sem causa técnica', () {
      final error = EfaturaServiceException(kind, 'Mensagem segura');
      expect(error.toString(), isNot(contains('Mensagem segura')));
      expect(error.toString(), isNot(contains('password')));
    });
  }
}

final class _Gateway implements EfaturaReadOnlyGateway {
  _Gateway({
    required this.overview,
    this.pending = const [],
    this.sector = const [],
  });
  final EfaturaOverview overview;
  final List<EfaturaInvoice> pending;
  final List<EfaturaInvoice> sector;
  int overviewCalls = 0;
  int pendingCalls = 0;
  String? lastSector;
  @override
  Future<EfaturaOverview> fetchOverview() async {
    overviewCalls++;
    return overview;
  }

  @override
  Future<List<EfaturaInvoice>> fetchPendingInvoices() async {
    pendingCalls++;
    return pending;
  }

  @override
  Future<List<EfaturaInvoice>> fetchSectorInvoices(String sectorCode) async {
    lastSector = sectorCode;
    return sector;
  }
}

final class _Store implements EfaturaCredentialStore {
  int saveCalls = 0;
  int clearCalls = 0;
  bool stored = false;

  @override
  Future<void> save(EfaturaCredentials credentials) async {
    saveCalls++;
    stored = true;
  }

  @override
  Future<void> clear() async {
    clearCalls++;
    stored = false;
  }

  @override
  Future<bool> hasCredentials() async => stored;

  @override
  Future<EfaturaRuntimeReadiness> load() async => EfaturaRuntimeReadiness(
    hasCredentials: stored,
    hasClientIdentity: true,
    hasCipherCertificate: true,
  );
}

final class _ErrorGateway implements EfaturaReadOnlyGateway {
  const _ErrorGateway(this.kind);
  final EfaturaFailureKind kind;
  Never _error() => throw EfaturaServiceException(kind, 'Mensagem segura');
  @override
  Future<EfaturaOverview> fetchOverview() async => _error();
  @override
  Future<List<EfaturaInvoice>> fetchPendingInvoices() async => _error();
  @override
  Future<List<EfaturaInvoice>> fetchSectorInvoices(String sectorCode) async =>
      _error();
}
