import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/l10n/app_localizations.dart';
import 'package:taxy_pt/modules/at_prefill/domain/official_prefill_evidence.dart';
import 'package:taxy_pt/modules/at_prefill/domain/official_prefill_confirmation.dart';
import 'package:taxy_pt/modules/at_prefill/infrastructure/official_prefill_backend_bridge.dart';
import 'package:taxy_pt/modules/at_prefill/screens/official_prefill_screen.dart';
import 'package:taxy_pt/guided_tax/tax_interview_models.dart';

void main() {
  Map<String, Object?> fixture() => <String, Object?>{
    'schemaVersion': 1,
    'taxYear': 2025,
    'source': 'OFFICIAL_AT_PREFILL',
    'annexes': <Object?>['A', 'C', 'H'],
    'household': <String, Object?>{'memberCount': 1},
    'categoryA': <String, Object?>{
      'rows': <Object?>[
        <String, Object?>{
          'incomeCode': '401',
          'holder': 'A',
          'grossIncomeCents': 1000000,
          'withholdingCents': 120000,
          'socialSecurityCents': 110000,
          'unionDuesCents': 0,
        },
      ],
      'totals': <String, Object?>{
        'grossIncomeCents': 1000000,
        'withholdingCents': 120000,
        'socialSecurityCents': 110000,
        'unionDuesCents': 0,
      },
      'totalsMatchOfficialSummary': true,
    },
    'categoryB': <String, Object?>{
      'present': true,
      'regime': 'ORGANIZED_ACCOUNTING',
      'incomeSubjectToWithholdingCents': null,
      'withholdingCents': 75000,
      'paymentsOnAccountCents': null,
      'investmentTaxCreditCents': null,
    },
    'candidates': <Object?>[
      <String, Object?>{
        'field': 'categoryATotals',
        'value': <String, Object?>{'grossIncomeCents': 1000000},
        'confidence': 'EXACT',
        'provenance': 'OFFICIAL_AT_PREFILL',
        'requiresUserConfirmation': true,
      },
      <String, Object?>{
        'field': 'categoryBPresent',
        'value': true,
        'confidence': 'EXACT',
        'provenance': 'OFFICIAL_AT_PREFILL',
        'requiresUserConfirmation': true,
      },
    ],
  };

  test('official prefill parses exact cents without becoming a TaxFact', () {
    final evidence = OfficialPrefillEvidence.fromJson(fixture());
    expect(evidence.taxYear, 2025);
    expect(evidence.annexes, {'A', 'C', 'H'});
    expect(evidence.categoryATotals.grossIncomeCents, 1000000);
    expect(evidence.categoryB?.withholdingCents, 75000);
    expect(evidence.candidateFields, {'categoryATotals', 'categoryBPresent'});
    expect(evidence.runtimeType.toString(), isNot(contains('TaxFact')));
  });

  test('response containing a taxpayer identifier fails closed', () {
    final value = fixture();
    (value['household']! as Map<String, Object?>)['nif'] = '999999990';
    expect(
      () => OfficialPrefillEvidence.fromJson(value),
      throwsFormatException,
    );
  });

  test('one-cent aggregate mismatch fails closed', () {
    final value = fixture();
    final categoryA = value['categoryA']! as Map<String, Object?>;
    final totals = categoryA['totals']! as Map<String, Object?>;
    totals['grossIncomeCents'] = 1000001;
    expect(
      () => OfficialPrefillEvidence.fromJson(value),
      throwsFormatException,
    );
  });

  test('backend gateway uses only the read-only prefill route', () async {
    final transport = _Transport(fixture());
    final gateway = BackendOfficialPrefillGateway(
      baseUri: Uri.parse('https://api.taxy.pt/'),
      transport: transport,
    );
    final evidence = await gateway.load(
      credentials: const OfficialPrefillCredentials(
        nif: '999999990',
        password: 'synthetic',
      ),
      taxYear: 2025,
    );
    expect(evidence.taxYear, 2025);
    expect(transport.uri.path, '/v1/irs/prefill');
    expect(transport.calls, 1);
  });

  test(
    'official prefill is enabled after the read-only backend deployment',
    () {
      expect(officialAtPrefillEnabled, isTrue);
    },
  );

  test('official evidence changes no answer before explicit confirmation', () {
    final current = <String, TaxAnswer>{
      'withholdingCents': const TaxAnswer(
        questionId: 'withholdingCents',
        value: 1,
      ),
    };
    final evidence = OfficialPrefillEvidence.fromJson(fixture());
    final result = applyOfficialPrefillConfirmation(
      current: current,
      taxYear: 2025,
      confirmation: OfficialPrefillConfirmation(
        taxYear: 2025,
        fields: const {},
        evidence: evidence,
      ),
    );
    expect(result['withholdingCents']?.value, 1);
    expect(result, isNot(contains('employmentGrossCents')));
  });

  test(
    'only explicitly selected official fields become current-year answers',
    () {
      final evidence = OfficialPrefillEvidence.fromJson(fixture());
      final result = applyOfficialPrefillConfirmation(
        current: const {},
        taxYear: 2025,
        confirmation: OfficialPrefillConfirmation(
          taxYear: 2025,
          fields: const {
            OfficialPrefillField.employmentGross,
            OfficialPrefillField.selfEmploymentPresence,
          },
          evidence: evidence,
        ),
      );
      expect(result['employmentIncome']?.value, isTrue);
      expect(result['employmentGrossCents']?.value, 1000000);
      expect(result['selfEmploymentIncome']?.value, isTrue);
      expect(result, isNot(contains('withholdingCents')));
      expect(
        result.values.every(
          (answer) => answer.provenance == TaxFactProvenance.official,
        ),
        isTrue,
      );
    },
  );

  testWidgets('review requires selection before confirmation', (tester) async {
    final evidence = OfficialPrefillEvidence.fromJson(fixture());
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OfficialPrefillScreen(taxYear: 2025, gateway: _Gateway(evidence)),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('official-prefill-nif')),
      '999999990',
    );
    await tester.enterText(
      find.byKey(const Key('official-prefill-password')),
      'synthetic',
    );
    await tester.tap(find.byKey(const Key('official-prefill-load')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('official-prefill-confirm')),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('official-prefill-employmentGross')));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('official-prefill-confirm')),
          )
          .onPressed,
      isNotNull,
    );
  });
}

final class _Transport implements OfficialPrefillTransport {
  _Transport(this.prefill);
  final Map<String, Object?> prefill;
  int calls = 0;
  late Uri uri;

  @override
  Future<OfficialPrefillResponse> post(
    Uri uri,
    Map<String, Object?> body,
  ) async {
    calls += 1;
    this.uri = uri;
    return OfficialPrefillResponse(200, <String, Object?>{'prefill': prefill});
  }
}

final class _Gateway implements OfficialPrefillGateway {
  const _Gateway(this.evidence);
  final OfficialPrefillEvidence evidence;

  @override
  Future<OfficialPrefillEvidence> load({
    required OfficialPrefillCredentials credentials,
    required int taxYear,
  }) async => evidence;
}
