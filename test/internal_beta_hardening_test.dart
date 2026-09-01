import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/core/internal_beta_build_info.dart';

void main() {
  test('build identification has safe non-secret fields only', () {
    expect(InternalBetaBuildInfo.appVersion, '0.7.11');
    expect(InternalBetaBuildInfo.buildNumber, '11');
    expect(InternalBetaBuildInfo.apiHost, 'api.taxy.pt');
  });

  test(
    'public bridge has correlation id, finite timeouts and no automatic retry',
    () {
      final source = File(
        'lib/modules/efatura/infrastructure/efatura_backend_bridge.dart',
      ).readAsStringSync();
      expect(source, contains("request.headers.set('X-Correlation-ID'"));
      expect(source, contains('connectTimeout = const Duration(seconds: 20)'));
      expect(source, contains('responseTimeout = const Duration(seconds: 90)'));
      expect(source, isNot(contains('retry(')));
    },
  );

  test('normal e-Fatura flow keeps public API only and no write operation', () {
    final sources = <String>[
      File('lib/main.dart').readAsStringSync(),
      File('lib/modules/efatura/infrastructure/efatura_backend_bridge.dart')
          .readAsStringSync(),
      File('lib/modules/efatura/infrastructure/efatura_api_configuration.dart')
          .readAsStringSync(),
    ].join('\n');
    expect(sources, contains('https://api.taxy.pt/'));
    expect(sources, isNot(contains('clientes.contabilidades.pt')));
    expect(sources, isNot(contains('servicos.portaldasfinancas.gov.pt')));
    expect(sources.toLowerCase(), isNot(contains('classificarfaturas')));
    expect(sources.toLowerCase(), isNot(contains('registarfatura')));
    expect(sources.toLowerCase(), isNot(contains('eliminarfatura')));
    expect(sources.toLowerCase(), isNot(contains('associarreceita')));
  });

  test('no fiscal response cache is implemented in the public bridge', () {
    final source = File(
      'lib/modules/efatura/infrastructure/efatura_backend_bridge.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('SharedPreferences')));
    expect(source, isNot(contains('SQLite')));
    expect(source, isNot(contains('cacheDir')));
    expect(source, isNot(contains('filesDir')));
  });
}
