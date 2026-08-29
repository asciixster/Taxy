import 'dart:io';

import 'package:flutter/services.dart';

import '../application/efatura_read_only_service.dart';
import '../domain/efatura_models.dart';

abstract interface class EfaturaRuntimeProvisioning {
  Future<bool> selectClientIdentity();

  Future<bool> selectCipherCertificate();

  Future<void> setScreenSecure(bool enabled);
}

/// Narrow Flutter ↔ Android boundary. The native side owns credentials,
/// private keys, TLS, NTP and SOAP. Only normalized read-only maps cross it.
final class AndroidEfaturaRuntimeBridge
    implements
        EfaturaReadOnlyGateway,
        EfaturaCredentialStore,
        EfaturaRuntimeProvisioning {
  AndroidEfaturaRuntimeBridge({
    MethodChannel? channel,
    this.enforceAndroid = true,
  }) : _channel = channel ?? const MethodChannel(_channelName),
       assert(enforceAndroid || channel != null);

  static const _channelName = 'pt.taxy.app/efatura';
  final MethodChannel _channel;
  final bool enforceAndroid;

  void _requireAndroid() {
    if (enforceAndroid && !Platform.isAndroid) {
      throw const EfaturaServiceException(
        EfaturaFailureKind.notConfigured,
        'A ligação e-Fatura experimental está disponível apenas em Android.',
      );
    }
  }

  @override
  Future<void> save(EfaturaCredentials credentials) async {
    _requireAndroid();
    if (!RegExp(r'^\d{9}$').hasMatch(credentials.nif) ||
        credentials.password.isEmpty) {
      throw const EfaturaServiceException(
        EfaturaFailureKind.authentication,
        'Indica um NIF de nove dígitos e a senha do Portal das Finanças.',
      );
    }
    try {
      await _channel.invokeMethod<void>('saveCredentials', <String, Object>{
        'nif': credentials.nif,
        'password': credentials.password,
      });
    } on PlatformException catch (error) {
      throw _mapPlatformError(error);
    }
  }

  @override
  Future<EfaturaRuntimeReadiness> load() async {
    _requireAndroid();
    try {
      final value = await _channel.invokeMapMethod<String, Object?>(
        'getReadiness',
      );
      return EfaturaRuntimeReadiness(
        hasCredentials: value?['hasCredentials'] == true,
        hasClientIdentity: value?['hasClientIdentity'] == true,
        hasCipherCertificate: value?['hasCipherCertificate'] == true,
      );
    } on PlatformException catch (error) {
      throw _mapPlatformError(error);
    }
  }

  @override
  Future<bool> hasCredentials() async => (await load()).hasCredentials;

  @override
  Future<void> clear() async {
    _requireAndroid();
    try {
      await _channel.invokeMethod<void>('clearCredentials');
    } on PlatformException catch (error) {
      throw _mapPlatformError(error);
    }
  }

  @override
  Future<bool> selectClientIdentity() async {
    _requireAndroid();
    try {
      return await _channel.invokeMethod<bool>('selectClientIdentity') ?? false;
    } on PlatformException catch (error) {
      throw _mapPlatformError(error);
    }
  }

  @override
  Future<bool> selectCipherCertificate() async {
    _requireAndroid();
    try {
      return await _channel.invokeMethod<bool>('selectCipherCertificate') ??
          false;
    } on PlatformException catch (error) {
      throw _mapPlatformError(error);
    }
  }

  @override
  Future<void> setScreenSecure(bool enabled) async {
    _requireAndroid();
    try {
      await _channel.invokeMethod<void>('setScreenSecure', enabled);
    } on PlatformException catch (error) {
      throw _mapPlatformError(error);
    }
  }

  @override
  Future<EfaturaOverview> fetchOverview() async {
    final result = await _invokeReadOnly('loadOverview');
    return _overviewFromMap(result);
  }

  @override
  Future<List<EfaturaInvoice>> fetchPendingInvoices() async {
    final result = await _invokeReadOnly('loadPendingInvoices');
    return _invoiceList(result['invoices']);
  }

  @override
  Future<List<EfaturaInvoice>> fetchSectorInvoices(String sectorCode) async {
    final result = await _invokeReadOnly('loadSectorInvoices', <String, Object>{
      'sectorCode': sectorCode,
    });
    return _invoiceList(result['invoices']);
  }

  Future<Map<String, Object?>> _invokeReadOnly(
    String method, [
    Map<String, Object>? arguments,
  ]) async {
    _requireAndroid();
    try {
      return await _channel.invokeMapMethod<String, Object?>(
            method,
            arguments,
          ) ??
          const <String, Object?>{};
    } on PlatformException catch (error) {
      throw _mapPlatformError(error);
    }
  }
}

EfaturaOverview _overviewFromMap(Map<String, Object?> map) {
  final rawSectors = (map['sectors'] as List<Object?>? ?? const []);
  return EfaturaOverview(
    provisionalBenefitCents: _requiredInteger(map, 'provisionalBenefitCents'),
    pendingValidation: _requiredInteger(map, 'pendingValidation'),
    pendingRevenueAssociation: _requiredInteger(
      map,
      'pendingRevenueAssociation',
    ),
    sectors: rawSectors
        .whereType<Map<Object?, Object?>>()
        .map(
          (value) => AtExpenseSector(
            code: value['code']?.toString() ?? '',
            label: value['label']?.toString(),
            provisionalBenefitCents: _integer(value['provisionalBenefitCents']),
            invoiceCount: _integer(value['invoiceCount']),
          ),
        )
        .toList(growable: false),
  );
}

List<EfaturaInvoice> _invoiceList(Object? raw) =>
    (raw as List<Object?>? ?? const [])
        .whereType<Map<Object?, Object?>>()
        .map(
          (value) => EfaturaInvoice(
            date: value['date']?.toString() ?? '',
            totalCents: _integer(value['totalCents']) ?? 0,
            issuerDisplayName: value['issuerDisplayName']?.toString(),
            vatCents: _integer(value['vatCents']),
            sectorCode: value['sectorCode']?.toString(),
            sectorLabel: value['sectorLabel']?.toString(),
            classificationStatus: value['classificationStatus']?.toString(),
            pendingClassification: value['pendingClassification'] == true,
          ),
        )
        .toList(growable: false);

int? _integer(Object? value) => switch (value) {
  int value => value,
  num value => value.toInt(),
  _ => null,
};

int _requiredInteger(Map<String, Object?> map, String key) {
  final value = _integer(map[key]);
  if (value == null) {
    throw const EfaturaServiceException(
      EfaturaFailureKind.parsing,
      'Recebemos uma resposta inesperada do e-Fatura.',
    );
  }
  return value;
}

EfaturaServiceException _mapPlatformError(PlatformException error) {
  final kind = switch (error.code) {
    'AUTH_ERROR' => EfaturaFailureKind.authentication,
    'AUTHORIZATION_ERROR' => EfaturaFailureKind.authorization,
    'NTP_TIME_UNAVAILABLE' => EfaturaFailureKind.ntp,
    'TLS_ERROR' => EfaturaFailureKind.tls,
    'SOAP_PROTOCOL_ERROR' => EfaturaFailureKind.soap,
    'BUSINESS_ERROR' => EfaturaFailureKind.business,
    'PARSING_ERROR' => EfaturaFailureKind.parsing,
    'NETWORK_ERROR' => EfaturaFailureKind.network,
    'SESSION_EXPIRED' => EfaturaFailureKind.expired,
    'RUNTIME_NOT_CONFIGURED' => EfaturaFailureKind.notConfigured,
    _ => EfaturaFailureKind.unknown,
  };
  return EfaturaServiceException(
    kind,
    error.message?.trim().isNotEmpty == true
        ? error.message!
        : 'Não foi possível consultar o e-Fatura.',
  );
}
