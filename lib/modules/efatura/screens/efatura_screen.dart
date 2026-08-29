import 'package:flutter/material.dart';

import '../application/efatura_read_only_service.dart';
import '../domain/efatura_models.dart';

final class EfaturaScreen extends StatefulWidget {
  const EfaturaScreen({super.key, required this.service});
  final EfaturaReadOnlyService service;
  @override
  State<EfaturaScreen> createState() => _EfaturaScreenState();
}

final class _EfaturaScreenState extends State<EfaturaScreen> {
  EfaturaConnectionStatus _status = EfaturaConnectionStatus.loading;
  EfaturaOverview? _overview;
  EfaturaServiceException? _failure;
  List<EfaturaInvoice> _invoices = const [];
  String? _selectedSector;
  bool _invoiceListLoaded = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _status = EfaturaConnectionStatus.loading;
      _failure = null;
    });
    try {
      final overview = await widget.service.loadOverview();
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _status = EfaturaConnectionStatus.ready;
      });
    } on EfaturaServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _failure = error;
        _status = error.kind == EfaturaFailureKind.notConfigured
            ? EfaturaConnectionStatus.notConfigured
            : EfaturaConnectionStatus.error;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failure = const EfaturaServiceException(
          EfaturaFailureKind.unknown,
          'Não foi possível atualizar o e-Fatura. Tenta novamente mais tarde.',
        );
        _status = EfaturaConnectionStatus.error;
      });
    }
  }

  Future<void> _loadPending() async => _loadInvoices(null);
  Future<void> _loadSector(AtExpenseSector sector) async =>
      _loadInvoices(sector);
  Future<void> _loadInvoices(AtExpenseSector? sector) async {
    setState(() {
      _status = EfaturaConnectionStatus.loading;
      _failure = null;
    });
    try {
      final invoices = sector == null
          ? await widget.service.loadPendingInvoices()
          : await widget.service.loadSectorInvoices(sector);
      if (!mounted) return;
      setState(() {
        _invoices = invoices;
        _selectedSector = sector?.code;
        _invoiceListLoaded = true;
        _status = EfaturaConnectionStatus.ready;
      });
    } on EfaturaServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _failure = error;
        _status = EfaturaConnectionStatus.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('e-Fatura')),
    body: RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              avatar: Icon(Icons.science_outlined, size: 18),
              label: Text('Experimental'),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'As tuas despesas, só para consulta',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'A Taxy nunca classifica, altera ou regista faturas neste ecrã.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          if (_status == EfaturaConnectionStatus.loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(key: Key('efatura-loading')),
              ),
            ),
          if (_failure != null) _ErrorCard(error: _failure!, onRetry: _refresh),
          if (_overview != null &&
              _status != EfaturaConnectionStatus.loading) ...[
            _OverviewCard(overview: _overview!, onPending: _loadPending),
            const SizedBox(height: 20),
            Text('Setores', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            if (_overview!.sectors.isEmpty)
              const _EmptyCard(text: 'Ainda não existem dados por setor.'),
            ..._overview!.sectors.map(
              (sector) => Card(
                child: ListTile(
                  key: Key('sector-${sector.code}'),
                  title: Text(sector.label ?? sector.code),
                  subtitle: sector.provisionalBenefitCents == null
                      ? const Text('Benefício não disponível')
                      : Text(
                          'Benefício provisório: ${_euros(sector.provisionalBenefitCents!)}',
                        ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _loadSector(sector),
                ),
              ),
            ),
            if (_invoiceListLoaded) ...[
              const SizedBox(height: 20),
              Text(
                _selectedSector == null
                    ? 'Faturas pendentes'
                    : 'Faturas do setor',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              if (_invoices.isEmpty)
                const _EmptyCard(text: 'Não foram encontrados documentos.'),
              ..._invoices.map((invoice) => _InvoiceTile(invoice: invoice)),
            ],
          ],
          const SizedBox(height: 18),
          OutlinedButton.icon(
            key: const Key('efatura-manual-refresh'),
            onPressed: _status == EfaturaConnectionStatus.loading
                ? null
                : _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Atualizar manualmente'),
          ),
        ],
      ),
    ),
  );
}

final class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.overview, required this.onPending});
  final EfaturaOverview overview;
  final VoidCallback onPending;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo e-Fatura',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          Text(
            'Benefício provisório: ${_euros(overview.provisionalBenefitCents)}',
          ),
          Text('Faturas por validar: ${overview.pendingValidation}'),
          Text('Por associar a receita: ${overview.pendingRevenueAssociation}'),
          if (overview.pendingValidation == 0)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text('Não tens faturas pendentes de classificação.'),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: TextButton(
                onPressed: onPending,
                child: const Text('Ver faturas pendentes'),
              ),
            ),
        ],
      ),
    ),
  );
}

final class _InvoiceTile extends StatelessWidget {
  const _InvoiceTile({required this.invoice});
  final EfaturaInvoice invoice;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.receipt_long_outlined),
      title: Text(invoice.issuerDisplayName ?? 'Emitente não disponível'),
      subtitle: Text(
        '${invoice.date}${invoice.sectorLabel == null ? '' : ' · ${invoice.sectorLabel}'}',
      ),
      trailing: Text(
        _euros(invoice.totalCents),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
  );
}

final class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error, required this.onRetry});
  final EfaturaServiceException error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _errorTitle(error.kind),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(error.safeMessage),
          const SizedBox(height: 10),
          TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    ),
  );
}

final class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(18), child: Text(text)),
  );
}

String _errorTitle(EfaturaFailureKind kind) => switch (kind) {
  EfaturaFailureKind.notConfigured => 'Ligação ainda não configurada',
  EfaturaFailureKind.authentication => 'Não foi possível autenticar',
  EfaturaFailureKind.network || EfaturaFailureKind.tls => 'Erro de ligação',
  EfaturaFailureKind.serviceUnavailable =>
    'Serviço temporariamente indisponível',
  EfaturaFailureKind.ntp => 'Hora segura indisponível',
  EfaturaFailureKind.soap ||
  EfaturaFailureKind.business ||
  EfaturaFailureKind.parsing => 'Resposta não suportada',
  EfaturaFailureKind.unknown => 'Não foi possível atualizar',
};
String _euros(int cents) =>
    '${(cents / 100).toStringAsFixed(2).replaceAll('.', ',')} €';
