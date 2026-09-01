import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/modules/efatura/infrastructure/efatura_api_configuration.dart';

void main() {
  test('normal application flow is pinned to the public HTTPS API', () {
    expect(EfaturaApiConfiguration.baseUri, Uri.parse('https://api.taxy.pt/'));
    expect(EfaturaApiConfiguration.contractVersion, 1);
  });

  test('normal application wiring has no direct FactIntWS fallback', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, isNot(contains('TAXY_EFATURA_BACKEND_URL')));
    expect(source, isNot(contains('AndroidEfaturaRuntimeBridge()')));
    expect(source, contains('SecureEfaturaSessionTokenStore()'));
  });

  test('public flow never names an old or insecure backend', () {
    final sources = <String>[
      File('lib/main.dart').readAsStringSync(),
      File('lib/modules/efatura/infrastructure/efatura_api_configuration.dart')
          .readAsStringSync(),
    ].join('\n');
    expect(sources, isNot(contains('clientes.contabilidades.pt')));
    expect(sources, isNot(contains('localhost')));
    expect(sources, isNot(contains('http://')));
  });
}
