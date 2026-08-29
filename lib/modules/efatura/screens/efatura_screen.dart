import 'dart:async';

import 'package:flutter/material.dart';

import '../application/efatura_read_only_service.dart';
import '../domain/efatura_models.dart';
import '../infrastructure/efatura_runtime_bridge.dart';

final class EfaturaScreen extends StatefulWidget {
  const EfaturaScreen({super.key, required this.service, this.provisioning});

  final EfaturaReadOnlyService service;
  final EfaturaRuntimeProvisioning? provisioning;

  @override
  State<EfaturaScreen> createState() => _EfaturaScreenState();
}

final class _EfaturaScreenState extends State<EfaturaScreen> {
  final _nifController = TextEditingController();
  final _passwordController = TextEditingController();
  EfaturaConnectionStatus _status = EfaturaConnectionStatus.notConfigured;
  EfaturaRuntimeReadiness? _readiness;
  EfaturaOverview? _overview;
  EfaturaServiceException? _failure;
  List<EfaturaInvoice> _invoices = const [];
  String? _selectedSector;
  bool _invoiceListLoaded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_protectScreen(true));
    _initialize();
  }

  @override
  void dispose() {
    unawaited(_protectScreen(false));
    _passwordController.clear();
    _nifController.clear();
    _passwordController.dispose();
    _nifController.dispose();
    super.dispose();
  }

  Future<void> _protectScreen(bool enabled) async {
    try {
      await widget.provisioning?.setScreenSecure(enabled);
    } on EfaturaServiceException {
      // Screenshot protection is defence-in-depth; the credential boundary
      // and read-only connector continue to fail closed independently.
    }
  }

  Future<void> _initialize() async {
    try {
      final readiness = await widget.service.readiness();
      if (!mounted) return;
      setState(() {
        _readiness = readiness;
        _status = readiness.isReady
            ? EfaturaConnectionStatus.connecting
            : EfaturaConnectionStatus.notConfigured;
      });
      if (readiness.isReady) await _refresh();
    } on EfaturaServiceException catch (error) {
      _applyFailure(error);
    }
  }

  Future<void> _connect() async {
    setState(() {
      _status = EfaturaConnectionStatus.connecting;
      _failure = null;
    });
    final credentials = EfaturaCredentials(
      nif: _nifController.text.trim(),
      password: _passwordController.text,
    );
    try {
      final overview = await widget.service.connect(credentials);
      if (!mounted) return;
      _nifController.clear();
      setState(() {
        _overview = overview;
        _status = EfaturaConnectionStatus.connected;
        _readiness = const EfaturaRuntimeReadiness(
          hasCredentials: true,
          hasClientIdentity: true,
          hasCipherCertificate: true,
        );
      });
    } on EfaturaServiceException catch (error) {
      _applyFailure(error);
    } finally {
      _passwordController.clear();
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _status = EfaturaConnectionStatus.connecting;
      _failure = null;
    });
    try {
      final overview = await widget.service.loadOverview();
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _status = EfaturaConnectionStatus.connected;
      });
    } on EfaturaServiceException catch (error) {
      _applyFailure(error);
    } catch (_) {
      _applyFailure(
        const EfaturaServiceException(
          EfaturaFailureKind.unknown,
          'Não foi possível atualizar o e-Fatura. Tenta novamente mais tarde.',
        ),
      );
    }
  }

  Future<void> _disconnect() async {
    await widget.service.disconnect();
    if (!mounted) return;
    _passwordController.clear();
    _nifController.clear();
    setState(() {
      _overview = null;
      _invoices = const [];
      _selectedSector = null;
      _invoiceListLoaded = false;
      _failure = null;
      _readiness = EfaturaRuntimeReadiness(
        hasCredentials: false,
        hasClientIdentity: _readiness?.hasClientIdentity ?? false,
        hasCipherCertificate: _readiness?.hasCipherCertificate ?? false,
      );
      _status = EfaturaConnectionStatus.disconnected;
    });
  }

  Future<void> _selectClientIdentity() async {
    final selected = await widget.provisioning?.selectClientIdentity() ?? false;
    if (selected) await _initialize();
  }

  Future<void> _selectCipherCertificate() async {
    final selected =
        await widget.provisioning?.selectCipherCertificate() ?? false;
    if (selected) await _initialize();
  }

  Future<void> _loadPending() async {
    final overview = _overview;
    if (overview == null || overview.pendingValidation <= 0) return;
    await _loadInvoices(null);
  }

  Future<void> _loadSector(AtExpenseSector sector) async =>
      _loadInvoices(sector);

  Future<void> _loadInvoices(AtExpenseSector? sector) async {
    setState(() {
      _status = EfaturaConnectionStatus.connecting;
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
        _status = EfaturaConnectionStatus.connected;
      });
    } on EfaturaServiceException catch (error) {
      _applyFailure(error);
    }
  }

  void _applyFailure(EfaturaServiceException error) {
    if (!mounted) return;
    setState(() {
      _failure = error;
      _status = switch (error.kind) {
        EfaturaFailureKind.notConfigured =>
          EfaturaConnectionStatus.notConfigured,
        EfaturaFailureKind.authentication =>
          EfaturaConnectionStatus.authenticationError,
        EfaturaFailureKind.expired => EfaturaConnectionStatus.expired,
        EfaturaFailureKind.network ||
        EfaturaFailureKind.tls => EfaturaConnectionStatus.networkError,
        _ => EfaturaConnectionStatus.serviceError,
      };
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('e-Fatura'),
      actions: [
        if (_overview != null)
          IconButton(
            key: const Key('efatura-disconnect'),
            tooltip: 'Desligar e-Fatura',
            onPressed: _disconnect,
            icon: const Icon(Icons.logout),
          ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _overview == null ? _initialize : _refresh,
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
            'As credenciais são utilizadas apenas para consultar o e-Fatura.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          if (_status == EfaturaConnectionStatus.connecting)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(key: Key('efatura-loading')),
              ),
            ),
          if (_failure != null)
            _ErrorCard(error: _failure!, onRetry: _initialize),
          if (_overview == null &&
              _status != EfaturaConnectionStatus.connecting)
            _ConnectCard(
              readiness: _readiness,
              nifController: _nifController,
              passwordController: _passwordController,
              onConnect: _connect,
              onSelectIdentity: widget.provisioning == null
                  ? null
                  : _selectClientIdentity,
              onSelectCipherCertificate: widget.provisioning == null
                  ? null
                  : _selectCipherCertificate,
            ),
          if (_overview != null &&
              _status != EfaturaConnectionStatus.connecting) ...[
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
                          'Benefício provisório: '
                          '${_euros(sector.provisionalBenefitCents!)}',
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
          if (_overview != null)
            OutlinedButton.icon(
              key: const Key('efatura-manual-refresh'),
              onPressed: _status == EfaturaConnectionStatus.connecting
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

final class _ConnectCard extends StatelessWidget {
  const _ConnectCard({
    required this.readiness,
    required this.nifController,
    required this.passwordController,
    required this.onConnect,
    required this.onSelectIdentity,
    required this.onSelectCipherCertificate,
  });

  final EfaturaRuntimeReadiness? readiness;
  final TextEditingController nifController;
  final TextEditingController passwordController;
  final VoidCallback onConnect;
  final VoidCallback? onSelectIdentity;
  final VoidCallback? onSelectCipherCertificate;

  @override
  Widget build(BuildContext context) {
    final identityReady = readiness?.hasClientIdentity == true;
    final cipherReady = readiness?.hasCipherCertificate == true;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ligar ao Portal das Finanças',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('efatura-nif'),
              controller: nifController,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.username],
              maxLength: 9,
              decoration: const InputDecoration(labelText: 'NIF'),
            ),
            TextField(
              key: const Key('efatura-password'),
              controller: passwordController,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              autofillHints: const [AutofillHints.password],
              decoration: const InputDecoration(labelText: 'Senha'),
            ),
            const SizedBox(height: 14),
            if (!identityReady && onSelectIdentity != null)
              TextButton.icon(
                key: const Key('efatura-select-identity'),
                onPressed: onSelectIdentity,
                icon: const Icon(Icons.badge_outlined),
                label: const Text('Selecionar certificado do dispositivo'),
              ),
            if (!cipherReady && onSelectCipherCertificate != null)
              TextButton.icon(
                key: const Key('efatura-select-cipher-certificate'),
                onPressed: onSelectCipherCertificate,
                icon: const Icon(Icons.vpn_key_outlined),
                label: const Text('Selecionar chave pública da AT'),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const Key('efatura-connect'),
              onPressed: identityReady && cipherReady ? onConnect : null,
              icon: const Icon(Icons.lock_outline),
              label: const Text('Ligar'),
            ),
          ],
        ),
      ),
    );
  }
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
            'Benefício provisório: '
            '${_euros(overview.provisionalBenefitCents)}',
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
        '${invoice.date}'
        "${invoice.sectorLabel == null ? '' : ' · ${invoice.sectorLabel}'}",
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
  EfaturaFailureKind.authorization => 'Acesso não autorizado',
  EfaturaFailureKind.network || EfaturaFailureKind.tls => 'Erro de ligação',
  EfaturaFailureKind.serviceUnavailable =>
    'Serviço temporariamente indisponível',
  EfaturaFailureKind.expired => 'Sessão expirada',
  EfaturaFailureKind.ntp => 'Hora segura indisponível',
  EfaturaFailureKind.soap ||
  EfaturaFailureKind.business ||
  EfaturaFailureKind.parsing => 'Resposta não suportada',
  EfaturaFailureKind.unknown => 'Não foi possível atualizar',
};

String _euros(int cents) =>
    '${(cents / 100).toStringAsFixed(2).replaceAll('.', ',')} €';
