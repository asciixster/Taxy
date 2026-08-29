import '../domain/efatura_models.dart';

abstract interface class EfaturaReadOnlyGateway {
  Future<EfaturaOverview> fetchOverview();
  Future<List<EfaturaInvoice>> fetchPendingInvoices();
  Future<List<EfaturaInvoice>> fetchSectorInvoices(String sectorCode);
}

final class EfaturaReadOnlyService {
  const EfaturaReadOnlyService(this._gateway);
  final EfaturaReadOnlyGateway _gateway;

  Future<EfaturaOverview> loadOverview() => _gateway.fetchOverview();
  Future<List<EfaturaInvoice>> loadPendingInvoices() =>
      _gateway.fetchPendingInvoices();
  Future<List<EfaturaInvoice>> loadSectorInvoices(AtExpenseSector sector) {
    if (!RegExp(r'^C(?:0[1-9]|1[0-5]|99)$').hasMatch(sector.code)) {
      throw const EfaturaServiceException(
        EfaturaFailureKind.business,
        'O setor devolvido pelo serviço ainda não é reconhecido.',
      );
    }
    return _gateway.fetchSectorInvoices(sector.code);
  }
}

final class UnconfiguredEfaturaGateway implements EfaturaReadOnlyGateway {
  const UnconfiguredEfaturaGateway();
  Never _missing() => throw const EfaturaServiceException(
    EfaturaFailureKind.notConfigured,
    'A ligação e-Fatura experimental ainda não está configurada neste dispositivo.',
  );
  @override
  Future<EfaturaOverview> fetchOverview() async => _missing();
  @override
  Future<List<EfaturaInvoice>> fetchPendingInvoices() async => _missing();
  @override
  Future<List<EfaturaInvoice>> fetchSectorInvoices(String sectorCode) async =>
      _missing();
}

abstract final class EfaturaFeatureFlags {
  static const experimental = bool.fromEnvironment(
    'TAXY_EFATURA_EXPERIMENTAL',
    defaultValue: false,
  );
}
