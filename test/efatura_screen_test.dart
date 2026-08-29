import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/modules/efatura/application/efatura_read_only_service.dart';
import 'package:taxy_pt/modules/efatura/domain/efatura_models.dart';
import 'package:taxy_pt/modules/efatura/infrastructure/efatura_runtime_bridge.dart';
import 'package:taxy_pt/modules/efatura/screens/efatura_screen.dart';
import 'package:taxy_pt/l10n/app_localizations.dart';

void main() {
  const sector = AtExpenseSector(
    code: 'C05',
    label: 'Saúde',
    provisionalBenefitCents: 250,
  );
  const overview = EfaturaOverview(
    provisionalBenefitCents: 1200,
    pendingValidation: 0,
    pendingRevenueAssociation: 0,
    sectors: [sector],
  );
  const invoice = EfaturaInvoice(
    date: '2026-08-29',
    totalCents: 2345,
    issuerDisplayName: 'Emitente sintético',
    sectorCode: 'C05',
    sectorLabel: 'Saúde',
  );

  testWidgets('mostra loading e badge experimental', (tester) async {
    final completer = Completer<EfaturaOverview>();
    await _pump(tester, _DeferredGateway(completer.future), _readyStore());
    await tester.pump();
    expect(find.byKey(const Key('efatura-loading')), findsOneWidget);
    expect(find.text('Experimental'), findsOneWidget);
  });
  testWidgets('mostra overview ligado e empty pending', (tester) async {
    await _pump(tester, _FakeGateway(overview: overview), _readyStore());
    await tester.pumpAndSettle();
    expect(find.text('Resumo e-Fatura'), findsOneWidget);
    expect(find.text('Benefício provisório'), findsOneWidget);
    expect(find.textContaining('12,00'), findsOneWidget);
    expect(find.text('Sem faturas por validar'), findsOneWidget);
  });
  testWidgets('mostra setores sem inventar contagem', (tester) async {
    await _pump(tester, _FakeGateway(overview: overview), _readyStore());
    await tester.pumpAndSettle();
    expect(find.text('Saúde'), findsOneWidget);
    expect(find.textContaining('2,50'), findsOneWidget);
    expect(find.textContaining('faturas no setor'), findsNothing);
  });
  testWidgets('mostra invoice sintética sem identificadores técnicos', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeGateway(overview: overview, sectorInvoices: const [invoice]),
      _readyStore(),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('sector-C05')), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sector-C05')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Emitente sintético'), 250);
    expect(find.text('Emitente sintético'), findsOneWidget);
    expect(find.textContaining('23,45'), findsOneWidget);
    expect(find.textContaining('IdDocumento'), findsNothing);
    expect(find.textContaining('NIF'), findsNothing);
  });
  testWidgets('mostra empty state de setor', (tester) async {
    await _pump(tester, _FakeGateway(overview: overview), _readyStore());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('sector-C05')), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sector-C05')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Sem faturas neste setor'), 250);
    expect(find.text('Sem faturas neste setor'), findsOneWidget);
  });
  testWidgets('erro de autenticação tem mensagem específica', (tester) async {
    await _pump(
      tester,
      const _FailingGateway(EfaturaFailureKind.authentication),
      _readyStore(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível autenticar'), findsOneWidget);
  });
  testWidgets('não configurado mostra login e não mostra erro desconhecido', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeGateway(overview: overview),
      _FakeStore(
        readiness: const EfaturaRuntimeReadiness(
          hasCredentials: false,
          hasClientIdentity: false,
          hasCipherCertificate: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ligar ao e-Fatura'), findsWidgets);
    expect(find.text('Erro desconhecido'), findsNothing);
  });
  testWidgets('login guarda com segurança, valida com overview e limpa senha', (
    tester,
  ) async {
    final store = _FakeStore(
      readiness: const EfaturaRuntimeReadiness(
        hasCredentials: false,
        hasClientIdentity: true,
        hasCipherCertificate: true,
      ),
    );
    await _pump(tester, _FakeGateway(overview: overview), store);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('efatura-nif')), '000000000');
    await tester.enterText(
      find.byKey(const Key('efatura-password')),
      'senha-sintetica',
    );
    await tester.tap(find.byKey(const Key('efatura-connect')));
    await tester.pumpAndSettle();
    expect(store.saveCalls, 1);
    expect(find.text('Resumo e-Fatura'), findsOneWidget);
    expect(find.text('senha-sintetica'), findsNothing);
    expect(find.byKey(const Key('efatura-password')), findsNothing);
  });
  testWidgets(
    'provisionamento e-Fatura é explícito e controlado pelo sistema',
    (tester) async {
      final provisioning = _Provisioning();
      final store = _FakeStore(
        readiness: const EfaturaRuntimeReadiness(
          hasCredentials: false,
          hasClientIdentity: false,
          hasCipherCertificate: false,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pt', 'PT'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: EfaturaScreen(
            service: EfaturaReadOnlyService(
              _FakeGateway(overview: overview),
              store,
            ),
            provisioning: provisioning,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('efatura-select-identity')));
      await tester.tap(
        find.byKey(const Key('efatura-select-cipher-certificate')),
      );
      expect(provisioning.identitySelections, 1);
      expect(provisioning.cipherSelections, 1);
      expect(provisioning.secureValues, contains(true));
    },
  );
  testWidgets('erro de rede tem mensagem humana distinta', (tester) async {
    await _pump(
      tester,
      const _FailingGateway(EfaturaFailureKind.network),
      _readyStore(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Erro de ligação'), findsOneWidget);
  });
  testWidgets('desligar limpa credenciais e estado transitório', (
    tester,
  ) async {
    final store = _readyStore();
    await _pump(tester, _FakeGateway(overview: overview), store);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('efatura-disconnect')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('efatura-disconnect-confirm')));
    await tester.pumpAndSettle();
    expect(store.clearCalls, 1);
    expect(find.text('Resumo e-Fatura'), findsNothing);
    expect(find.text('Ligar ao e-Fatura'), findsWidgets);
  });
  testWidgets('refresh é apenas manual', (tester) async {
    final gateway = _FakeGateway(overview: overview);
    await _pump(tester, gateway, _readyStore());
    await tester.pumpAndSettle();
    final refresh = find.byKey(const Key('efatura-manual-refresh'));
    await tester.ensureVisible(refresh);
    await tester.pumpAndSettle();
    await tester.tap(refresh);
    await tester.pumpAndSettle();
    expect(gateway.overviewCalls, 2);
  });

  testWidgets('English copy and localized sector are rendered naturally', (
    tester,
  ) async {
    await _pumpLocalized(
      tester,
      _FakeGateway(overview: overview),
      _readyStore(),
      locale: const Locale('en'),
    );
    await tester.pumpAndSettle();
    expect(find.text('e-Fatura overview'), findsOneWidget);
    expect(find.text('Provisional tax benefit'), findsOneWidget);
    expect(find.text('No invoices to validate'), findsOneWidget);
    expect(find.text('Health'), findsOneWidget);
  });

  testWidgets('local validation blocks malformed credentials', (tester) async {
    final store = _FakeStore(
      readiness: const EfaturaRuntimeReadiness(
        hasCredentials: false,
        hasClientIdentity: true,
        hasCipherCertificate: true,
      ),
    );
    await _pump(tester, _FakeGateway(overview: overview), store);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('efatura-nif')), '12');
    await tester.tap(find.byKey(const Key('efatura-connect')));
    await tester.pump();
    expect(find.text('Introduz um NIF com 9 algarismos.'), findsOneWidget);
    expect(find.text('Introduz a senha.'), findsOneWidget);
    expect(store.saveCalls, 0);
  });

  testWidgets('small dark screen with large text has no overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpLocalized(
      tester,
      _FakeGateway(overview: overview),
      _readyStore(),
      locale: const Locale('en'),
      themeMode: ThemeMode.dark,
      textScaler: const TextScaler.linear(2),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Experimental'), findsOneWidget);
  });

  for (final entry in <EfaturaFailureKind, String>{
    EfaturaFailureKind.serviceUnavailable: 'Serviço indisponível',
    EfaturaFailureKind.parsing: 'Resposta inesperada',
  }.entries) {
    testWidgets('${entry.key.name} tem copy humana', (tester) async {
      await _pump(tester, _FailingGateway(entry.key), _readyStore());
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
      expect(find.textContaining('SOAP'), findsNothing);
      expect(find.textContaining('NTP'), findsNothing);
    });
  }
}

Future<void> _pump(
  WidgetTester tester,
  EfaturaReadOnlyGateway gateway,
  EfaturaCredentialStore store,
) => _pumpLocalized(tester, gateway, store);

Future<void> _pumpLocalized(
  WidgetTester tester,
  EfaturaReadOnlyGateway gateway,
  EfaturaCredentialStore store, {
  Locale locale = const Locale('pt', 'PT'),
  ThemeMode themeMode = ThemeMode.light,
  TextScaler textScaler = TextScaler.noScaling,
}) => tester.pumpWidget(
  MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    themeMode: themeMode,
    theme: ThemeData.light(useMaterial3: true),
    darkTheme: ThemeData.dark(useMaterial3: true),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: child!,
    ),
    home: EfaturaScreen(service: EfaturaReadOnlyService(gateway, store)),
  ),
);

_FakeStore _readyStore() => _FakeStore(
  readiness: const EfaturaRuntimeReadiness(
    hasCredentials: true,
    hasClientIdentity: true,
    hasCipherCertificate: true,
  ),
);

final class _FakeStore implements EfaturaCredentialStore {
  _FakeStore({required this.readiness});
  EfaturaRuntimeReadiness readiness;
  int saveCalls = 0;
  int clearCalls = 0;

  @override
  Future<void> save(EfaturaCredentials credentials) async {
    saveCalls++;
    readiness = const EfaturaRuntimeReadiness(
      hasCredentials: true,
      hasClientIdentity: true,
      hasCipherCertificate: true,
    );
  }

  @override
  Future<void> clear() async {
    clearCalls++;
    readiness = EfaturaRuntimeReadiness(
      hasCredentials: false,
      hasClientIdentity: readiness.hasClientIdentity,
      hasCipherCertificate: readiness.hasCipherCertificate,
    );
  }

  @override
  Future<bool> hasCredentials() async => readiness.hasCredentials;

  @override
  Future<EfaturaRuntimeReadiness> load() async => readiness;
}

final class _FakeGateway implements EfaturaReadOnlyGateway {
  _FakeGateway({required this.overview, this.sectorInvoices = const []});
  final EfaturaOverview overview;
  final List<EfaturaInvoice> sectorInvoices;
  int overviewCalls = 0;
  @override
  Future<EfaturaOverview> fetchOverview() async {
    overviewCalls++;
    return overview;
  }

  @override
  Future<List<EfaturaInvoice>> fetchPendingInvoices() async => const [];
  @override
  Future<List<EfaturaInvoice>> fetchSectorInvoices(String sectorCode) async =>
      sectorInvoices;
}

final class _DeferredGateway implements EfaturaReadOnlyGateway {
  _DeferredGateway(this.future);
  final Future<EfaturaOverview> future;
  @override
  Future<EfaturaOverview> fetchOverview() => future;
  @override
  Future<List<EfaturaInvoice>> fetchPendingInvoices() async => const [];
  @override
  Future<List<EfaturaInvoice>> fetchSectorInvoices(String sectorCode) async =>
      const [];
}

final class _FailingGateway implements EfaturaReadOnlyGateway {
  const _FailingGateway(this.kind);
  final EfaturaFailureKind kind;
  Never _fail() => throw EfaturaServiceException(kind, 'Mensagem segura');
  @override
  Future<EfaturaOverview> fetchOverview() async => _fail();
  @override
  Future<List<EfaturaInvoice>> fetchPendingInvoices() async => _fail();
  @override
  Future<List<EfaturaInvoice>> fetchSectorInvoices(String sectorCode) async =>
      _fail();
}

final class _Provisioning implements EfaturaRuntimeProvisioning {
  int identitySelections = 0;
  int cipherSelections = 0;
  final List<bool> secureValues = [];

  @override
  Future<bool> selectClientIdentity() async {
    identitySelections++;
    return false;
  }

  @override
  Future<bool> selectCipherCertificate() async {
    cipherSelections++;
    return false;
  }

  @override
  Future<void> setScreenSecure(bool enabled) async {
    secureValues.add(enabled);
  }
}
