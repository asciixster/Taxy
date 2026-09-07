import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

enum CapturedDocumentMediaType { pdf, jpeg, png }

enum CapturedDocumentState {
  captured,
  processing,
  reviewRequired,
  confirmed,
  failed,
  deleted,
}

enum TaxDocumentTypeCandidate {
  employmentStatement,
  withholdingProof,
  socialSecurityProof,
  combinedEmploymentStatement,
  unsupported,
  unknown,
}

enum TaxDocumentFieldType {
  employmentGross,
  irsWithholding,
  socialSecurityContributions,
  taxYear,
  employerName,
}

enum ExtractionConfidence { high, medium, low }

final class TaxDocumentExtractedField {
  const TaxDocumentExtractedField({
    required this.type,
    required this.normalizedCandidate,
    required this.confidence,
    this.rawCandidate,
  });

  final TaxDocumentFieldType type;
  final Object? normalizedCandidate;
  final ExtractionConfidence confidence;

  /// Kept in memory for review only. It is deliberately excluded from JSON.
  final String? rawCandidate;

  Map<String, Object?> toJson() => {
    'type': type.name,
    'normalizedCandidate': normalizedCandidate,
    'confidence': confidence.name,
  };

  factory TaxDocumentExtractedField.fromJson(Map<String, Object?> json) {
    return TaxDocumentExtractedField(
      type: TaxDocumentFieldType.values.byName(json['type'] as String),
      normalizedCandidate: json['normalizedCandidate'],
      confidence: ExtractionConfidence.values.byName(
        json['confidence'] as String,
      ),
    );
  }
}

final class TaxDocumentExtraction {
  const TaxDocumentExtraction({
    required this.documentTypeCandidate,
    required this.fields,
    required this.confidence,
    this.warnings = const [],
  });

  final TaxDocumentTypeCandidate documentTypeCandidate;
  final List<TaxDocumentExtractedField> fields;
  final ExtractionConfidence confidence;
  final List<String> warnings;

  TaxDocumentExtractedField? field(TaxDocumentFieldType type) {
    for (final field in fields) {
      if (field.type == type) return field;
    }
    return null;
  }

  Map<String, Object?> toJson() => {
    'documentTypeCandidate': documentTypeCandidate.name,
    'fields': fields.map((field) => field.toJson()).toList(),
    'confidence': confidence.name,
    // Warnings are stable machine categories, never OCR content.
    'warnings': warnings,
  };

  factory TaxDocumentExtraction.fromJson(Map<String, Object?> json) {
    final fields = json['fields'];
    if (fields is! List) throw const FormatException('extraction fields');
    return TaxDocumentExtraction(
      documentTypeCandidate: TaxDocumentTypeCandidate.values.byName(
        json['documentTypeCandidate'] as String,
      ),
      fields: fields
          .map(
            (field) => TaxDocumentExtractedField.fromJson(
              (field as Map).cast<String, Object?>(),
            ),
          )
          .toList(growable: false),
      confidence: ExtractionConfidence.values.byName(
        json['confidence'] as String,
      ),
      warnings: (json['warnings'] as List? ?? const [])
          .whereType<String>()
          .toList(growable: false),
    );
  }
}

final class CapturedTaxDocument {
  const CapturedTaxDocument({
    required this.id,
    required this.taxYear,
    required this.mediaType,
    required this.pageCount,
    required this.createdAt,
    required this.state,
    this.extraction,
  });

  final String id;
  final int taxYear;
  final CapturedDocumentMediaType mediaType;
  final int pageCount;
  final DateTime createdAt;
  final CapturedDocumentState state;
  final TaxDocumentExtraction? extraction;

  CapturedTaxDocument copyWith({
    CapturedDocumentState? state,
    TaxDocumentExtraction? extraction,
  }) => CapturedTaxDocument(
    id: id,
    taxYear: taxYear,
    mediaType: mediaType,
    pageCount: pageCount,
    createdAt: createdAt,
    state: state ?? this.state,
    extraction: extraction ?? this.extraction,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'taxYear': taxYear,
    'mediaType': mediaType.name,
    'pageCount': pageCount,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'state': state.name,
    if (extraction != null) 'extraction': extraction!.toJson(),
  };

  factory CapturedTaxDocument.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final year = json['taxYear'];
    final pageCount = json['pageCount'];
    final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
    if (id is! String ||
        !RegExp(r'^[a-f0-9]{32}$').hasMatch(id) ||
        year is! int ||
        pageCount is! int ||
        pageCount < 1 ||
        pageCount > 10 ||
        createdAt == null) {
      throw const FormatException('captured document metadata');
    }
    final extraction = json['extraction'];
    return CapturedTaxDocument(
      id: id,
      taxYear: year,
      mediaType: CapturedDocumentMediaType.values.byName(
        json['mediaType'] as String,
      ),
      pageCount: pageCount,
      createdAt: createdAt.toUtc(),
      state: CapturedDocumentState.values.byName(json['state'] as String),
      extraction: extraction is Map
          ? TaxDocumentExtraction.fromJson(extraction.cast<String, Object?>())
          : null,
    );
  }
}

abstract interface class TaxDocumentExtractor {
  TaxDocumentExtraction extract(String recognizedText);
}

/// A deliberately narrow parser for the three document facts supported by the
/// existing IRS engine. It does not infer legal meaning beyond those labels.
final class PortugueseEmploymentDocumentExtractor
    implements TaxDocumentExtractor {
  const PortugueseEmploymentDocumentExtractor();

  static final _yearPattern = RegExp(r'(?<!\d)(20\d{2})(?!\d)');

  @override
  TaxDocumentExtraction extract(String recognizedText) {
    final text = _fold(recognizedText);
    final unsupported = _containsAny(text, const [
      'recibo verde',
      'trabalho independente',
      'pensao',
      'rendimento predial',
      'renda recebida',
      'rendimento estrangeiro',
    ]);
    if (unsupported) {
      return const TaxDocumentExtraction(
        documentTypeCandidate: TaxDocumentTypeCandidate.unsupported,
        fields: [],
        confidence: ExtractionConfidence.low,
        warnings: ['unsupported_document'],
      );
    }

    final fields = <TaxDocumentExtractedField>[];
    final warnings = <String>[];
    _moneyField(
      recognizedText,
      TaxDocumentFieldType.employmentGross,
      const [
        'rendimento bruto',
        'rendimentos brutos',
        'remuneracao bruta',
        'remuneracoes',
      ],
      fields,
      warnings,
    );
    _moneyField(
      recognizedText,
      TaxDocumentFieldType.irsWithholding,
      const ['retencao de irs', 'irs retido', 'imposto retido', 'retencoes'],
      fields,
      warnings,
    );
    _moneyField(
      recognizedText,
      TaxDocumentFieldType.socialSecurityContributions,
      const [
        'seguranca social',
        'contribuicoes obrigatorias',
        'contribuicoes para a seguranca social',
      ],
      fields,
      warnings,
    );

    final years = _yearPattern
        .allMatches(recognizedText)
        .map((match) => int.parse(match.group(1)!))
        .where((year) => year >= 2000 && year <= 2100)
        .toSet();
    if (years.length == 1) {
      fields.add(
        TaxDocumentExtractedField(
          type: TaxDocumentFieldType.taxYear,
          normalizedCandidate: years.single,
          rawCandidate: years.single.toString(),
          confidence: ExtractionConfidence.high,
        ),
      );
    } else if (years.length > 1) {
      warnings.add('ambiguous_tax_year');
      fields.add(
        const TaxDocumentExtractedField(
          type: TaxDocumentFieldType.taxYear,
          normalizedCandidate: null,
          confidence: ExtractionConfidence.low,
        ),
      );
    }

    final types = fields
        .where((field) => field.normalizedCandidate != null)
        .map((field) => field.type)
        .toSet();
    final moneyCount = types
        .where((type) => type != TaxDocumentFieldType.taxYear)
        .length;
    final type = moneyCount > 1
        ? TaxDocumentTypeCandidate.combinedEmploymentStatement
        : types.contains(TaxDocumentFieldType.employmentGross)
        ? TaxDocumentTypeCandidate.employmentStatement
        : types.contains(TaxDocumentFieldType.irsWithholding)
        ? TaxDocumentTypeCandidate.withholdingProof
        : types.contains(TaxDocumentFieldType.socialSecurityContributions)
        ? TaxDocumentTypeCandidate.socialSecurityProof
        : TaxDocumentTypeCandidate.unknown;
    final confidence =
        type == TaxDocumentTypeCandidate.unknown ||
            fields.any((field) => field.confidence == ExtractionConfidence.low)
        ? ExtractionConfidence.low
        : warnings.isEmpty
        ? ExtractionConfidence.high
        : ExtractionConfidence.medium;
    if (type == TaxDocumentTypeCandidate.unknown) {
      warnings.add('unknown_document');
    }
    return TaxDocumentExtraction(
      documentTypeCandidate: type,
      fields: List.unmodifiable(fields),
      confidence: confidence,
      warnings: List.unmodifiable(warnings),
    );
  }

  void _moneyField(
    String source,
    TaxDocumentFieldType type,
    List<String> labels,
    List<TaxDocumentExtractedField> output,
    List<String> warnings,
  ) {
    final candidates = <({String raw, int cents})>[];
    for (final line in source.split(RegExp(r'[\r\n]+'))) {
      final folded = _fold(line);
      if (!_containsAny(folded, labels)) continue;
      for (final match in RegExp(
        r'(?<!\d)(\d{1,3}(?:[. ]\d{3})*(?:,\d{1,2})|\d+(?:,\d{1,2})|\d+\.\d{2})(?!\d)',
      ).allMatches(line)) {
        final raw = match.group(1)!;
        final cents = parsePortugueseMoneyCents(raw);
        if (cents != null) candidates.add((raw: raw, cents: cents));
      }
    }
    final distinct = {for (final candidate in candidates) candidate.cents};
    if (distinct.length == 1) {
      final candidate = candidates.first;
      output.add(
        TaxDocumentExtractedField(
          type: type,
          normalizedCandidate: candidate.cents,
          rawCandidate: candidate.raw,
          confidence: ExtractionConfidence.high,
        ),
      );
    } else if (distinct.length > 1) {
      warnings.add('ambiguous_${type.name}');
      output.add(
        TaxDocumentExtractedField(
          type: type,
          normalizedCandidate: null,
          confidence: ExtractionConfidence.low,
        ),
      );
    }
  }

  static bool _containsAny(String source, List<String> values) =>
      values.any((value) => source.contains(_fold(value)));

  static String _fold(String source) => source
      .toLowerCase()
      .replaceAll(RegExp('[áàâãä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[íìîï]'), 'i')
      .replaceAll(RegExp('[óòôõö]'), 'o')
      .replaceAll(RegExp('[úùûü]'), 'u')
      .replaceAll('ç', 'c');
}

int? parsePortugueseMoneyCents(String source) {
  final compact = source.trim().replaceAll(RegExp(r'\s'), '');
  if (compact.isEmpty || compact.startsWith('-')) return null;
  String euros;
  String fraction;
  if (compact.contains(',')) {
    if (!RegExp(r'^\d{1,3}(?:\.\d{3})*(?:,\d{1,2})?$|^\d+(?:,\d{1,2})?$')
        .hasMatch(compact)) {
      return null;
    }
    final parts = compact.split(',');
    euros = parts.first.replaceAll('.', '');
    fraction = parts.length == 1 ? '00' : parts.last.padRight(2, '0');
  } else if (RegExp(r'^\d+\.\d{2}$').hasMatch(compact)) {
    final parts = compact.split('.');
    euros = parts.first;
    fraction = parts.last;
  } else if (RegExp(r'^\d+$').hasMatch(compact)) {
    euros = compact;
    fraction = '00';
  } else {
    return null;
  }
  final whole = int.tryParse(euros);
  final decimal = int.tryParse(fraction);
  if (whole == null || decimal == null) return null;
  return whole * 100 + decimal;
}

abstract interface class CapturedTaxDocumentRepository {
  Future<List<CapturedTaxDocument>> load();
  Future<void> save(CapturedTaxDocument document);
  Future<void> remove(String id);
  Future<void> clearUnconfirmed();
  Future<int> purgeExpired(DateTime now);
}

final class LocalCapturedTaxDocumentRepository
    implements CapturedTaxDocumentRepository {
  static const _storage = MethodChannel('pt.taxy.app/storage');

  Future<File> _file() async {
    final directory = await _storage.invokeMethod<String>('getAppDataPath');
    if (directory == null || directory.isEmpty) {
      throw StateError('storage unavailable');
    }
    final file = File(
      '$directory${Platform.pathSeparator}captured-tax-documents-v1.json',
    );
    // A process kill can leave only the staging file behind. It is never a
    // committed repository state, so recovery fails closed by discarding it.
    final temporary = File('${file.path}.tmp');
    if (await temporary.exists()) await temporary.delete();
    return file;
  }

  @override
  Future<List<CapturedTaxDocument>> load() async {
    final file = await _file();
    if (!await file.exists()) return const [];
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map || decoded['schemaVersion'] != 1) {
      throw const FormatException('captured document schema');
    }
    return (decoded['items'] as List? ?? const [])
        .map(
          (item) => CapturedTaxDocument.fromJson(
            (item as Map).cast<String, Object?>(),
          ),
        )
        .toList(growable: false);
  }

  Future<void> _write(List<CapturedTaxDocument> values) async {
    final file = await _file();
    final temporary = File('${file.path}.tmp');
    try {
      await temporary.writeAsString(
        jsonEncode({
          'schemaVersion': 1,
          'items': values.map((item) => item.toJson()).toList(),
        }),
        flush: true,
      );
      if (await file.exists()) await file.delete();
      await temporary.rename(file.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  @override
  Future<void> save(CapturedTaxDocument document) async {
    final values = await load();
    await _write([
      ...values.where((value) => value.id != document.id),
      document,
    ]);
  }

  @override
  Future<void> remove(String id) async {
    await _write((await load()).where((value) => value.id != id).toList());
  }

  @override
  Future<void> clearUnconfirmed() async {
    await _write(
      (await load())
          .where((value) => value.state == CapturedDocumentState.confirmed)
          .toList(),
    );
  }

  @override
  Future<int> purgeExpired(DateTime now) async {
    final values = await load();
    final cutoff = now.toUtc().subtract(const Duration(hours: 24));
    final retained = values
        .where(
          (value) =>
              value.state == CapturedDocumentState.confirmed ||
              !value.createdAt.isBefore(cutoff),
        )
        .toList();
    await _write(retained);
    return values.length - retained.length;
  }
}

final class MemoryCapturedTaxDocumentRepository
    implements CapturedTaxDocumentRepository {
  final Map<String, CapturedTaxDocument> _values = {};

  @override
  Future<List<CapturedTaxDocument>> load() async =>
      List.unmodifiable(_values.values);

  @override
  Future<void> save(CapturedTaxDocument document) async {
    _values[document.id] = document;
  }

  @override
  Future<void> remove(String id) async => _values.remove(id);

  @override
  Future<void> clearUnconfirmed() async {
    _values.removeWhere(
      (_, value) => value.state != CapturedDocumentState.confirmed,
    );
  }

  @override
  Future<int> purgeExpired(DateTime now) async {
    final cutoff = now.toUtc().subtract(const Duration(hours: 24));
    final before = _values.length;
    _values.removeWhere(
      (_, value) =>
          value.state != CapturedDocumentState.confirmed &&
          value.createdAt.isBefore(cutoff),
    );
    return before - _values.length;
  }
}

final class NativeDocumentCaptureResult {
  const NativeDocumentCaptureResult({
    required this.document,
    required this.recognizedText,
  });

  final CapturedTaxDocument document;
  final String recognizedText;
}

abstract interface class TaxDocumentCaptureGateway {
  Future<NativeDocumentCaptureResult?> takePhoto(int taxYear);
  Future<NativeDocumentCaptureResult?> chooseFile(int taxYear);
  Future<Uint8List?> preview(String id);
  Future<void> delete(String id);
  Future<void> confirmAndDeleteRaw(String id);
  Future<int> cleanupExpired();
  Future<void> clearTemporary();
}

final class AndroidTaxDocumentCaptureGateway
    implements TaxDocumentCaptureGateway {
  static const _channel = MethodChannel('pt.taxy.app/document_capture');

  @override
  Future<NativeDocumentCaptureResult?> takePhoto(int taxYear) =>
      _capture('takePhoto', taxYear);

  @override
  Future<NativeDocumentCaptureResult?> chooseFile(int taxYear) =>
      _capture('chooseFile', taxYear);

  Future<NativeDocumentCaptureResult?> _capture(
    String method,
    int taxYear,
  ) async {
    final value = await _channel.invokeMapMethod<String, Object?>(method, {
      'taxYear': taxYear,
    });
    if (value == null) return null;
    final metadata = (value['document'] as Map).cast<String, Object?>();
    return NativeDocumentCaptureResult(
      document: CapturedTaxDocument.fromJson(metadata),
      recognizedText: value['recognizedText'] as String? ?? '',
    );
  }

  @override
  Future<Uint8List?> preview(String id) =>
      _channel.invokeMethod<Uint8List>('preview', {'id': id});

  @override
  Future<void> delete(String id) =>
      _channel.invokeMethod<void>('delete', {'id': id});

  @override
  Future<void> confirmAndDeleteRaw(String id) =>
      _channel.invokeMethod<void>('confirm', {'id': id});

  @override
  Future<int> cleanupExpired() async =>
      await _channel.invokeMethod<int>('cleanupExpired') ?? 0;

  @override
  Future<void> clearTemporary() =>
      _channel.invokeMethod<void>('clearTemporary');
}
