import '../domain/efatura_models.dart';

abstract interface class EfaturaCredentialStore {
  Future<void> save(EfaturaCredentials credentials);

  /// Returns readiness metadata only; stored secrets are never returned.
  Future<EfaturaRuntimeReadiness> load();

  Future<void> clear();

  Future<bool> hasCredentials();
}

abstract interface class EfaturaReadOnlyGateway {
  Future<EfaturaOverview> fetchOverview();
  Future<List<EfaturaInvoice>> fetchPendingInvoices();
  Future<List<EfaturaInvoice>> fetchSectorInvoices(String sectorCode);
}

abstract interface class EfaturaReachabilityProbe {
  Future<EfaturaApiReachability> checkReachability();
}

final class EfaturaReadOnlyService {
  const EfaturaReadOnlyService(
    this._gateway, [
    this._credentialStore,
    this._reachabilityProbe,
  ]);

  final EfaturaReadOnlyGateway _gateway;
  final EfaturaCredentialStore? _credentialStore;
  final EfaturaReachabilityProbe? _reachabilityProbe;

  Future<EfaturaApiReachability> reachability() async =>
      await _reachabilityProbe?.checkReachability() ??
      EfaturaApiReachability.reachable;

  Future<EfaturaRuntimeReadiness> readiness() async {
    final store = _credentialStore;
    if (store == null) {
      return const EfaturaRuntimeReadiness(
        hasCredentials: false,
        hasClientIdentity: false,
        hasCipherCertificate: false,
      );
    }
    return store.load();
  }

  Future<EfaturaOverview> connect(EfaturaCredentials credentials) async {
    final store = _credentialStore;
    if (store == null) {
      throw const EfaturaServiceException(
        EfaturaFailureKind.notConfigured,
        'A bridge segura e-Fatura não está disponível.',
      );
    }
    await store.save(credentials);
    try {
      return await loadOverview();
    } on EfaturaServiceException catch (error) {
      if (error.kind == EfaturaFailureKind.authentication ||
          error.kind == EfaturaFailureKind.authorization) {
        await store.clear();
      }
      rethrow;
    }
  }

  Future<void> disconnect() async {
    final store = _credentialStore;
    if (store != null) await store.clear();
  }

  Future<EfaturaOverview> loadOverview() => _gateway.fetchOverview();
  Future<List<EfaturaInvoice>> loadPendingInvoices() =>
      _gateway.fetchPendingInvoices();

  Future<List<EfaturaInvoice>> loadPendingInvoicesIfNeeded(
    EfaturaOverview overview,
  ) async {
    final pending = overview.pendingValidation.valueOrNull;
    if (pending == null || pending <= 0) return const [];
    return loadPendingInvoices();
  }

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
