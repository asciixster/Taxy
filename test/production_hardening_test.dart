import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release signing is fail-closed and never uses debug signing', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('TAXY_ANDROID_KEYSTORE_PATH'));
    expect(gradle, contains('Production signing is not configured'));
    expect(gradle, isNot(contains('signingConfigs.getByName("debug")')));
  });

  test('production identity and secret exclusions are explicit', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final ignores = File('.gitignore').readAsStringSync();
    expect(manifest, contains('android:label="Taxy"'));
    expect(manifest, contains('android:allowBackup="false"'));
    expect(ignores, contains('*.keystore'));
    expect(ignores, contains('.env.local'));
    expect(ignores, contains('*.pfx.password'));
  });
}
