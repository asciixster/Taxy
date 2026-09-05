import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/guided_tax/document_evidence.dart';
import 'package:taxy_pt/guided_tax/document_evidence_screen.dart';
import 'package:taxy_pt/guided_tax/secure_document_capture.dart';
import 'package:taxy_pt/guided_tax/tax_interview_models.dart';
import 'package:taxy_pt/l10n/app_localizations.dart';

void main() {
  test('document evidence is tax-year scoped and stores no file reference', () {
    final evidence = GuidedDocumentEvidence(
      type: GuidedDocumentType.employmentIncomeStatement,
      taxYear: 2026,
      amountCents: 123456,
      confirmedAt: DateTime.utc(2026, 9, 5),
    );
    final json = evidence.toJson();
    expect(json['taxYear'], 2026);
    expect(json['amountCents'], 123456);
    expect(json, isNot(contains('path')));
    expect(json, isNot(contains('file')));
    expect(
      GuidedDocumentEvidence.fromJson(json).factId,
      'employmentGrossCents',
    );
  });

  test('malformed or negative document evidence fails closed', () {
    expect(
      () => GuidedDocumentEvidence.fromJson({
        'type': 'withholdingProof',
        'taxYear': 2026,
        'amountCents': -1,
        'confirmedAt': '2026-09-05T00:00:00Z',
      }),
      throwsFormatException,
    );
  });

  test('repository upserts per type and isolates fiscal years', () async {
    final repository = MemoryGuidedDocumentEvidenceRepository();
    Future<void> save(int year, int cents) => repository.save(
      GuidedDocumentEvidence(
        type: GuidedDocumentType.withholdingProof,
        taxYear: year,
        amountCents: cents,
        confirmedAt: DateTime.utc(year, 1, 1),
      ),
    );

    await save(2025, 100);
    await save(2026, 200);
    await save(2026, 300);
    expect((await repository.load(2025)).single.amountCents, 100);
    expect((await repository.load(2026)).single.amountCents, 300);
    await repository.remove(2026, GuidedDocumentType.withholdingProof);
    expect(await repository.load(2026), isEmpty);
    expect(await repository.load(2025), hasLength(1));
  });

  test(
    'evidence reconciliation updates its import but never a user answer',
    () {
      final oldEvidence = GuidedDocumentEvidence(
        type: GuidedDocumentType.withholdingProof,
        taxYear: 2026,
        amountCents: 100,
        confirmedAt: DateTime.utc(2026, 1, 1),
      );
      final newEvidence = GuidedDocumentEvidence(
        type: GuidedDocumentType.withholdingProof,
        taxYear: 2026,
        amountCents: 200,
        confirmedAt: DateTime.utc(2026, 2, 1),
      );
      final imported = reconcileDocumentEvidenceAnswers(
        current: const {
          'withholdingCents': TaxAnswer(
            questionId: 'withholdingCents',
            value: 100,
            provenance: TaxFactProvenance.imported,
          ),
        },
        before: [oldEvidence],
        after: [newEvidence],
      );
      expect(imported['withholdingCents']?.value, 200);

      final userEntered = reconcileDocumentEvidenceAnswers(
        current: const {
          'withholdingCents': TaxAnswer(
            questionId: 'withholdingCents',
            value: 150,
          ),
        },
        before: [oldEvidence],
        after: [newEvidence],
      );
      expect(userEntered['withholdingCents']?.value, 150);
    },
  );

  test('removing evidence removes only its matching imported answer', () {
    final evidence = GuidedDocumentEvidence(
      type: GuidedDocumentType.socialSecurityProof,
      taxYear: 2026,
      amountCents: 330000,
      confirmedAt: DateTime.utc(2026, 1, 1),
    );
    final result = reconcileDocumentEvidenceAnswers(
      current: const {
        'socialSecurityCents': TaxAnswer(
          questionId: 'socialSecurityCents',
          value: 330000,
          provenance: TaxFactProvenance.imported,
        ),
      },
      before: [evidence],
      after: const [],
    );
    expect(result, isNot(contains('socialSecurityCents')));
  });

  testWidgets('confirmed document amount is explicit and local-only', (
    tester,
  ) async {
    final repository = MemoryGuidedDocumentEvidenceRepository();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DocumentEvidenceScreen(
          taxYear: 2026,
          repository: repository,
          captureRepository: MemoryCapturedTaxDocumentRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('processed on this device'), findsOneWidget);
    await tester.tap(find.text('Employment income statement'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '1234.56');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final stored = await repository.load(2026);
    expect(stored.single.amountCents, 123456);
    expect(find.textContaining('Confirmed:'), findsOneWidget);
  });

  testWidgets('document evidence remains usable at 200% on a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'PT'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DocumentEvidenceScreen(
          taxYear: 2026,
          repository: MemoryGuidedDocumentEvidenceRepository(),
          captureRepository: MemoryCapturedTaxDocumentRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Evidência documental'), findsOneWidget);
  });
}
