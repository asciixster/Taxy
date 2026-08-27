import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../domain/models.dart';

abstract interface class SimulationRepository {
  Future<List<TaxSimulation>> list();
  Future<void> save(TaxSimulation simulation);
  Future<void> delete(String id);
  Future<Map<String, Object?>?> loadDraft();
  Future<void> saveDraft(Map<String, Object?> draft);
  Future<void> clearDraft();
}

/// Ficheiro JSON no diretório privado da aplicação Android. A escrita usa um
/// ficheiro temporário e rename para nunca deixar dados parcialmente gravados.
final class LocalSimulationRepository implements SimulationRepository {
  static const _storage = MethodChannel('pt.taxy.app/storage');
  File? _file;
  File? _draft;

  Future<File> get _dataFile async {
    if (_file case final value?) return value;
    final directory = await _storage.invokeMethod<String>('getAppDataPath');
    if (directory == null || directory.isEmpty) {
      throw StateError('Diretório privado da aplicação indisponível.');
    }
    return _file = File('$directory${Platform.pathSeparator}simulations.json');
  }

  Future<File> get _draftFile async {
    if (_draft case final value?) return value;
    final directory = await _storage.invokeMethod<String>('getAppDataPath');
    if (directory == null || directory.isEmpty) {
      throw StateError('Diretório privado da aplicação indisponível.');
    }
    return _draft = File('$directory${Platform.pathSeparator}draft.json');
  }

  Future<List<TaxSimulation>> _read() async {
    final file = await _dataFile;
    if (!await file.exists()) return [];
    final source = await file.readAsString();
    if (source.trim().isEmpty) return [];
    final values = jsonDecode(source) as List<Object?>;
    return values
        .map(
          (value) =>
              TaxSimulation.fromJson((value as Map).cast<String, Object?>()),
        )
        .toList();
  }

  Future<void> _write(List<TaxSimulation> values) async {
    final file = await _dataFile;
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(
      jsonEncode(values.map((e) => e.toJson()).toList()),
      flush: true,
    );
    if (await file.exists()) await file.delete();
    await temporary.rename(file.path);
  }

  @override
  Future<List<TaxSimulation>> list() async {
    final values = await _read();
    values.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return values;
  }

  @override
  Future<void> save(TaxSimulation simulation) async {
    final values = await _read();
    values.removeWhere((item) => item.id == simulation.id);
    values.add(simulation);
    await _write(values);
  }

  @override
  Future<void> delete(String id) async {
    final values = await _read();
    values.removeWhere((item) => item.id == id);
    await _write(values);
  }

  @override
  Future<Map<String, Object?>?> loadDraft() async {
    final file = await _draftFile;
    if (!await file.exists()) return null;
    final source = await file.readAsString();
    if (source.trim().isEmpty) return null;
    return (jsonDecode(source) as Map).cast<String, Object?>();
  }

  @override
  Future<void> saveDraft(Map<String, Object?> draft) async {
    final file = await _draftFile;
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(draft), flush: true);
    if (await file.exists()) await file.delete();
    await temporary.rename(file.path);
  }

  @override
  Future<void> clearDraft() async {
    final file = await _draftFile;
    if (await file.exists()) await file.delete();
  }
}

final class MemorySimulationRepository implements SimulationRepository {
  final Map<String, TaxSimulation> _items = {};
  Map<String, Object?>? _draft;

  @override
  Future<void> clearDraft() async => _draft = null;

  @override
  Future<void> delete(String id) async => _items.remove(id);

  @override
  Future<List<TaxSimulation>> list() async {
    final values = _items.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return values;
  }

  @override
  Future<Map<String, Object?>?> loadDraft() async =>
      _draft == null ? null : Map<String, Object?>.from(_draft!);

  @override
  Future<void> save(TaxSimulation simulation) async =>
      _items[simulation.id] = simulation;

  @override
  Future<void> saveDraft(Map<String, Object?> draft) async =>
      _draft = Map<String, Object?>.from(draft);
}
