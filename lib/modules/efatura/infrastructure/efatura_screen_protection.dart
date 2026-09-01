import 'package:flutter/services.dart';

import 'efatura_runtime_bridge.dart';

/// Narrow Android bridge used by the public-backend flow.
///
/// It exposes screenshot protection only; it cannot call FactIntWS or access a
/// client certificate. The direct connector remains isolated for research.
final class AndroidEfaturaScreenProtection
    implements EfaturaRuntimeProvisioning {
  AndroidEfaturaScreenProtection({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('pt.taxy.app/efatura');

  final MethodChannel _channel;

  @override
  Future<bool> selectClientIdentity() async => true;

  @override
  Future<bool> selectCipherCertificate() async => true;

  @override
  Future<void> setScreenSecure(bool enabled) => _channel.invokeMethod<void>(
    'setScreenSecure',
    <String, Object?>{'enabled': enabled},
  );
}
