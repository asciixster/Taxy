import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum LanguagePreference { automatic, portuguese, english }

abstract interface class LanguagePreferenceStore {
  Future<LanguagePreference> load();
  Future<void> save(LanguagePreference preference);
}

final class LocalLanguagePreferenceStore implements LanguagePreferenceStore {
  static const _storage = MethodChannel('pt.taxy.app/storage');
  static const _fileName = 'language.preference';

  @override
  Future<LanguagePreference> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return LanguagePreference.automatic;
      final stored = (await file.readAsString()).trim();
      return LanguagePreference.values.firstWhere(
        (value) => value.name == stored,
        orElse: () => LanguagePreference.automatic,
      );
    } on Object {
      return LanguagePreference.automatic;
    }
  }

  @override
  Future<void> save(LanguagePreference preference) async {
    final file = await _file();
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(preference.name, flush: true);
    if (await file.exists()) await file.delete();
    await temporary.rename(file.path);
  }

  Future<File> _file() async {
    final directory = await _storage.invokeMethod<String>('getAppDataPath');
    if (directory == null || directory.isEmpty) {
      throw StateError('App settings storage is unavailable.');
    }
    return File('$directory${Platform.pathSeparator}$_fileName');
  }
}

final class MemoryLanguagePreferenceStore implements LanguagePreferenceStore {
  MemoryLanguagePreferenceStore([
    this.preference = LanguagePreference.automatic,
  ]);

  LanguagePreference preference;

  @override
  Future<LanguagePreference> load() async => preference;

  @override
  Future<void> save(LanguagePreference preference) async {
    this.preference = preference;
  }
}

final class LanguageController extends ChangeNotifier {
  LanguageController(
    this._store, {
    LanguagePreference initial = LanguagePreference.automatic,
  }) : _preference = initial;

  final LanguagePreferenceStore _store;
  LanguagePreference _preference;

  LanguagePreference get preference => _preference;

  Locale? get locale => switch (_preference) {
    LanguagePreference.automatic => null,
    LanguagePreference.portuguese => const Locale('pt', 'PT'),
    LanguagePreference.english => const Locale('en'),
  };

  Future<void> load() async {
    _preference = await _store.load();
    notifyListeners();
  }

  Future<void> select(LanguagePreference preference) async {
    if (_preference == preference) return;
    _preference = preference;
    notifyListeners();
    await _store.save(preference);
  }
}

Locale resolveTaxyLocale(Locale? locale, Iterable<Locale> supported) {
  if (locale?.languageCode == 'en') return const Locale('en');
  return const Locale('pt', 'PT');
}

final class LanguageScope extends InheritedNotifier<LanguageController> {
  const LanguageScope({
    super.key,
    required LanguageController controller,
    required super.child,
  }) : super(notifier: controller);

  static LanguageController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LanguageScope>();
    assert(scope != null, 'LanguageScope is missing above this context.');
    return scope!.notifier!;
  }
}
