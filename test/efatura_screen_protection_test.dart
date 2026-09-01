import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/modules/efatura/infrastructure/efatura_screen_protection.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('pt.taxy.test/screen-protection');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'FLAG_SECURE request uses the native Boolean channel contract',
    () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return null;
          });
      final protection = AndroidEfaturaScreenProtection(channel: channel);
      await protection.setScreenSecure(true);
      await protection.setScreenSecure(false);
      expect(calls.map((call) => call.method), <String>[
        'setScreenSecure',
        'setScreenSecure',
      ]);
      expect(calls.map((call) => call.arguments), <bool>[true, false]);
    },
  );
}
