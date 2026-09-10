import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../domain/historical_tax_evidence.dart';

abstract interface class HistoricalTaxConfirmationRepository {
  Future<List<HistoricalTaxConfirmation>> load(int targetYear);
  Future<void> saveAll(int targetYear, List<HistoricalTaxConfirmation> values);
  Future<void> clear(int targetYear);
}

final class LocalHistoricalTaxConfirmationRepository
    implements HistoricalTaxConfirmationRepository {
  static const _storage = MethodChannel('pt.taxy.app/storage');

  Future<File> _file(int targetYear) async {
    final directory = await _storage.invokeMethod<String>('getAppDataPath');
    if (directory == null || directory.isEmpty) {
      throw StateError('storage unavailable');
    }
    return File(
      '$directory${Platform.pathSeparator}irs-history-confirmations-$targetYear.json',
    );
  }

  @override
  Future<List<HistoricalTaxConfirmation>> load(int targetYear) async {
    final file = await _file(targetYear);
    if (!await file.exists()) return const [];
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map ||
        decoded['schemaVersion'] != 1 ||
        decoded['targetYear'] != targetYear) {
      throw const FormatException('historical confirmation schema');
    }
    final items = decoded['items'];
    if (items is! List) {
      throw const FormatException('historical confirmation items');
    }
    return items
        .map(
          (item) => HistoricalTaxConfirmation.fromJson(
            (item as Map).cast<String, Object?>(),
          ),
        )
        .where((item) => item.targetYear == targetYear)
        .toList(growable: false);
  }

  @override
  Future<void> saveAll(
    int targetYear,
    List<HistoricalTaxConfirmation> values,
  ) async {
    if (values.any((item) => item.targetYear != targetYear)) {
      throw ArgumentError.value(targetYear, 'targetYear');
    }
    final file = await _file(targetYear);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(
      jsonEncode({
        'schemaVersion': 1,
        'targetYear': targetYear,
        'items': values.map((item) => item.toJson()).toList(growable: false),
      }),
      flush: true,
    );
    if (await file.exists()) await file.delete();
    await temporary.rename(file.path);
  }

  @override
  Future<void> clear(int targetYear) async {
    final file = await _file(targetYear);
    if (await file.exists()) await file.delete();
  }
}

final class MemoryHistoricalTaxConfirmationRepository
    implements HistoricalTaxConfirmationRepository {
  final Map<int, List<HistoricalTaxConfirmation>> _values = {};

  @override
  Future<List<HistoricalTaxConfirmation>> load(int targetYear) async =>
      List.unmodifiable(_values[targetYear] ?? const []);

  @override
  Future<void> saveAll(
    int targetYear,
    List<HistoricalTaxConfirmation> values,
  ) async {
    _values[targetYear] = List.unmodifiable(values);
  }

  @override
  Future<void> clear(int targetYear) async => _values.remove(targetYear);
}
