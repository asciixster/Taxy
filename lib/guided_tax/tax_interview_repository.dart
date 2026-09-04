import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import 'tax_interview_models.dart';

abstract interface class TaxInterviewRepository {
  Future<TaxInterview?> load(int taxYear);
  Future<void> save(TaxInterview interview);
  Future<void> clear(int taxYear);
}

final class LocalTaxInterviewRepository implements TaxInterviewRepository {
  static const _storage = MethodChannel('pt.taxy.app/storage');

  Future<File> _file(int taxYear) async {
    final directory = await _storage.invokeMethod<String>('getAppDataPath');
    if (directory == null || directory.isEmpty) {
      throw StateError('storage unavailable');
    }
    return File(
      '$directory${Platform.pathSeparator}guided-tax-interview-$taxYear.json',
    );
  }

  @override
  Future<TaxInterview?> load(int taxYear) async {
    final file = await _file(taxYear);
    if (!await file.exists()) return null;
    final source = await file.readAsString();
    if (source.trim().isEmpty) return null;
    final interview = TaxInterview.fromJson((jsonDecode(source) as Map).cast());
    if (interview.taxYear != taxYear) throw const FormatException('taxYear');
    return interview;
  }

  @override
  Future<void> save(TaxInterview interview) async {
    final file = await _file(interview.taxYear);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(interview.toJson()), flush: true);
    if (await file.exists()) await file.delete();
    await temporary.rename(file.path);
  }

  @override
  Future<void> clear(int taxYear) async {
    final file = await _file(taxYear);
    if (await file.exists()) await file.delete();
  }
}

final class MemoryTaxInterviewRepository implements TaxInterviewRepository {
  final Map<int, TaxInterview> _values = {};

  @override
  Future<void> clear(int taxYear) async => _values.remove(taxYear);

  @override
  Future<TaxInterview?> load(int taxYear) async => _values[taxYear];

  @override
  Future<void> save(TaxInterview interview) async {
    _values[interview.taxYear] = interview;
  }
}
