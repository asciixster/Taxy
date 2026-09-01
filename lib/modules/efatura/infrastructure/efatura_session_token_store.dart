import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class EfaturaSessionTokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> delete();
}

/// Stores only the opaque, short-lived Taxy API session token.
///
/// Portal credentials, upstream cookies and fiscal payloads never enter this
/// store. Android storage is backed by the platform's secure facilities.
final class SecureEfaturaSessionTokenStore implements EfaturaSessionTokenStore {
  SecureEfaturaSessionTokenStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(aOptions: AndroidOptions());

  static const _key = 'taxy.efatura.api.session.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() async {
    final token = await _storage.read(key: _key);
    return token == null || token.trim().isEmpty ? null : token;
  }

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> delete() => _storage.delete(key: _key);
}
