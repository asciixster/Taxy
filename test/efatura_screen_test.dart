import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/modules/efatura/application/efatura_read_only_service.dart';
import 'package:taxy_pt/modules/efatura/domain/efatura_models.dart';
import 'package:taxy_pt/modules/efatura/screens/efatura_screen.dart';

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
    await _pump(tester, _DeferredGateway(completer.future));
    expect(find.byKey(const Key('efatura-loading')), findsOneWidget);
    expect(find.text('Experimental'), findsOneWidget);
  });
  testWidgets('mostra overview ligado e empty pending', (tester) async {
    await _pump(tester, _FakeGateway(overview: overview));
    await tester.pumpAndSettle();
    expect(find.text('Resumo e-Fatura'), findsOneWidget);
    expect(find.text('Benefício provisório: 12,00 €'), findsOneWidget);
    expect(
      find.text('Não tens faturas pendentes de classificação.'),
      findsOneWidget,
    );
  });
  testWidgets('mostra setores sem inventar contagem', (tester) async {
    await _pump(tester, _FakeGateway(overview: overview));
    await tester.pumpAndSettle();
    expect(find.text('Saúde'), findsOneWidget);
    expect(find.textContaining('Benefício provisório: 2,50 €'), findsOneWidget);
    expect(find.textContaining('faturas no setor'), findsNothing);
  });
  testWidgets('mostra invoice sintética sem identificadores técnicos', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeGateway(overview: overview, sectorInvoices: const [invoice]),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('sector-C05')));
    await tester.tap(find.byKey(const Key('sector-C05')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Emitente sintético'), 250);
    expect(find.text('Emitente sintético'), findsOneWidget);
    expect(find.text('23,45 €'), findsOneWidget);
    expect(find.textContaining('IdDocumento'), findsNothing);
    expect(find.textContaining('NIF'), findsNothing);
  });
  testWidgets('mostra empty state de setor', (tester) async {
    await _pump(tester, _FakeGateway(overview: overview));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('sector-C05')));
    await tester.tap(find.byKey(const Key('sector-C05')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Não foram encontrados documentos.'),
      250,
    );
    expect(find.text('Não foram encontrados documentos.'), findsOneWidget);
  });
  testWidgets('erro de autenticação tem mensagem específica', (tester) async {
    await _pump(
      tester,
      const _FailingGateway(EfaturaFailureKind.authentication),
    );
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível autenticar'), findsOneWidget);
  });
  testWidgets('não configurado é distinto de erro desconhecido', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EfaturaScreen(
          service: EfaturaReadOnlyService(UnconfiguredEfaturaGateway()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ligação ainda não configurada'), findsOneWidget);
    expect(find.text('Erro desconhecido'), findsNothing);
  });
  testWidgets('refresh é apenas manual', (tester) async {
    final gateway = _FakeGateway(overview: overview);
    await _pump(tester, gateway);
    await tester.pumpAndSettle();
    final refresh = find.byKey(const Key('efatura-manual-refresh'));
    await tester.ensureVisible(refresh);
    await tester.pumpAndSettle();
    await tester.tap(refresh);
    await tester.pumpAndSettle();
    expect(gateway.overviewCalls, 2);
  });
}

Future<void> _pump(WidgetTester tester, EfaturaReadOnlyGateway gateway) =>
    tester.pumpWidget(
      MaterialApp(
        home: EfaturaScreen(service: EfaturaReadOnlyService(gateway)),
      ),
    );

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
