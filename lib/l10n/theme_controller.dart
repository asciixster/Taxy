import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ThemePreference { system, light, dark }

abstract interface class ThemePreferenceStore {
  Future<ThemePreference> load();
  Future<void> save(ThemePreference preference);
}

final class LocalThemePreferenceStore implements ThemePreferenceStore {
  static const _storage = MethodChannel('pt.taxy.app/storage');

  Future<File> _file() async {
    final directory = await _storage.invokeMethod<String>('getAppDataPath');
    if (directory == null || directory.isEmpty) throw StateError('storage');
    return File('$directory${Platform.pathSeparator}theme.preference');
  }

  @override
  Future<ThemePreference> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return ThemePreference.system;
      final value = (await file.readAsString()).trim();
      return ThemePreference.values.firstWhere(
        (item) => item.name == value,
        orElse: () => ThemePreference.system,
      );
    } on Object {
      return ThemePreference.system;
    }
  }

  @override
  Future<void> save(ThemePreference preference) async {
    final file = await _file();
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(preference.name, flush: true);
    if (await file.exists()) await file.delete();
    await temporary.rename(file.path);
  }
}

final class MemoryThemePreferenceStore implements ThemePreferenceStore {
  MemoryThemePreferenceStore([this.value = ThemePreference.system]);
  ThemePreference value;
  @override
  Future<ThemePreference> load() async => value;
  @override
  Future<void> save(ThemePreference preference) async => value = preference;
}

final class ThemeController extends ChangeNotifier {
  ThemeController(
    this._store, {
    ThemePreference initial = ThemePreference.system,
  }) : _preference = initial;
  final ThemePreferenceStore _store;
  ThemePreference _preference;
  ThemePreference get preference => _preference;
  ThemeMode get mode => switch (_preference) {
    ThemePreference.system => ThemeMode.system,
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
  };
  Future<void> load() async {
    _preference = await _store.load();
    notifyListeners();
  }

  Future<void> select(ThemePreference value) async {
    _preference = value;
    notifyListeners();
    await _store.save(value);
  }
}

final class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope is missing above this context.');
    return scope!.notifier!;
  }
}
