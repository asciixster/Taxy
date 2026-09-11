import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production connector has a three-operation read allowlist and no write transport', () {
    final protocol = File(
      'android/app/src/main/kotlin/pt/taxy/app/dm3irs/Dm3IrsProtocol.kt',
    ).readAsStringSync();
    final client = File(
      'android/app/src/main/kotlin/pt/taxy/app/dm3irs/Dm3IrsNativeClient.kt',
    ).readAsStringSync();
    expect(protocol, contains('CHECK_DELIVERY'));
    expect(protocol, contains('GET_RECEIPT'));
    expect(protocol, contains('GET_DECLARATION'));
    expect(protocol, contains('prohibitedOperations'));
    expect(protocol, contains('submeterDeclaracaoMobileRequest'));
    expect(client, isNot(contains('submeterDeclaracaoMobileRequest')));
    expect(client, isNot(contains('Log.')));
    expect(client, isNot(contains('writeText')));
    expect(client, isNot(contains('writeBytes')));
  });

  test('raw fiscal payload has no persistence path', () {
    final sources = [
      'android/app/src/main/kotlin/pt/taxy/app/dm3irs/Dm3IrsNativeClient.kt',
      'android/app/src/main/kotlin/pt/taxy/app/dm3irs/Dm3IrsPdfMemoryExtractor.kt',
    ].map((path) => File(path).readAsStringSync()).join('\n');
    expect(sources, contains('memfd_create'));
    expect(sources, contains('pdf.fill(0)'));
    expect(sources, isNot(contains('FileOutputStream')));
    expect(sources, isNot(contains('getExternalStorage')));
    expect(sources, isNot(contains('cacheDir')));
    expect(sources, isNot(contains('filesDir')));
  });

  test('field 603 is gated and absent from Dart product model', () {
    final nativeParser = File(
      'android/app/src/main/kotlin/pt/taxy/app/dm3irs/Dm3IrsStructuralParser.kt',
    ).readAsStringSync();
    final dartModel = File(
      'lib/modules/dm3irs/domain/historical_tax_evidence.dart',
    ).readAsStringSync();
    expect(nativeParser, contains('RUNTIME_VALIDATION_REQUIRED_FIELD_603'));
    expect(dartModel, isNot(contains('paymentsOnAccount')));
    expect(dartModel, isNot(contains('field603')));
  });

  test('Category B production engine is unchanged by DM3IRS integration', () {
    final changed = Process.runSync('git', [
      'diff',
      '--name-only',
      'origin/main...HEAD',
      '--',
      'lib/tax_engine',
      'assets/tax_rules',
    ]);
    expect((changed.stdout as String).trim(), isEmpty);
  });
}
