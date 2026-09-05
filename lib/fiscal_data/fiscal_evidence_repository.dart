import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import 'fiscal_data_orchestrator.dart';

abstract interface class FiscalEvidenceRepository {
  Future<EfaturaCompanionEvidence?> loadEfatura(int taxYear);
  Future<void> saveEfatura(EfaturaCompanionEvidence evidence);
  Future<void> clearEfatura(int taxYear);
}

final class LocalFiscalEvidenceRepository implements FiscalEvidenceRepository {
  static const _storage = MethodChannel('pt.taxy.app/storage');

  Future<File> _file(int taxYear) async {
    final directory = await _storage.invokeMethod<String>('getAppDataPath');
    if (directory == null || directory.isEmpty) {
      throw StateError('storage unavailable');
    }
    return File(
      '$directory${Platform.pathSeparator}fiscal-evidence-$taxYear.json',
    );
  }

  @override
  Future<EfaturaCompanionEvidence?> loadEfatura(int taxYear) async {
    final file = await _file(taxYear);
    if (!await file.exists()) return null;
    final json = (jsonDecode(await file.readAsString()) as Map)
        .cast<String, Object?>();
    if (json['schemaVersion'] != 1 || json['taxYear'] != taxYear) {
      throw const FormatException('fiscal evidence schema');
    }
    return EfaturaCompanionEvidence(
      taxYear: taxYear,
      pendingCount: json['pendingCount'] as int?,
      invoiceCount: json['invoiceCount'] as int?,
      available: json['available'] as bool? ?? false,
      needsReview: json['needsReview'] as bool? ?? false,
      lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String).toUtc(),
    );
  }

  @override
  Future<void> saveEfatura(EfaturaCompanionEvidence evidence) async {
    final file = await _file(evidence.taxYear);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(
      jsonEncode({
        'schemaVersion': 1,
        'taxYear': evidence.taxYear,
        'pendingCount': evidence.pendingCount,
        'invoiceCount': evidence.invoiceCount,
        'available': evidence.available,
        'needsReview': evidence.needsReview,
        'lastUpdatedAt': evidence.lastUpdatedAt.toUtc().toIso8601String(),
      }),
      flush: true,
    );
    if (await file.exists()) await file.delete();
    await temporary.rename(file.path);
  }

  @override
  Future<void> clearEfatura(int taxYear) async {
    final file = await _file(taxYear);
    if (await file.exists()) await file.delete();
  }
}

final class MemoryFiscalEvidenceRepository implements FiscalEvidenceRepository {
  final Map<int, EfaturaCompanionEvidence> _efatura = {};

  @override
  Future<void> clearEfatura(int taxYear) async => _efatura.remove(taxYear);

  @override
  Future<EfaturaCompanionEvidence?> loadEfatura(int taxYear) async =>
      _efatura[taxYear];

  @override
  Future<void> saveEfatura(EfaturaCompanionEvidence evidence) async {
    _efatura[evidence.taxYear] = evidence;
  }
}
