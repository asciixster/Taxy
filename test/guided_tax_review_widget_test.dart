import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/domain/models.dart';
import 'package:taxy_pt/fiscal_data/fiscal_evidence_repository.dart';
import 'package:taxy_pt/guided_tax/document_evidence.dart';
import 'package:taxy_pt/guided_tax/guided_tax_providers.dart';
import 'package:taxy_pt/guided_tax/guided_tax_review_screen.dart';
import 'package:taxy_pt/guided_tax/tax_interview_models.dart';
import 'package:taxy_pt/guided_tax/tax_interview_repository.dart';
import 'package:taxy_pt/l10n/app_localizations.dart';
import 'package:taxy_pt/product/product_models.dart';
import 'package:taxy_pt/product/product_repository.dart';
import 'package:taxy_pt/state/providers.dart';
import 'package:taxy_pt/tax_engine/tax_rules.dart';

void main() {
  final interview = TaxInterview(
    taxYear: 2026,
    completed: true,
    answers: const {
      'residentPortugal': TaxAnswer(
        questionId: 'residentPortugal',
        value: true,
      ),
      'region': TaxAnswer(questionId: 'region', value: 'continent'),
      'age': TaxAnswer(questionId: 'age', value: 35),
      'civilStatus': TaxAnswer(questionId: 'civilStatus', value: 'single'),
      'dependentCount': TaxAnswer(questionId: 'dependentCount', value: 0),
      'employmentIncome': TaxAnswer(
        questionId: 'employmentIncome',
        value: true,
      ),
      'employmentGrossCents': TaxAnswer(
        questionId: 'employmentGrossCents',
        value: 3200000,
      ),
      'selfEmploymentIncome': TaxAnswer(
        questionId: 'selfEmploymentIncome',
        value: false,
      ),
      'pensionIncome': TaxAnswer(questionId: 'pensionIncome', value: false),
      'foreignIncome': TaxAnswer(questionId: 'foreignIncome', value: false),
      'rentalIncome': TaxAnswer(questionId: 'rentalIncome', value: false),
      'expensesReviewed': TaxAnswer(
        questionId: 'expensesReviewed',
        value: true,
      ),
      'withholdingCents': TaxAnswer(
        questionId: 'withholdingCents',
        value: 420000,
      ),
      'socialSecurityCents': TaxAnswer(
        questionId: 'socialSecurityCents',
        value: 352000,
      ),
      'reviewConfirmed': TaxAnswer(questionId: 'reviewConfirmed', value: true),
    },
  );
  final product = ProductState(
    profile: const FiscalProfile(
      activeTaxYear: 2026,
      region: TaxRegion.continent,
      civilStatus: CivilStatus.single,
      dependentCount: 0,
      hasEmployment: true,
      hasSelfEmployment: false,
    ),
  );

  Future<void> pumpReview(
    WidgetTester tester, {
    required Locale locale,
    ThemeData? theme,
    double textScale = 1,
    TaxInterview? reviewInterview,
    ProductState? reviewProduct,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(
            MemoryProductRepository(reviewProduct ?? product),
          ),
          taxInterviewRepositoryProvider.overrideWithValue(
            MemoryTaxInterviewRepository(),
          ),
          documentEvidenceRepositoryProvider.overrideWithValue(
            MemoryGuidedDocumentEvidenceRepository(),
          ),
          fiscalEvidenceRepositoryProvider.overrideWithValue(
            MemoryFiscalEvidenceRepository(),
          ),
          taxRuleRepositoryProvider.overrideWithValue(
            TaxRuleRepository((path) => File(path).readAsString()),
          ),
        ],
        child: MaterialApp(
          key: ValueKey(
            '${locale.toLanguageTag()}-'
            '${reviewInterview?.answers['civilStatus']?.value}-'
            '${reviewInterview?.answers['selfEmploymentIncome']?.value}-'
            '${reviewInterview?.answers.length}',
          ),
          locale: locale,
          theme: theme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: GuidedTaxReviewScreen(
            taxYear: 2026,
            interview: reviewInterview ?? interview,
          ),
        ),
      ),
    );
    await tester.pump();
    for (var index = 0; index < 10; index++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('PT review fits a 320x640 phone at 200% text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpReview(tester, locale: const Locale('pt', 'PT'), textScale: 2);
    expect(find.text('Revisão fiscal'), findsOneWidget);
    expect(find.text('Estimativa de IRS'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('O que está incluído nesta estimativa'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('O que está incluído nesta estimativa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English review uses natural copy in dark mode', (tester) async {
    await pumpReview(
      tester,
      locale: const Locale('en'),
      theme: ThemeData.dark(),
    );
    expect(find.text('Tax review'), findsOneWidget);
    expect(find.text('IRS estimate'), findsOneWidget);
    expect(find.text('Ready to review'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing information and conflicts have human review states', (
    tester,
  ) async {
    final incompleteAnswers = Map<String, TaxAnswer>.from(interview.answers)
      ..remove('withholdingCents');
    await pumpReview(
      tester,
      locale: const Locale('en'),
      reviewInterview: interview.copyWith(answers: incompleteAnswers),
    );
    expect(find.text('Information is missing'), findsWidgets);

    final conflictAnswers = Map<String, TaxAnswer>.from(interview.answers)
      ..['civilStatus'] = const TaxAnswer(
        questionId: 'civilStatus',
        value: 'married',
      );
    await pumpReview(
      tester,
      locale: const Locale('en'),
      reviewInterview: interview.copyWith(answers: conflictAnswers),
    );
    expect(find.text('Information to confirm'), findsOneWidget);
    expect(find.text('Needs your review'), findsOneWidget);
  });

  testWidgets('unsupported income is visibly excluded', (tester) async {
    final answers = Map<String, TaxAnswer>.from(interview.answers)
      ..['selfEmploymentIncome'] = const TaxAnswer(
        questionId: 'selfEmploymentIncome',
        value: true,
      );
    final matchingProduct = ProductState(
      profile: const FiscalProfile(
        activeTaxYear: 2026,
        region: TaxRegion.continent,
        civilStatus: CivilStatus.single,
        dependentCount: 0,
        hasEmployment: true,
        hasSelfEmployment: true,
      ),
    );
    await pumpReview(
      tester,
      locale: const Locale('en'),
      reviewInterview: interview.copyWith(answers: answers),
      reviewProduct: matchingProduct,
    );
    expect(find.text('Not included in the current estimate'), findsWidgets);
    expect(find.text('Estimate not available yet'), findsOneWidget);
  });
}
