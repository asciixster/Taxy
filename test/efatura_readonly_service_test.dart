import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/modules/efatura/application/efatura_read_only_service.dart';
import 'package:taxy_pt/modules/efatura/domain/efatura_models.dart';

void main() {
  const overview = EfaturaOverview(
    provisionalBenefitCents: 1234,
    pendingValidation: 1,
    pendingRevenueAssociation: 0,
    sectors: [
      AtExpenseSector(
        code: 'C05',
        label: 'Saúde',
        provisionalBenefitCents: 234,
      ),
    ],
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
    expect(result.provisionalBenefitCents, 1234);
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
  test('loadSectorInvoices usa código validado', () async {
    final gateway = _Gateway(overview: overview, sector: const [invoice]);
    final result = await EfaturaReadOnlyService(gateway)
        .loadSectorInvoices(overview.sectors.single);
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
  String? lastSector;
  @override
  Future<EfaturaOverview> fetchOverview() async {
    overviewCalls++;
    return overview;
  }

  @override
  Future<List<EfaturaInvoice>> fetchPendingInvoices() async => pending;
  @override
  Future<List<EfaturaInvoice>> fetchSectorInvoices(String sectorCode) async {
    lastSector = sectorCode;
    return sector;
  }
}
