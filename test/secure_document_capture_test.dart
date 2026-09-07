import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/guided_tax/document_evidence.dart';
import 'package:taxy_pt/guided_tax/document_evidence_screen.dart';
import 'package:taxy_pt/guided_tax/document_extraction_review_screen.dart';
import 'package:taxy_pt/guided_tax/secure_document_capture.dart';
import 'package:taxy_pt/l10n/app_localizations.dart';

void main() {
  const extractor = PortugueseEmploymentDocumentExtractor();

  group('Portuguese document extraction', () {
    test('parses supported European money formats to integer cents', () {
      expect(parsePortugueseMoneyCents('1.234,56'), 123456);
      expect(parsePortugueseMoneyCents('1234,56'), 123456);
      expect(parsePortugueseMoneyCents('1 234,56'), 123456);
      expect(parsePortugueseMoneyCents('1234.56'), 123456);
      expect(parsePortugueseMoneyCents('1.234'), isNull);
      expect(parsePortugueseMoneyCents('-1,00'), isNull);
    });

    test('extracts only supported annual employment fields', () {
      final result = extractor.extract('''
        Declaração anual de rendimentos 2026
        Rendimentos brutos: 24.500,00 EUR
        Retenção de IRS: 3.200,00 EUR
        Contribuições para a Segurança Social: 2.695,00 EUR
      ''');
      expect(
        result.documentTypeCandidate,
        TaxDocumentTypeCandidate.combinedEmploymentStatement,
      );
      expect(
        result.field(TaxDocumentFieldType.employmentGross)?.normalizedCandidate,
        2450000,
      );
      expect(
        result.field(TaxDocumentFieldType.irsWithholding)?.normalizedCandidate,
        320000,
      );
      expect(
        result
            .field(TaxDocumentFieldType.socialSecurityContributions)
            ?.normalizedCandidate,
        269500,
      );
      expect(
        result.field(TaxDocumentFieldType.taxYear)?.normalizedCandidate,
        2026,
      );
    });

    test('ambiguous amount fails closed instead of selecting a value', () {
      final result = extractor.extract('''
        Retenção de IRS: 1.200,00
        Total retenções: 1.350,00
      ''');
      final field = result.field(TaxDocumentFieldType.irsWithholding);
      expect(field?.normalizedCandidate, isNull);
      expect(field?.confidence, ExtractionConfidence.low);
      expect(result.warnings, contains('ambiguous_irsWithholding'));
    });

    test(
      'unsupported income is identified but no fiscal value is extracted',
      () {
        final result = extractor.extract(
          'Recibo verde 2026 rendimento bruto 12.000,00',
        );
        expect(
          result.documentTypeCandidate,
          TaxDocumentTypeCandidate.unsupported,
        );
        expect(result.fields, isEmpty);
      },
    );

    test('missing withholding remains absent', () {
      final result = extractor.extract(
        'Declaração de rendimentos 2026\nRendimento bruto: 20.000,00',
      );
      expect(result.field(TaxDocumentFieldType.employmentGross), isNotNull);
      expect(result.field(TaxDocumentFieldType.irsWithholding), isNull);
    });
  });

  test(
    'candidate serialization persists no OCR text, path or original name',
    () {
      const field = TaxDocumentExtractedField(
        type: TaxDocumentFieldType.irsWithholding,
        normalizedCandidate: 320000,
        rawCandidate: 'sensitive raw candidate',
        confidence: ExtractionConfidence.high,
      );
      final document = CapturedTaxDocument(
        id: '0123456789abcdef0123456789abcdef',
        taxYear: 2026,
        mediaType: CapturedDocumentMediaType.pdf,
        pageCount: 1,
        createdAt: DateTime.utc(2026, 9, 5),
        state: CapturedDocumentState.reviewRequired,
        extraction: const TaxDocumentExtraction(
          documentTypeCandidate: TaxDocumentTypeCandidate.withholdingProof,
          fields: [field],
          confidence: ExtractionConfidence.high,
        ),
      );
      final encoded = jsonEncode(document.toJson());
      expect(encoded, isNot(contains('sensitive raw candidate')));
      expect(encoded, isNot(contains('recognizedText')));
      expect(encoded, isNot(contains('filename')));
      expect(encoded, isNot(contains('path')));
      expect(encoded, isNot(contains('bytes')));
    },
  );

  test(
    'temporary candidate never becomes evidence without confirmation',
    () async {
      final evidence = MemoryGuidedDocumentEvidenceRepository();
      final captures = MemoryCapturedTaxDocumentRepository();
      await captures.save(
        CapturedTaxDocument(
          id: '0123456789abcdef0123456789abcdef',
          taxYear: 2026,
          mediaType: CapturedDocumentMediaType.jpeg,
          pageCount: 1,
          createdAt: DateTime.utc(2026, 9, 5),
          state: CapturedDocumentState.reviewRequired,
          extraction: const TaxDocumentExtraction(
            documentTypeCandidate: TaxDocumentTypeCandidate.withholdingProof,
            fields: [
              TaxDocumentExtractedField(
                type: TaxDocumentFieldType.irsWithholding,
                normalizedCandidate: 320000,
                confidence: ExtractionConfidence.high,
              ),
            ],
            confidence: ExtractionConfidence.high,
          ),
        ),
      );
      expect(await evidence.load(2026), isEmpty);
    },
  );

  test('TTL cleanup removes only expired unconfirmed captures', () async {
    final repository = MemoryCapturedTaxDocumentRepository();
    CapturedTaxDocument captured(
      String id,
      DateTime createdAt, {
      bool confirmed = false,
    }) => CapturedTaxDocument(
      id: id,
      taxYear: 2026,
      mediaType: CapturedDocumentMediaType.jpeg,
      pageCount: 1,
      createdAt: createdAt,
      state: confirmed
          ? CapturedDocumentState.confirmed
          : CapturedDocumentState.reviewRequired,
    );
    await repository.save(
      captured('00000000000000000000000000000000', DateTime.utc(2026, 9, 3)),
    );
    await repository.save(
      captured('11111111111111111111111111111111', DateTime.utc(2026, 9, 5)),
    );
    await repository.save(
      captured(
        '22222222222222222222222222222222',
        DateTime.utc(2026, 9, 3),
        confirmed: true,
      ),
    );
    expect(await repository.purgeExpired(DateTime.utc(2026, 9, 5, 1)), 1);
    expect((await repository.load()).map((item) => item.id), hasLength(2));
  });

  test(
    'restart cleanup removes interrupted state but never confirmed state',
    () async {
      final repository = MemoryCapturedTaxDocumentRepository();
      await repository.save(_capturedDocument());
      await repository.save(
        _capturedDocument(
          id: '11111111111111111111111111111111',
          state: CapturedDocumentState.confirmed,
        ),
      );
      await repository.clearUnconfirmed();
      final restored = await repository.load();
      expect(restored, hasLength(1));
      expect(restored.single.state, CapturedDocumentState.confirmed);
    },
  );

  test('malicious and malformed persisted metadata fails closed', () {
    Map<String, Object?> metadata(String id) => {
      ..._capturedDocument().toJson(),
      'id': id,
    };
    for (final id in [
      '../document',
      '/absolute/path',
      r'..\document',
      'abc∕def',
      List.filled(4096, 'a').join(),
    ]) {
      expect(
        () => CapturedTaxDocument.fromJson(metadata(id)),
        throwsFormatException,
      );
    }
    expect(
      () => CapturedTaxDocument.fromJson({
        ...metadata('0123456789abcdef0123456789abcdef'),
        'pageCount': 11,
      }),
      throwsFormatException,
    );
  });

  test('Android boundary is local, encrypted, bounded and permission-minimal', () {
    final native = File(
      'android/app/src/main/kotlin/pt/taxy/app/SecureDocumentCaptureBridge.kt',
    ).readAsStringSync();
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(native, contains('AES/GCM/NoPadding'));
    expect(native, contains('AndroidKeyStore'));
    expect(native, contains('MAX_BYTES = 10 * 1024 * 1024'));
    expect(native, contains('MAX_PAGES = 10'));
    expect(native, contains('TEMP_TTL_MS = 24L'));
    expect(native, contains('Re-encoding deliberately strips EXIF'));
    expect(native, contains('ExifInterface.TAG_ORIENTATION'));
    expect(native, contains('bitmap.eraseColor(Color.WHITE)'));
    expect(native, contains('pending?.cameraFile?.delete()'));
    expect(native, contains('request.cameraFile?.delete()'));
    expect(native, contains('MIME_MISMATCH'));
    expect(native, contains('UNSUPPORTED_FILE'));
    expect(native, contains('FILE_TOO_LARGE'));
    expect(native, contains('PAGE_LIMIT'));
    expect(native, isNot(contains('Log.')));
    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:exported="false"'));
    expect(manifest, isNot(contains('MANAGE_EXTERNAL_STORAGE')));
    expect(manifest, isNot(contains('READ_EXTERNAL_STORAGE')));
    expect(manifest, isNot(contains('android.permission.CAMERA')));
  });

  testWidgets('partial confirmation stores only selected corrected fields', (
    tester,
  ) async {
    final gateway = _FakeCaptureGateway();
    final captures = MemoryCapturedTaxDocumentRepository();
    final evidence = MemoryGuidedDocumentEvidenceRepository();
    await captures.save(_capturedDocument());
    await _pumpReview(tester, gateway, captures, evidence);

    final withholding = find.byKey(
      const Key('document-field-irsWithholding-select'),
    );
    await _scrollTo(tester, withholding);
    await tester.tap(withholding);
    final socialField = find.byKey(
      const Key('document-field-socialSecurityContributions-input'),
    );
    await _scrollTo(tester, socialField);
    await tester.enterText(socialField, '2600,00');
    await _tapReviewConfirm(tester);

    final confirmed = await evidence.load(2026);
    expect(confirmed, hasLength(2));
    expect(
      confirmed.any((item) => item.type == GuidedDocumentType.withholdingProof),
      isFalse,
    );
    expect(
      confirmed
          .singleWhere(
            (item) => item.type == GuidedDocumentType.socialSecurityProof,
          )
          .amountCents,
      260000,
    );
    expect(await captures.load(), isEmpty);
    expect(gateway.deletedRaw, isTrue);
  });

  testWidgets('wrong-year document cannot create current-year evidence', (
    tester,
  ) async {
    final gateway = _FakeCaptureGateway(documentYear: 2025);
    final captures = MemoryCapturedTaxDocumentRepository();
    final evidence = MemoryGuidedDocumentEvidenceRepository();
    await _pumpReview(tester, gateway, captures, evidence);
    await _scrollTo(tester, find.byKey(const Key('document-review-confirm')));
    expect(
      find.textContaining('Este documento parece ser de 2025'),
      findsOneWidget,
    );
    final confirm = tester.widget<FilledButton>(
      find.byKey(const Key('document-review-confirm')),
    );
    expect(confirm.onPressed, isNull);
    expect(await evidence.load(2026), isEmpty);
  });

  testWidgets('failed raw deletion rolls confirmed evidence back', (
    tester,
  ) async {
    final gateway = _FakeCaptureGateway(failConfirm: true);
    final captures = MemoryCapturedTaxDocumentRepository();
    final evidence = MemoryGuidedDocumentEvidenceRepository();
    await captures.save(_capturedDocument());
    await _pumpReview(tester, gateway, captures, evidence);
    await _tapReviewConfirm(tester);
    expect(await evidence.load(2026), isEmpty);
    expect(await captures.load(), hasLength(1));
    expect(
      find.text('Não conseguimos ler este documento com segurança.'),
      findsOneWidget,
    );
  });

  testWidgets('delete action removes raw and candidate metadata', (
    tester,
  ) async {
    final gateway = _FakeCaptureGateway();
    final captures = MemoryCapturedTaxDocumentRepository();
    final evidence = MemoryGuidedDocumentEvidenceRepository();
    await captures.save(_capturedDocument());
    await _pumpReview(tester, gateway, captures, evidence);
    await tester.tap(find.byTooltip('Eliminar documento'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar documento'));
    await tester.pumpAndSettle();
    expect(gateway.deletedRaw, isTrue);
    expect(await captures.load(), isEmpty);
    expect(await evidence.load(2026), isEmpty);
  });

  testWidgets('review is accessible at 200% text in dark mode', (tester) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pumpReview(
      tester,
      _FakeCaptureGateway(),
      MemoryCapturedTaxDocumentRepository(),
      MemoryGuidedDocumentEvidenceRepository(),
      themeMode: ThemeMode.dark,
    );
    expect(tester.takeException(), isNull);
    final employmentSemantics = find.byKey(
      const Key('document-field-employmentGross-semantics'),
    );
    await _scrollTo(tester, employmentSemantics);
    expect(
      tester.getSemantics(employmentSemantics).label,
      contains('Rendimentos do trabalho'),
    );
    final confirm = find.byKey(const Key('document-review-confirm'));
    await _scrollTo(tester, confirm);
    expect(confirm, findsOneWidget);
    semantics.dispose();
  });

  testWidgets('capture to explicit review to confirmation deletes raw', (
    tester,
  ) async {
    final gateway = _FakeCaptureGateway();
    final captures = MemoryCapturedTaxDocumentRepository();
    final evidence = MemoryGuidedDocumentEvidenceRepository();
    tester.view.physicalSize = const Size(640, 1280);
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'PT'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: DocumentEvidenceScreen(
          taxYear: 2026,
          repository: evidence,
          captureGateway: gateway,
          captureRepository: captures,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('document-capture-file')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('document-capture-file')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('document-capture-file')));
    await tester.pumpAndSettle();
    expect(find.text('Encontrámos estes valores'), findsWidgets);
    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    for (
      var i = 0;
      i < 12 &&
          find.byKey(const Key('document-review-confirm')).evaluate().isEmpty;
      i++
    ) {
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(
      find.byKey(const Key('document-review-confirm')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('document-review-confirm')));
    await tester.pumpAndSettle();
    expect(gateway.confirmed, isTrue);
    expect(gateway.deletedRaw, isTrue);
    expect(await captures.load(), isEmpty);
    final confirmed = await evidence.load(2026);
    expect(confirmed, hasLength(3));
  });

  testWidgets('a native processing failure remains visible after reload', (
    tester,
  ) async {
    final evidence = MemoryGuidedDocumentEvidenceRepository();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'PT'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: DocumentEvidenceScreen(
          taxYear: 2026,
          repository: evidence,
          captureGateway: const _FailingCaptureGateway('PROCESSING_FAILED'),
          captureRepository: MemoryCapturedTaxDocumentRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('document-capture-file')));
    await tester.pumpAndSettle();

    expect(
      find.text('Não conseguimos ler este documento com segurança.'),
      findsOneWidget,
    );
    expect(find.text('Introduzir valores manualmente'), findsOneWidget);
  });
}

CapturedTaxDocument _capturedDocument({
  String id = '0123456789abcdef0123456789abcdef',
  CapturedDocumentState state = CapturedDocumentState.reviewRequired,
  int documentYear = 2026,
}) => CapturedTaxDocument(
  id: id,
  taxYear: 2026,
  mediaType: CapturedDocumentMediaType.jpeg,
  pageCount: 1,
  createdAt: DateTime.utc(2026, 9, 5),
  state: state,
  extraction: TaxDocumentExtraction(
    documentTypeCandidate: TaxDocumentTypeCandidate.combinedEmploymentStatement,
    fields: [
      const TaxDocumentExtractedField(
        type: TaxDocumentFieldType.employmentGross,
        normalizedCandidate: 2450000,
        confidence: ExtractionConfidence.high,
      ),
      const TaxDocumentExtractedField(
        type: TaxDocumentFieldType.irsWithholding,
        normalizedCandidate: 320000,
        confidence: ExtractionConfidence.high,
      ),
      const TaxDocumentExtractedField(
        type: TaxDocumentFieldType.socialSecurityContributions,
        normalizedCandidate: 269500,
        confidence: ExtractionConfidence.high,
      ),
      TaxDocumentExtractedField(
        type: TaxDocumentFieldType.taxYear,
        normalizedCandidate: documentYear,
        confidence: ExtractionConfidence.high,
      ),
    ],
    confidence: ExtractionConfidence.high,
  ),
);

Future<void> _pumpReview(
  WidgetTester tester,
  _FakeCaptureGateway gateway,
  CapturedTaxDocumentRepository captures,
  GuidedDocumentEvidenceRepository evidence, {
  ThemeMode themeMode = ThemeMode.light,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt', 'PT'),
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: DocumentExtractionReviewScreen(
        document: _capturedDocument(documentYear: gateway.documentYear),
        captureGateway: gateway,
        captureRepository: captures,
        evidenceRepository: evidence,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapReviewConfirm(WidgetTester tester) async {
  final button = find.byKey(const Key('document-review-confirm'));
  await _scrollTo(tester, button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

final class _FakeCaptureGateway implements TaxDocumentCaptureGateway {
  _FakeCaptureGateway({this.documentYear = 2026, this.failConfirm = false});

  final int documentYear;
  final bool failConfirm;
  bool confirmed = false;
  bool deletedRaw = false;

  NativeDocumentCaptureResult _result() => NativeDocumentCaptureResult(
    document: _capturedDocument(documentYear: documentYear),
    recognizedText: '''
      Declaração anual de rendimentos 2026
      Rendimentos brutos: 24.500,00
      Retenção de IRS: 3.200,00
      Segurança Social: 2.695,00
    ''',
  );

  @override
  Future<NativeDocumentCaptureResult?> chooseFile(int taxYear) async =>
      _result();

  @override
  Future<NativeDocumentCaptureResult?> takePhoto(int taxYear) async =>
      _result();

  @override
  Future<Uint8List?> preview(String id) async => null;

  @override
  Future<void> confirmAndDeleteRaw(String id) async {
    if (failConfirm) throw StateError('sanitized confirmation failure');
    confirmed = true;
    deletedRaw = true;
  }

  @override
  Future<void> delete(String id) async => deletedRaw = true;

  @override
  Future<int> cleanupExpired() async => 0;

  @override
  Future<void> clearTemporary() async => deletedRaw = true;
}

final class _FailingCaptureGateway implements TaxDocumentCaptureGateway {
  const _FailingCaptureGateway(this.code);

  final String code;

  Future<NativeDocumentCaptureResult?> _fail() async =>
      throw PlatformException(code: code);

  @override
  Future<NativeDocumentCaptureResult?> chooseFile(int taxYear) => _fail();

  @override
  Future<NativeDocumentCaptureResult?> takePhoto(int taxYear) => _fail();

  @override
  Future<Uint8List?> preview(String id) async => null;

  @override
  Future<void> confirmAndDeleteRaw(String id) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<int> cleanupExpired() async => 0;

  @override
  Future<int> clearTemporary() async => 0;
}
