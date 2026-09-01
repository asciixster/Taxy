import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/taxy_formatters.dart';
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
  final _formKey = GlobalKey<FormState>();
  EfaturaConnectionStatus _status = EfaturaConnectionStatus.notConfigured;
  EfaturaRuntimeReadiness? _readiness;
  EfaturaOverview? _overview;
  EfaturaServiceException? _failure;
  List<EfaturaInvoice> _invoices = const [];
  bool _invoiceListLoaded = false;
  bool _showingPendingInvoices = false;
  bool _requestInFlight = false;

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
      if (readiness.isReady) {
        await _refresh();
      } else {
        final reachability = await widget.service.reachability();
        if (reachability == EfaturaApiReachability.networkOffline) {
          throw const EfaturaServiceException(
            EfaturaFailureKind.network,
            'Não foi possível estabelecer ligação.',
          );
        }
        if (reachability == EfaturaApiReachability.serviceUnavailable) {
          throw const EfaturaServiceException(
            EfaturaFailureKind.serviceUnavailable,
            'O serviço e-Fatura não está disponível de momento.',
          );
        }
      }
    } on EfaturaServiceException catch (error) {
      _applyFailure(error);
    }
  }

  Future<void> _connect() async {
    if (_requestInFlight) return;
    if (_formKey.currentState?.validate() != true) return;
    _requestInFlight = true;
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
        _invoices = const [];
        _invoiceListLoaded = false;
        _showingPendingInvoices = false;
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
      _requestInFlight = false;
    }
  }

  Future<void> _refresh() async {
    if (_requestInFlight) return;
    _requestInFlight = true;
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
    } finally {
      _requestInFlight = false;
    }
  }

  Future<void> _confirmDisconnect() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.disconnectTitle),
        content: Text(l10n.disconnectExplanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('efatura-disconnect-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.disconnect),
          ),
        ],
      ),
    );
    if (confirmed == true) await _disconnect();
  }

  Future<void> _disconnect() async {
    if (_requestInFlight) return;
    _requestInFlight = true;
    try {
      await widget.service.disconnect();
      if (!mounted) return;
      _passwordController.clear();
      _nifController.clear();
      setState(() {
        _overview = null;
        _invoices = const [];
        _invoiceListLoaded = false;
        _showingPendingInvoices = false;
        _failure = null;
        _readiness = EfaturaRuntimeReadiness(
          hasCredentials: false,
          hasClientIdentity: _readiness?.hasClientIdentity ?? false,
          hasCipherCertificate: _readiness?.hasCipherCertificate ?? false,
        );
        _status = EfaturaConnectionStatus.disconnected;
      });
    } finally {
      _requestInFlight = false;
    }
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

  Future<void> _loadSector(AtExpenseSector sector) async =>
      _loadInvoices(sector);

  Future<void> _loadPendingInvoices() async {
    if (_requestInFlight) return;
    _requestInFlight = true;
    setState(() {
      _status = EfaturaConnectionStatus.connecting;
      _failure = null;
    });
    try {
      final invoices = await widget.service.loadPendingInvoices();
      if (!mounted) return;
      setState(() {
        _invoices = invoices;
        _invoiceListLoaded = true;
        _showingPendingInvoices = true;
        _status = EfaturaConnectionStatus.connected;
      });
    } on EfaturaServiceException catch (error) {
      _applyFailure(error);
    } finally {
      _requestInFlight = false;
    }
  }

  Future<void> _loadInvoices(AtExpenseSector sector) async {
    if (_requestInFlight) return;
    _requestInFlight = true;
    setState(() {
      _status = EfaturaConnectionStatus.connecting;
      _failure = null;
    });
    try {
      final invoices = await widget.service.loadSectorInvoices(sector);
      if (!mounted) return;
      setState(() {
        _invoices = invoices;
        _invoiceListLoaded = true;
        _showingPendingInvoices = false;
        _status = EfaturaConnectionStatus.connected;
      });
    } on EfaturaServiceException catch (error) {
      _applyFailure(error);
    } finally {
      _requestInFlight = false;
    }
  }

  void _applyFailure(EfaturaServiceException error) {
    if (!mounted) return;
    final sessionEnded =
        error.kind == EfaturaFailureKind.expired ||
        error.kind == EfaturaFailureKind.authentication;
    setState(() {
      _failure = error;
      if (sessionEnded) {
        _overview = null;
        _invoices = const [];
        _invoiceListLoaded = false;
        _showingPendingInvoices = false;
        _readiness = const EfaturaRuntimeReadiness(
          hasCredentials: false,
          hasClientIdentity: true,
          hasCipherCertificate: true,
        );
      }
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final busy = _status == EfaturaConnectionStatus.connecting;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.efaturaTitle),
        actions: [
          if (_overview != null || (_readiness?.hasCredentials ?? false))
            IconButton(
              key: const Key('efatura-disconnect'),
              tooltip: l10n.disconnectEfatura,
              onPressed: busy ? null : _confirmDisconnect,
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => RefreshIndicator(
          onRefresh: _overview == null ? _initialize : _refresh,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              constraints.maxWidth < 380 ? 14 : 20,
              8,
              constraints.maxWidth < 380 ? 14 : 20,
              32,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Semantics(
                          label: l10n.efaturaSemantics,
                          child: Chip(
                            visualDensity: VisualDensity.compact,
                            avatar: const Icon(
                              Icons.science_outlined,
                              size: 16,
                            ),
                            label: Text(l10n.experimental),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.efaturaHeroTitle,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.efaturaCredentialNotice,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (busy && _overview == null)
                        const _OverviewSkeleton(key: Key('efatura-loading')),
                      if (_failure != null) ...[
                        _ErrorCard(error: _failure!, onRetry: _initialize),
                        const SizedBox(height: 12),
                      ],
                      if (_overview == null && !busy)
                        _ConnectCard(
                          formKey: _formKey,
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
                      if (_overview != null) ...[
                        if (busy) const LinearProgressIndicator(minHeight: 3),
                        _OverviewCard(overview: _overview!),
                        if ((_overview!.pendingValidation.valueOrNull ?? 0) >
                            0) ...[
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            key: const Key('efatura-view-pending'),
                            onPressed: busy ? null : _loadPendingInvoices,
                            icon: const Icon(Icons.receipt_long_outlined),
                            label: Text(l10n.viewPendingInvoices),
                          ),
                        ],
                        const SizedBox(height: 10),
                        _IrsEvidenceCard(evidence: _overview!.irsEvidence),
                        if (_overview!.outcome ==
                            EfaturaOverviewOutcome.partialSuccess) ...[
                          const SizedBox(height: 10),
                          _PartialSuccessBanner(
                            message: l10n.partialEfaturaData,
                          ),
                        ],
                        const SizedBox(height: 24),
                        Semantics(
                          header: true,
                          child: Text(
                            l10n.expensesByCategory,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (!_overview!.sectors.isAvailable)
                          _EmptyCard(
                            icon: Icons.category_outlined,
                            text: l10n.unavailable,
                          )
                        else if (_overview!.sectors.value.isEmpty)
                          _EmptyCard(
                            icon: Icons.category_outlined,
                            text: l10n.noDataAvailable,
                          )
                        else
                          _SectorGrid(
                            sectors: _overview!.sectors.value,
                            enabled: !busy,
                            onTap: _loadSector,
                          ),
                        if (_invoiceListLoaded) ...[
                          const SizedBox(height: 24),
                          Semantics(
                            header: true,
                            child: Text(
                              _showingPendingInvoices
                                  ? l10n.pendingInvoicesTitle
                                  : l10n.sectorInvoicesTitle,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_invoices.isEmpty)
                            _EmptyCard(
                              icon: Icons.receipt_long_outlined,
                              text: _showingPendingInvoices
                                  ? l10n.noInvoicesToValidate
                                  : l10n.noInvoicesInCategory,
                            )
                          else
                            ..._invoices.indexed.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _InvoiceTile(
                                  key: Key('efatura-invoice-${entry.$1}'),
                                  invoice: entry.$2,
                                ),
                              ),
                            ),
                        ],
                        const SizedBox(height: 18),
                        OutlinedButton.icon(
                          key: const Key('efatura-manual-refresh'),
                          onPressed: busy ? null : _refresh,
                          icon: busy
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh),
                          label: Text(busy ? l10n.updating : l10n.refresh),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _ConnectCard extends StatelessWidget {
  const _ConnectCard({
    required this.formKey,
    required this.readiness,
    required this.nifController,
    required this.passwordController,
    required this.onConnect,
    required this.onSelectIdentity,
    required this.onSelectCipherCertificate,
  });

  final GlobalKey<FormState> formKey;
  final EfaturaRuntimeReadiness? readiness;
  final TextEditingController nifController;
  final TextEditingController passwordController;
  final VoidCallback onConnect;
  final VoidCallback? onSelectIdentity;
  final VoidCallback? onSelectCipherCertificate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final identityReady = readiness?.hasClientIdentity == true;
    final cipherReady = readiness?.hasCipherCertificate == true;
    return Card(
      child: Form(
        key: formKey,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.connectPortalTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('efatura-nif'),
                controller: nifController,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.username],
                maxLength: 9,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: l10n.nif),
                validator: (value) =>
                    RegExp(r'^\d{9}$').hasMatch(value?.trim() ?? '')
                    ? null
                    : l10n.invalidNif,
              ),
              TextFormField(
                key: const Key('efatura-password'),
                controller: passwordController,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) {
                  if (identityReady && cipherReady) onConnect();
                },
                decoration: InputDecoration(labelText: l10n.password),
                validator: (value) =>
                    (value?.isNotEmpty ?? false) ? null : l10n.passwordRequired,
              ),
              const SizedBox(height: 14),
              if (!identityReady && onSelectIdentity != null)
                TextButton.icon(
                  key: const Key('efatura-select-identity'),
                  onPressed: onSelectIdentity,
                  icon: const Icon(Icons.badge_outlined),
                  label: Text(l10n.selectDeviceCertificate),
                ),
              if (!cipherReady && onSelectCipherCertificate != null)
                TextButton.icon(
                  key: const Key('efatura-select-cipher-certificate'),
                  onPressed: onSelectCipherCertificate,
                  icon: const Icon(Icons.vpn_key_outlined),
                  label: Text(l10n.selectAtPublicKey),
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                key: const Key('efatura-connect'),
                onPressed: identityReady && cipherReady ? onConnect : null,
                icon: const Icon(Icons.lock_outline),
                label: Text(l10n.connectEfatura),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.overview});

  final EfaturaOverview overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final benefit = overview.provisionalBenefitCents.valueOrNull;
    final pending = overview.pendingValidation.valueOrNull;
    final revenue = overview.pendingRevenueAssociation.valueOrNull;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.overviewTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.provisionalTaxBenefit,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                benefit == null
                    ? l10n.unavailable
                    : TaxyFormatters.euros(context, benefit),
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(color: scheme.primary),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _Metric(
                  label: l10n.invoicesToValidate,
                  value: pending?.toString() ?? l10n.unavailable,
                  icon: Icons.task_alt_outlined,
                ),
                _Metric(
                  label: l10n.invoicesToAssociate,
                  value: revenue?.toString() ?? l10n.unavailable,
                  icon: Icons.link_outlined,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (pending == 0)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l10n.noInvoicesToValidate)),
                ],
              )
            else if (pending != null && pending > 0)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l10n.readOnlyNoValidation)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

final class _IrsEvidenceCard extends StatelessWidget {
  const _IrsEvidenceCard({required this.evidence});

  final EfaturaIrsEvidence evidence;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String money(AtValue<int> value) => value.isAvailable
        ? TaxyFormatters.euros(context, value.value)
        : l10n.unavailable;
    return Card(
      key: const Key('efatura-irs-evidence'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calculate_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.irsPredictionDataTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _EvidenceRow(
              label: l10n.officialProvisionalBenefit,
              value: money(evidence.officialProvisionalBenefitCents),
            ),
            _EvidenceRow(
              label: l10n.listedExpenses,
              value: money(evidence.listedExpensesCents),
            ),
            _EvidenceRow(
              label: l10n.listedVat,
              value: money(evidence.listedVatCents),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.irsPredictionDisclaimer,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 16),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

final class _PartialSuccessBanner extends StatelessWidget {
  const _PartialSuccessBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

final class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 170, maxWidth: 280),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.titleLarge),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );
}

final class _SectorGrid extends StatelessWidget {
  const _SectorGrid({
    required this.sectors,
    required this.enabled,
    required this.onTap,
  });

  final List<AtExpenseSector> sectors;
  final bool enabled;
  final ValueChanged<AtExpenseSector> onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final twoColumns = constraints.maxWidth >= 620;
      final width = twoColumns
          ? (constraints.maxWidth - 10) / 2
          : constraints.maxWidth;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: sectors
            .map(
              (sector) => SizedBox(
                width: width,
                child: _SectorTile(
                  sector: sector,
                  enabled: enabled,
                  onTap: () => onTap(sector),
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

final class _SectorTile extends StatelessWidget {
  const _SectorTile({
    required this.sector,
    required this.enabled,
    required this.onTap,
  });

  final AtExpenseSector sector;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = _sectorLabel(l10n, sector);
    final benefit = sector.provisionalBenefitCents.valueOrNull;
    final expenses = sector.totalExpensesCents.valueOrNull;
    final count = sector.invoiceCount.valueOrNull;
    final details = <String>[
      if (expenses != null)
        '${l10n.listedExpenses}: ${TaxyFormatters.euros(context, expenses)}',
      if (benefit != null)
        '${l10n.provisionalTaxBenefit}: ${TaxyFormatters.euros(context, benefit)}',
      if (count != null) l10n.invoiceCount(count),
    ];
    if (details.isEmpty) details.add(l10n.unavailable);
    return Semantics(
      button: true,
      label: '$label${details.isEmpty ? '' : ', ${details.join(', ')}'}',
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          key: Key('sector-${sector.code}'),
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.category_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        details.isEmpty
                            ? l10n.noActivityInCategory
                            : details.join(' · '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _InvoiceTile extends StatelessWidget {
  const _InvoiceTile({super.key, required this.invoice});

  final EfaturaInvoice invoice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final issuer = invoice.issuerDisplayName ?? l10n.issuerUnavailable;
    final sector = invoice.sectorCode == null
        ? invoice.sectorLabel
        : _sectorLabel(
            l10n,
            AtExpenseSector(
              code: invoice.sectorCode!,
              label: invoice.sectorLabel,
            ),
          );
    final date = TaxyFormatters.date(context, invoice.date);
    final amount = TaxyFormatters.euros(context, invoice.totalCents);
    return Semantics(
      label: '$issuer, $date, $amount${sector == null ? '' : ', $sector'}',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.receipt_long_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      issuer,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text([date, ?sector].join(' · ')),
                    const SizedBox(height: 8),
                    Text(
                      amount,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error, required this.onRetry});

  final EfaturaServiceException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _errorTitle(l10n, error.kind),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(_errorMessage(l10n, error.kind)),
            const SizedBox(height: 10),
            TextButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}

final class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    ),
  );
}

final class _OverviewSkeleton extends StatelessWidget {
  const _OverviewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHigh;
    return Semantics(
      liveRegion: true,
      label: AppLocalizations.of(context).connecting,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 150,
                height: 18,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 220,
                height: 34,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 16),
              const LinearProgressIndicator(minHeight: 3),
            ],
          ),
        ),
      ),
    );
  }
}

String _sectorLabel(AppLocalizations l10n, AtExpenseSector sector) =>
    switch (sector.code) {
      'C01' => l10n.sectorCarRepairs,
      'C02' => l10n.sectorMotorcycleRepairs,
      'C03' => l10n.sectorHospitality,
      'C04' => l10n.sectorHairdressing,
      'C05' => l10n.sectorHealth,
      'C06' => l10n.sectorEducation,
      'C07' => l10n.sectorHousing,
      'C08' => l10n.sectorNursingHomes,
      'C09' => l10n.sectorVeterinary,
      'C10' => l10n.sectorPublicTransport,
      'C11' => l10n.sectorGyms,
      'C12' => l10n.sectorNewspapers,
      'C13' => l10n.sectorDomesticServices,
      'C99' => l10n.sectorOther,
      _ => sector.label ?? l10n.noDataAvailable,
    };

String _errorTitle(AppLocalizations l10n, EfaturaFailureKind kind) =>
    switch (kind) {
      EfaturaFailureKind.notConfigured => l10n.notConfiguredTitle,
      EfaturaFailureKind.authentication => l10n.authErrorTitle,
      EfaturaFailureKind.authorization => l10n.authorizationErrorTitle,
      EfaturaFailureKind.operationUnavailable => l10n.operationUnavailableTitle,
      EfaturaFailureKind.rateLimited => l10n.rateLimitedTitle,
      EfaturaFailureKind.network ||
      EfaturaFailureKind.tls => l10n.networkErrorTitle,
      EfaturaFailureKind.serviceUnavailable ||
      EfaturaFailureKind.ntp => l10n.serviceErrorTitle,
      EfaturaFailureKind.expired => l10n.sessionExpiredTitle,
      EfaturaFailureKind.soap ||
      EfaturaFailureKind.business ||
      EfaturaFailureKind.parsing => l10n.parsingErrorTitle,
      EfaturaFailureKind.unknown => l10n.genericErrorTitle,
    };

String _errorMessage(AppLocalizations l10n, EfaturaFailureKind kind) =>
    switch (kind) {
      EfaturaFailureKind.authentication => l10n.authErrorMessage,
      EfaturaFailureKind.authorization => l10n.authorizationErrorMessage,
      EfaturaFailureKind.operationUnavailable =>
        l10n.operationUnavailableMessage,
      EfaturaFailureKind.rateLimited => l10n.rateLimitedMessage,
      EfaturaFailureKind.network ||
      EfaturaFailureKind.tls => l10n.networkErrorMessage,
      EfaturaFailureKind.serviceUnavailable ||
      EfaturaFailureKind.ntp => l10n.serviceErrorMessage,
      EfaturaFailureKind.expired => l10n.sessionExpiredMessage,
      EfaturaFailureKind.soap ||
      EfaturaFailureKind.business ||
      EfaturaFailureKind.parsing => l10n.parsingErrorMessage,
      EfaturaFailureKind.notConfigured ||
      EfaturaFailureKind.unknown => l10n.genericErrorMessage,
    };
