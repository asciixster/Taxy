import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/taxy_formatters.dart';
import '../domain/historical_tax_evidence.dart';
import '../infrastructure/dm3irs_history_bridge.dart';
import '../infrastructure/historical_tax_confirmation_repository.dart';

final class IrsHistoryPrefillScreen extends StatefulWidget {
  const IrsHistoryPrefillScreen({
    super.key,
    required this.targetYear,
    required this.gateway,
    required this.repository,
  });

  final int targetYear;
  final Dm3IrsHistoryGateway gateway;
  final HistoricalTaxConfirmationRepository repository;

  @override
  State<IrsHistoryPrefillScreen> createState() =>
      _IrsHistoryPrefillScreenState();
}

final class _IrsHistoryPrefillScreenState
    extends State<IrsHistoryPrefillScreen> {
  static const _sourceYear = 2024;
  final _nif = TextEditingController();
  final _password = TextEditingController();
  final _nifFocus = FocusNode();
  Dm3IrsReadiness? _readiness;
  HistoricalTaxEvidence? _evidence;
  final Set<HistoricalSuggestionField> _selected = {};
  final Map<HistoricalSuggestionField, TextEditingController> _edits = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.gateway.setScreenSecure(true);
    _loadReadiness();
  }

  @override
  void dispose() {
    widget.gateway.setScreenSecure(false);
    _nif.dispose();
    _password.dispose();
    _nifFocus.dispose();
    for (final controller in _edits.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadReadiness() async {
    try {
      final value = await widget.gateway.readiness();
      if (!mounted) return;
      setState(() {
        _readiness = value;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'unavailable';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.irsHistoryTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              key: const Key('irs-history-prefill'),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                Text(
                  l10n.irsHistoryIntro,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(l10n.irsHistoryPrivacy),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    label: l10n.irsHistoryFallback,
                    child: Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_errorText(l10n)),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (_evidence == null) _connection(l10n) else _review(l10n),
              ],
            ),
    );
  }

  Widget _connection(AppLocalizations l10n) {
    final readiness = _readiness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (readiness?.hasCredentials != true) ...[
          TextField(
            key: const Key('irs-history-nif'),
            controller: _nif,
            focusNode: _nifFocus,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.username],
            decoration: InputDecoration(labelText: l10n.nif),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('irs-history-password'),
            controller: _password,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(labelText: l10n.password),
          ),
          const SizedBox(height: 12),
        ] else
          TextButton(
            key: const Key('irs-history-change-login'),
            onPressed: _changeLogin,
            child: Text(l10n.irsHistoryChangeLogin),
          ),
        OutlinedButton.icon(
          key: const Key('irs-history-client-identity'),
          onPressed: _selectIdentity,
          icon: const Icon(Icons.verified_user_outlined),
          label: Text(l10n.irsHistorySelectIdentity),
        ),
        if (readiness?.hasCipherCertificate != true)
          OutlinedButton.icon(
            key: const Key('irs-history-public-certificate'),
            onPressed: _selectCipherCertificate,
            icon: const Icon(Icons.key_outlined),
            label: Text(l10n.irsHistorySelectPublicCertificate),
          ),
        const SizedBox(height: 8),
        FilledButton.icon(
          key: const Key('irs-history-load'),
          onPressed: _loading ? null : _connectAndLoad,
          icon: const Icon(Icons.history_rounded),
          label: Text(l10n.irsHistoryFind2024),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.irsHistoryContinueManual),
        ),
      ],
    );
  }

  Widget _review(AppLocalizations l10n) {
    final evidence = _evidence!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.irsHistoryFound,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(l10n.irsHistoryYearNotice(evidence.taxYear, widget.targetYear)),
        const SizedBox(height: 12),
        Text(
          l10n.irsHistoryAnnexesFound,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final annex in evidence.annexes)
              Chip(
                key: Key('irs-history-annex-${annex.name}'),
                label: Text(_annexLabel(l10n, annex)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        for (final suggestion in evidence.suggestions)
          _suggestionTile(l10n, suggestion),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('irs-history-confirm'),
          onPressed: _selected.isEmpty ? null : _confirm,
          child: Text(l10n.irsHistoryConfirmSelected),
        ),
        TextButton(
          key: const Key('irs-history-ignore'),
          onPressed: () =>
              Navigator.pop(context, const <HistoricalTaxConfirmation>[]),
          child: Text(l10n.irsHistoryIgnore),
        ),
        TextButton.icon(
          key: const Key('irs-history-disconnect'),
          onPressed: _disconnect,
          icon: const Icon(Icons.logout),
          label: Text(l10n.disconnect),
        ),
      ],
    );
  }

  String _annexLabel(AppLocalizations l10n, HistoricalTaxAnnex annex) =>
      switch (annex) {
        HistoricalTaxAnnex.a => l10n.irsHistoryAnnexA,
        HistoricalTaxAnnex.c => l10n.irsHistoryAnnexC,
        HistoricalTaxAnnex.h => l10n.irsHistoryAnnexH,
        HistoricalTaxAnnex.ss => l10n.irsHistoryAnnexSS,
      };

  Widget _suggestionTile(
    AppLocalizations l10n,
    HistoricalTaxSuggestion suggestion,
  ) {
    final editable =
        suggestion.field == HistoricalSuggestionField.activityCode ||
        suggestion.field == HistoricalSuggestionField.withholding;
    final controller = editable
        ? _edits.putIfAbsent(
            suggestion.field,
            () => TextEditingController(text: _editableValue(suggestion)),
          )
        : null;
    return Card(
      child: CheckboxListTile(
        key: Key('irs-history-${suggestion.field.name}'),
        value: _selected.contains(suggestion.field),
        onChanged: (value) => setState(() {
          if (value == true) {
            _selected.add(suggestion.field);
          } else {
            _selected.remove(suggestion.field);
          }
        }),
        title: Text(_label(l10n, suggestion.field)),
        subtitle: editable
            ? TextField(
                controller: controller,
                keyboardType:
                    suggestion.field == HistoricalSuggestionField.withholding
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.irsHistoryReviewValue,
                ),
              )
            : Text(_display(l10n, suggestion)),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Future<void> _selectIdentity() async {
    final selected = await widget.gateway.selectClientIdentity();
    if (selected) await _loadReadiness();
  }

  Future<void> _changeLogin() async {
    try {
      await widget.gateway.clear();
    } catch (_) {
      // Saving the replacement credential remains an overwrite operation.
    }
    if (!mounted) return;
    setState(() {
      _readiness = Dm3IrsReadiness(
        hasCredentials: false,
        hasClientIdentity: _readiness?.hasClientIdentity == true,
        hasCipherCertificate: _readiness?.hasCipherCertificate == true,
      );
      _error = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nifFocus.requestFocus();
    });
  }

  Future<void> _selectCipherCertificate() async {
    final selected = await widget.gateway.selectCipherCertificate();
    if (selected) await _loadReadiness();
  }

  Future<void> _connectAndLoad() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_readiness?.hasCredentials != true) {
        await widget.gateway.saveCredentials(_nif.text.trim(), _password.text);
        _password.clear();
      }
      final ready = await widget.gateway.readiness();
      if (!ready.ready) {
        throw const Dm3IrsException(
          Dm3IrsFailureKind.notConfigured,
          'not ready',
        );
      }
      final evidence = await widget.gateway.loadHistory(
        sourceYear: _sourceYear,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _readiness = ready;
        _evidence = evidence;
        _error = evidence == null ? 'none' : null;
      });
    } on Dm3IrsException catch (error) {
      if (!mounted) return;
      if (error.kind == Dm3IrsFailureKind.authentication) {
        try {
          await widget.gateway.clear();
        } catch (_) {
          // The next save overwrites the rejected credential even if cleanup
          // could not be completed here.
        }
        if (!mounted) return;
      }
      setState(() {
        _loading = false;
        _error = error.kind.name;
        if (error.kind == Dm3IrsFailureKind.authentication) {
          _readiness = Dm3IrsReadiness(
            hasCredentials: false,
            hasClientIdentity: _readiness?.hasClientIdentity == true,
            hasCipherCertificate: _readiness?.hasCipherCertificate == true,
          );
        }
      });
      if (error.kind == Dm3IrsFailureKind.authentication) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _nifFocus.requestFocus();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'unavailable';
        });
      }
    }
  }

  Future<void> _confirm() async {
    final evidence = _evidence!;
    final now = DateTime.now().toUtc();
    final confirmations = <HistoricalTaxConfirmation>[];
    for (final suggestion in evidence.suggestions.where(
      (item) => _selected.contains(item.field),
    )) {
      final value = _confirmedValue(suggestion);
      if (value == null) continue;
      confirmations.add(
        HistoricalTaxConfirmation(
          field: suggestion.field,
          value: value,
          sourceYear: evidence.taxYear,
          targetYear: widget.targetYear,
          userConfirmedAt: now,
          templateFingerprint: evidence.templateFingerprint,
        ),
      );
    }
    if (confirmations.isEmpty) return;
    await widget.repository.saveAll(widget.targetYear, confirmations);
    if (mounted) Navigator.pop(context, confirmations);
  }

  Future<void> _disconnect() async {
    await widget.gateway.clear();
    _nif.clear();
    _password.clear();
    if (!mounted) return;
    setState(() {
      _evidence = null;
      _selected.clear();
      _error = null;
      _readiness = const Dm3IrsReadiness(
        hasCredentials: false,
        hasClientIdentity: true,
        hasCipherCertificate: true,
      );
    });
  }

  Object? _confirmedValue(HistoricalTaxSuggestion suggestion) {
    final source = _edits[suggestion.field]?.text.trim();
    if (suggestion.field == HistoricalSuggestionField.activityCode) {
      return source != null && RegExp(r'^\d{4}$').hasMatch(source)
          ? source
          : null;
    }
    if (suggestion.field == HistoricalSuggestionField.withholding) {
      final normalized = source?.replaceAll(' ', '').replaceAll(',', '.');
      if (normalized == null ||
          !RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(normalized)) {
        return null;
      }
      final parts = normalized.split('.');
      return int.parse(parts.first) * 100 +
          (parts.length == 1 ? 0 : int.parse(parts.last.padRight(2, '0')));
    }
    return suggestion.value;
  }

  String _editableValue(HistoricalTaxSuggestion suggestion) =>
      suggestion.field == HistoricalSuggestionField.withholding
      ? ((suggestion.value as int) / 100)
            .toStringAsFixed(2)
            .replaceAll('.', ',')
      : suggestion.value.toString();

  String _label(AppLocalizations l10n, HistoricalSuggestionField field) =>
      switch (field) {
        HistoricalSuggestionField.categoryA => l10n.irsHistoryCategoryA,
        HistoricalSuggestionField.categoryB => l10n.irsHistoryCategoryB,
        HistoricalSuggestionField.categoryBRegime =>
          l10n.irsHistoryCategoryBRegime,
        HistoricalSuggestionField.activityCode => l10n.irsHistoryActivityCode,
        HistoricalSuggestionField.taxableProfit => l10n.irsHistoryTaxableProfit,
        HistoricalSuggestionField.withholding => l10n.irsHistoryWithholding,
      };

  String _display(AppLocalizations l10n, HistoricalTaxSuggestion suggestion) =>
      switch (suggestion.field) {
        HistoricalSuggestionField.categoryA ||
        HistoricalSuggestionField.categoryB => l10n.irsHistoryPresentIn2024,
        HistoricalSuggestionField.categoryBRegime =>
          l10n.irsHistoryOrganizedAccounting,
        HistoricalSuggestionField.taxableProfit => TaxyFormatters.euros(
          context,
          suggestion.value as int,
        ),
        _ => suggestion.value.toString(),
      };

  String _errorText(AppLocalizations l10n) => switch (_error) {
    'none' || 'noDeclaration' => l10n.irsHistoryNone,
    'unknownTemplate' || 'invalidDocument' => l10n.irsHistoryUnknownTemplate,
    'authentication' => l10n.irsHistoryAuthenticationError,
    'notConfigured' => l10n.irsHistoryConfigurationError,
    'network' => l10n.irsHistoryNetworkError,
    'unavailable' => l10n.irsHistoryServiceError,
    _ => l10n.irsHistoryFallback,
  };
}
