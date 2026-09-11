import 'dart:io';

import 'package:flutter/services.dart';

import '../domain/historical_tax_evidence.dart';

enum Dm3IrsFailureKind {
  notConfigured,
  authentication,
  unavailable,
  noDeclaration,
  unknownTemplate,
  invalidDocument,
  network,
  unknown,
}

final class Dm3IrsException implements Exception {
  const Dm3IrsException(this.kind, this.safeMessage);
  final Dm3IrsFailureKind kind;
  final String safeMessage;
}

final class Dm3IrsReadiness {
  const Dm3IrsReadiness({
    required this.hasCredentials,
    required this.hasClientIdentity,
    required this.hasCipherCertificate,
  });
  final bool hasCredentials;
  final bool hasClientIdentity;
  final bool hasCipherCertificate;
  bool get ready => hasCredentials && hasClientIdentity && hasCipherCertificate;
}

abstract interface class Dm3IrsHistoryGateway {
  Future<Dm3IrsReadiness> readiness();
  Future<void> saveCredentials(String nif, String password);
  Future<bool> selectClientIdentity();
  Future<bool> selectCipherCertificate();
  Future<HistoricalTaxEvidence?> loadHistory({required int sourceYear});
  Future<void> setScreenSecure(bool enabled);
  Future<void> clear();
}

final class AndroidDm3IrsHistoryGateway implements Dm3IrsHistoryGateway {
  AndroidDm3IrsHistoryGateway({
    MethodChannel? channel,
    this.enforceAndroid = true,
  }) : _channel = channel ?? const MethodChannel(_channelName),
       assert(!enforceAndroid || channel == null);

  static const _channelName = 'pt.taxy.app/dm3irs_history';
  final MethodChannel _channel;
  final bool enforceAndroid;

  void _requireAndroid() {
    if (enforceAndroid && !Platform.isAndroid) {
      throw const Dm3IrsException(
        Dm3IrsFailureKind.notConfigured,
        'Android required',
      );
    }
  }

  @override
  Future<Dm3IrsReadiness> readiness() async {
    _requireAndroid();
    final value = await _invokeMap('getReadiness');
    return Dm3IrsReadiness(
      hasCredentials: value['hasCredentials'] == true,
      hasClientIdentity: value['hasClientIdentity'] == true,
      hasCipherCertificate: value['hasCipherCertificate'] == true,
    );
  }

  @override
  Future<void> saveCredentials(String nif, String password) async {
    _requireAndroid();
    if (!RegExp(r'^\d{9}$').hasMatch(nif) || password.isEmpty) {
      throw const Dm3IrsException(
        Dm3IrsFailureKind.authentication,
        'Invalid credentials',
      );
    }
    await _invoke('saveCredentials', {'nif': nif, 'password': password});
  }

  @override
  Future<bool> selectClientIdentity() async =>
      (await _invoke('selectClientIdentity')) == true;

  @override
  Future<bool> selectCipherCertificate() async =>
      (await _invoke('selectCipherCertificate')) == true;

  @override
  Future<HistoricalTaxEvidence?> loadHistory({required int sourceYear}) async {
    _requireAndroid();
    if (sourceYear != 2024) {
      throw const Dm3IrsException(
        Dm3IrsFailureKind.unknownTemplate,
        'Unsupported history year',
      );
    }
    final value = await _invokeMap('loadHistory', {'sourceYear': sourceYear});
    if (value['available'] == false) return null;
    return HistoricalTaxEvidence.fromNative(value);
  }

  @override
  Future<void> setScreenSecure(bool enabled) async =>
      _invoke('setScreenSecure', {'enabled': enabled});

  @override
  Future<void> clear() async => _invoke('clear');

  Future<Object?> _invoke(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    try {
      return await _channel.invokeMethod<Object?>(method, arguments);
    } on PlatformException catch (error) {
      throw Dm3IrsException(
        _kind(error.code),
        error.message ?? 'DM3IRS unavailable',
      );
    }
  }

  Future<Map<Object?, Object?>> _invokeMap(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    final value = await _invoke(method, arguments);
    if (value is! Map) {
      throw const Dm3IrsException(
        Dm3IrsFailureKind.unknown,
        'Invalid response',
      );
    }
    return value;
  }

  Dm3IrsFailureKind _kind(String code) => switch (code) {
    'NOT_CONFIGURED' => Dm3IrsFailureKind.notConfigured,
    'AUTH_ERROR' => Dm3IrsFailureKind.authentication,
    'NO_DECLARATION' => Dm3IrsFailureKind.noDeclaration,
    'UNKNOWN_TEMPLATE' => Dm3IrsFailureKind.unknownTemplate,
    'INVALID_DOCUMENT' => Dm3IrsFailureKind.invalidDocument,
    'NETWORK_ERROR' || 'TLS_ERROR' => Dm3IrsFailureKind.network,
    'SERVICE_UNAVAILABLE' => Dm3IrsFailureKind.unavailable,
    _ => Dm3IrsFailureKind.unknown,
  };
}
