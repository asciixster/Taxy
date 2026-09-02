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
    provisionalBenefitCents: AtValue.available(250),
    totalExpensesCents: AtValue.available(2345),
    totalVatExpensesCents: AtValue.available(439),
  );
  const overview = EfaturaOverview(
    provisionalBenefitCents: AtValue.available(1200),
    pendingValidation: AtValue.available(0),
    pendingRevenueAssociation: AtValue.available(0),
    sectors: AtValue.available([sector]),
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
    expect(find.textContaining('12,00'), findsWidgets);
    expect(find.text('Sem faturas pendentes'), findsOneWidget);
    expect(find.byKey(const Key('efatura-irs-evidence')), findsOneWidget);
    expect(find.text('Dados para previsão de IRS'), findsOneWidget);
  });
  testWidgets('distingue benefício indisponível de zero real', (tester) async {
    const partial = EfaturaOverview(
      provisionalBenefitCents: AtValue.unavailable(),
      pendingValidation: AtValue.available(5),
      pendingRevenueAssociation: AtValue.unavailable(),
      sectors: AtValue.unavailable(),
    );
    await _pump(tester, _FakeGateway(overview: partial), _readyStore());
    await tester.pumpAndSettle();
    expect(find.text('Indisponível'), findsWidgets);
    expect(find.textContaining('Alguns valores'), findsOneWidget);
    expect(find.textContaining('0,00'), findsNothing);
    expect(find.text('5'), findsOneWidget);
  });
  testWidgets('mostra zero real quando o benefício está disponível', (
    tester,
  ) async {
    const zero = EfaturaOverview(
      provisionalBenefitCents: AtValue.available(0),
      pendingValidation: AtValue.available(0),
      pendingRevenueAssociation: AtValue.available(0),
      sectors: AtValue.available([]),
    );
    await _pump(tester, _FakeGateway(overview: zero), _readyStore());
    await tester.pumpAndSettle();
    expect(find.textContaining('0,00'), findsWidgets);
    expect(find.text('Indisponível'), findsNothing);
  });
  testWidgets('mostra setores sem inventar contagem', (tester) async {
    await _pump(tester, _FakeGateway(overview: overview), _readyStore());
    await tester.pumpAndSettle();
    expect(find.text('Saúde'), findsOneWidget);
    expect(find.textContaining('Despesas listadas'), findsWidgets);
    expect(find.textContaining('23,45'), findsWidgets);
    expect(find.textContaining('2,50'), findsOneWidget);
    expect(find.text('🩺'), findsOneWidget);
    expect(find.byKey(const Key('sector-emoji-C05')), findsOneWidget);
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
    await tester.scrollUntilVisible(
      find.text('Emitente sintético'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Emitente sintético'), findsOneWidget);
    expect(find.textContaining('23,45'), findsWidgets);
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
  testWidgets('campos de autenticação têm rótulos para leitores de ecrã', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      _FakeGateway(overview: overview),
      _FakeStore(
        readiness: const EfaturaRuntimeReadiness(
          hasCredentials: false,
          hasClientIdentity: true,
          hasCipherCertificate: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('NIF'), findsAtLeast(1));
    expect(find.bySemanticsLabel('Senha'), findsAtLeast(1));
    semantics.dispose();
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

  testWidgets('sessão expirada regressa ao login sem estado ligado falso', (
    tester,
  ) async {
    await _pump(
      tester,
      const _FailingGateway(EfaturaFailureKind.expired),
      _readyStore(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sessão expirada'), findsOneWidget);
    expect(find.byKey(const Key('efatura-connect')), findsOneWidget);
    expect(find.text('Resumo e-Fatura'), findsNothing);
  });
  testWidgets('erro após guardar credenciais continua a permitir desligar', (
    tester,
  ) async {
    final store = _readyStore();
    await _pump(
      tester,
      const _FailingGateway(EfaturaFailureKind.network),
      store,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('efatura-disconnect')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('efatura-disconnect-confirm')));
    await tester.pumpAndSettle();
    expect(store.clearCalls, 1);
    expect(find.text('Ligar ao e-Fatura'), findsWidgets);
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

  testWidgets('duplo toque em refresh produz apenas um pedido', (tester) async {
    final gateway = _BlockingRefreshGateway(overview);
    await _pump(tester, gateway, _readyStore());
    await tester.pumpAndSettle();
    final refresh = find.byKey(const Key('efatura-manual-refresh'));
    await tester.ensureVisible(refresh);
    await tester.pumpAndSettle();
    await tester.tap(refresh);
    await tester.tap(refresh);
    await tester.pump();
    expect(gateway.overviewCalls, 2);
    gateway.completeRefresh();
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
    expect(find.text('No pending invoices'), findsOneWidget);
    expect(find.text('Data for your IRS estimate'), findsOneWidget);
    expect(find.text('Health'), findsOneWidget);
  });

  testWidgets(
    'pending count opens a read-only list without validation actions',
    (tester) async {
      const pendingOverview = EfaturaOverview(
        provisionalBenefitCents: AtValue.available(50339),
        pendingValidation: AtValue.available(5),
        pendingRevenueAssociation: AtValue.available(0),
        sectors: AtValue.available([]),
      );
      await _pump(
        tester,
        _FakeGateway(overview: pendingOverview),
        _readyStore(),
      );
      await tester.pumpAndSettle();
      expect(find.text('5'), findsOneWidget);
      expect(
        find.text(
          'A Taxy apresenta esta contagem apenas para consulta. A validação '
          'continua a ser feita no e-Fatura oficial.',
        ),
        findsOneWidget,
      );
      expect(find.text('Ver faturas por validar'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('efatura-view-pending')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('efatura-view-pending')));
      await tester.pumpAndSettle();
      expect(find.text('Faturas pendentes'), findsOneWidget);
      expect(find.text('Sem faturas pendentes'), findsOneWidget);
      expect(find.textContaining('Classificar'), findsNothing);
      expect(find.textContaining('Validar'), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    },
  );

  testWidgets('pending list renders normalized synthetic backend data', (
    tester,
  ) async {
    const pendingOverview = EfaturaOverview(
      provisionalBenefitCents: AtValue.unavailable(),
      pendingValidation: AtValue.available(1),
      pendingRevenueAssociation: AtValue.unavailable(),
      sectors: AtValue.unavailable(),
    );
    await _pump(
      tester,
      _FakeGateway(
        overview: pendingOverview,
        pendingInvoices: const [
          EfaturaInvoice(
            issuerDisplayName: 'Emitente sintético',
            date: '2026-08-29',
            totalCents: 2345,
            pendingClassification: true,
          ),
        ],
      ),
      _readyStore(),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('efatura-view-pending')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('efatura-view-pending')));
    await tester.pumpAndSettle();
    expect(find.text('Emitente sintético'), findsOneWidget);
    expect(find.text('23,45 €'), findsWidgets);
    expect(find.textContaining('Classificar'), findsNothing);
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
  _FakeGateway({
    required this.overview,
    this.sectorInvoices = const [],
    this.pendingInvoices = const [],
  });
  final EfaturaOverview overview;
  final List<EfaturaInvoice> sectorInvoices;
  final List<EfaturaInvoice> pendingInvoices;
  int overviewCalls = 0;
  @override
  Future<EfaturaOverview> fetchOverview() async {
    overviewCalls++;
    return overview;
  }

  @override
  Future<List<EfaturaInvoice>> fetchPendingInvoices() async => pendingInvoices;
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

final class _BlockingRefreshGateway implements EfaturaReadOnlyGateway {
  _BlockingRefreshGateway(this.overview);
  final EfaturaOverview overview;
  final Completer<EfaturaOverview> _refresh = Completer<EfaturaOverview>();
  int overviewCalls = 0;

  void completeRefresh() => _refresh.complete(overview);

  @override
  Future<EfaturaOverview> fetchOverview() {
    overviewCalls++;
    return overviewCalls == 1 ? Future.value(overview) : _refresh.future;
  }

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
