import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final nativeRoot = Directory(
    'android/app/src/main/kotlin/pt/taxy/app/efatura',
  );

  test(
    'native bridge contains no logging sink for fiscal or credential data',
    () {
      final source = nativeRoot
          .listSync()
          .whereType<File>()
          .map((file) => file.readAsStringSync())
          .join('\n');
      expect(source, isNot(contains('android.util.Log')));
      expect(source, isNot(contains('Log.')));
      expect(source, isNot(contains('println(')));
      expect(source, isNot(contains('printStackTrace')));
    },
  );

  test('credential API never exposes a loadCredentials channel method', () {
    final dartBridge = File(
      'lib/modules/efatura/infrastructure/efatura_runtime_bridge.dart',
    ).readAsStringSync();
    final nativeBridge = File('${nativeRoot.path}/EfaturaRuntimeBridge.kt')
        .readAsStringSync();
    expect(dartBridge, isNot(contains("invokeMethod('loadCredentials'")));
    expect(nativeBridge, isNot(contains('"loadCredentials" ->')));
    final secureStore = File('${nativeRoot.path}/SecureCredentialStore.kt')
        .readAsStringSync();
    expect(secureStore, contains('AndroidKeyStore'));
  });

  test('runtime exposes only the three confirmed read-only operations', () {
    final protocol = File('${nativeRoot.path}/FactIntWsProtocol.kt')
        .readAsStringSync();
    expect(protocol, contains('OVERVIEW("EcraInicial")'));
    expect(protocol, contains('PENDING("FaturasPorClassificar")'));
    expect(protocol, contains('SECTOR("FaturasPorSetor")'));
    for (final forbidden in [
      'ClassificarFatura',
      'RegistarFaturaQRCode',
      'EliminarFaturaQRCode',
      'AssociarReceita',
    ]) {
      expect(protocol, isNot(contains(forbidden)));
    }
  });

  test(
    'Android manifest disables backup and enables only required network',
    () {
      final manifest = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();
      expect(manifest, contains('android:allowBackup="false"'));
      expect(manifest, contains('android.permission.INTERNET'));
    },
  );
}
