import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android backup is disabled for secure session material', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest, contains('android:allowBackup="false"'));
  });

  test('public backend flow contains no sensitive production logging', () {
    final source = <String>[
      File('lib/modules/efatura/infrastructure/efatura_backend_bridge.dart')
          .readAsStringSync(),
      File(
        'lib/modules/efatura/infrastructure/efatura_session_token_store.dart',
      ).readAsStringSync(),
      File('lib/modules/efatura/screens/efatura_screen.dart')
          .readAsStringSync(),
    ].join('\n');
    expect(source, isNot(contains('debugPrint(')));
    expect(source, isNot(contains('print(')));
    expect(source, isNot(contains('rawResponse')));
    expect(source, isNot(contains('documentId')));
  });

  test('APK asset declaration contains no private certificate material', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(
      pubspec,
      isNot(
        matches(
          RegExp(
            r'^\s*-\s+.*\.(pfx|p12|key)\s*$',
            caseSensitive: false,
            multiLine: true,
          ),
        ),
      ),
    );
    final assets = Directory('assets')
        .listSync(recursive: true)
        .whereType<File>()
        .map((file) => file.path.toLowerCase());
    expect(
      assets.where(
        (path) =>
            path.endsWith('.pfx') ||
            path.endsWith('.p12') ||
            path.endsWith('.key') ||
            path.endsWith('.pkcs8'),
      ),
      isEmpty,
    );
  });

  test('public mobile contract exposes read-only endpoint paths only', () {
    final source = File(
      'lib/modules/efatura/infrastructure/efatura_backend_bridge.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('classificar')));
    expect(source, isNot(contains('registar')));
    expect(source, isNot(contains('associarReceita')));
    expect(source, isNot(contains('DELETE v1/efatura/invoices')));
  });
}
