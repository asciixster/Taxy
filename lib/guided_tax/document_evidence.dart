import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import 'tax_interview_models.dart';

enum GuidedDocumentType {
  employmentIncomeStatement,
  withholdingProof,
  socialSecurityProof,
}

final class GuidedDocumentEvidence {
  const GuidedDocumentEvidence({
    required this.type,
    required this.taxYear,
    required this.amountCents,
    required this.confirmedAt,
  });

  final GuidedDocumentType type;
  final int taxYear;
  final int amountCents;
  final DateTime confirmedAt;

  String get factId => switch (type) {
    GuidedDocumentType.employmentIncomeStatement => 'employmentGrossCents',
    GuidedDocumentType.withholdingProof => 'withholdingCents',
    GuidedDocumentType.socialSecurityProof => 'socialSecurityCents',
  };

  Map<String, Object?> toJson() => {
    'type': type.name,
    'taxYear': taxYear,
    'amountCents': amountCents,
    'confirmedAt': confirmedAt.toUtc().toIso8601String(),
  };

  factory GuidedDocumentEvidence.fromJson(Map<String, Object?> json) {
    final year = json['taxYear'];
    final amount = json['amountCents'];
    final confirmedAt = DateTime.tryParse(json['confirmedAt'] as String? ?? '');
    if (year is! int || amount is! int || amount < 0 || confirmedAt == null) {
      throw const FormatException('document evidence');
    }
    return GuidedDocumentEvidence(
      type: GuidedDocumentType.values.byName(json['type'] as String),
      taxYear: year,
      amountCents: amount,
      confirmedAt: confirmedAt.toUtc(),
    );
  }
}

abstract interface class GuidedDocumentEvidenceRepository {
  Future<List<GuidedDocumentEvidence>> load(int taxYear);
  Future<void> save(GuidedDocumentEvidence evidence);
  Future<void> remove(int taxYear, GuidedDocumentType type);
  Future<void> clear(int taxYear);
}

final class LocalGuidedDocumentEvidenceRepository
    implements GuidedDocumentEvidenceRepository {
  static const _storage = MethodChannel('pt.taxy.app/storage');

  Future<File> _file(int taxYear) async {
    final directory = await _storage.invokeMethod<String>('getAppDataPath');
    if (directory == null || directory.isEmpty) {
      throw StateError('storage unavailable');
    }
    return File(
      '$directory${Platform.pathSeparator}guided-document-evidence-$taxYear.json',
    );
  }

  @override
  Future<List<GuidedDocumentEvidence>> load(int taxYear) async {
    final file = await _file(taxYear);
    if (!await file.exists()) return const [];
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map || decoded['schemaVersion'] != 1) {
      throw const FormatException('document evidence schema');
    }
    final items = decoded['items'];
    if (items is! List) throw const FormatException('document evidence items');
    final evidence = items
        .map(
          (item) => GuidedDocumentEvidence.fromJson(
            (item as Map).cast<String, Object?>(),
          ),
        )
        .toList(growable: false);
    if (evidence.any((item) => item.taxYear != taxYear)) {
      throw const FormatException('document evidence taxYear');
    }
    return evidence;
  }

  Future<void> _write(int taxYear, List<GuidedDocumentEvidence> values) async {
    final file = await _file(taxYear);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(
      jsonEncode({
        'schemaVersion': 1,
        'taxYear': taxYear,
        'items': values.map((item) => item.toJson()).toList(),
      }),
      flush: true,
    );
    if (await file.exists()) await file.delete();
    await temporary.rename(file.path);
  }

  @override
  Future<void> save(GuidedDocumentEvidence evidence) async {
    final current = await load(evidence.taxYear);
    await _write(evidence.taxYear, [
      ...current.where((item) => item.type != evidence.type),
      evidence,
    ]);
  }

  @override
  Future<void> remove(int taxYear, GuidedDocumentType type) async {
    final current = await load(taxYear);
    await _write(taxYear, current.where((item) => item.type != type).toList());
  }

  @override
  Future<void> clear(int taxYear) async {
    final file = await _file(taxYear);
    if (await file.exists()) await file.delete();
  }
}

final class MemoryGuidedDocumentEvidenceRepository
    implements GuidedDocumentEvidenceRepository {
  final Map<int, List<GuidedDocumentEvidence>> _values = {};

  @override
  Future<List<GuidedDocumentEvidence>> load(int taxYear) async =>
      List.unmodifiable(_values[taxYear] ?? const []);

  @override
  Future<void> save(GuidedDocumentEvidence evidence) async {
    final current = _values[evidence.taxYear] ?? const [];
    _values[evidence.taxYear] = [
      ...current.where((item) => item.type != evidence.type),
      evidence,
    ];
  }

  @override
  Future<void> remove(int taxYear, GuidedDocumentType type) async {
    _values[taxYear] = (_values[taxYear] ?? const [])
        .where((item) => item.type != type)
        .toList();
  }

  @override
  Future<void> clear(int taxYear) async => _values.remove(taxYear);
}

Map<String, TaxAnswer> reconcileDocumentEvidenceAnswers({
  required Map<String, TaxAnswer> current,
  required List<GuidedDocumentEvidence> before,
  required List<GuidedDocumentEvidence> after,
}) {
  final updated = {...current};
  final previousByType = {for (final item in before) item.type: item};
  final nextByType = {for (final item in after) item.type: item};

  for (final old in before) {
    if (nextByType.containsKey(old.type)) continue;
    final answer = updated[old.factId];
    if (answer?.provenance == TaxFactProvenance.imported &&
        answer?.value == old.amountCents) {
      updated.remove(old.factId);
    }
  }

  for (final item in after) {
    final answer = updated[item.factId];
    final previous = previousByType[item.type];
    final wasThisEvidence =
        previous != null &&
        answer?.provenance == TaxFactProvenance.imported &&
        answer?.value == previous.amountCents;
    if (answer == null || wasThisEvidence) {
      updated[item.factId] = TaxAnswer(
        questionId: item.factId,
        value: item.amountCents,
        provenance: TaxFactProvenance.imported,
      );
    }
  }

  if (after.any(
        (item) => item.type == GuidedDocumentType.employmentIncomeStatement,
      ) &&
      !updated.containsKey('employmentIncome')) {
    updated['employmentIncome'] = const TaxAnswer(
      questionId: 'employmentIncome',
      value: true,
      provenance: TaxFactProvenance.imported,
    );
  }
  return updated;
}
