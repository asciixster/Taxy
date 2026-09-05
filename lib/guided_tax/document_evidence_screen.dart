import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/taxy_formatters.dart';
import 'document_evidence.dart';

final class DocumentEvidenceScreen extends StatefulWidget {
  const DocumentEvidenceScreen({
    super.key,
    required this.taxYear,
    required this.repository,
  });

  final int taxYear;
  final GuidedDocumentEvidenceRepository repository;

  @override
  State<DocumentEvidenceScreen> createState() => _DocumentEvidenceScreenState();
}

final class _DocumentEvidenceScreenState extends State<DocumentEvidenceScreen> {
  List<GuidedDocumentEvidence> _items = const [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final values = await widget.repository.load(widget.taxYear);
      if (!mounted) return;
      setState(() {
        _items = values;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'load';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.guidedDocumentsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                Text(
                  l10n.guidedDocumentsIntro,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.guidedDocumentsPrivacy,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(l10n.savedDataLoadError),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                for (final type in GuidedDocumentType.values) ...[
                  _DocumentTile(
                    type: type,
                    evidence: _forType(type),
                    enabled: !_saving,
                    onConfirm: () => _confirm(type),
                    onRemove: _forType(type) == null
                        ? null
                        : () => _remove(type),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }

  GuidedDocumentEvidence? _forType(GuidedDocumentType type) {
    for (final item in _items) {
      if (item.type == type) return item;
    }
    return null;
  }

  Future<void> _confirm(GuidedDocumentType type) async {
    final l10n = AppLocalizations.of(context);
    final cents = await showDialog<int>(
      context: context,
      builder: (_) => _AmountConfirmationDialog(
        title: _label(l10n, type),
        prompt: l10n.guidedDocumentsConfirmValue,
        amountLabel: l10n.amountEuros,
        cancelLabel: l10n.cancel,
        saveLabel: l10n.save,
      ),
    );
    if (cents == null || !mounted) return;
    setState(() => _saving = true);
    try {
      await widget.repository.save(
        GuidedDocumentEvidence(
          type: type,
          taxYear: widget.taxYear,
          amountCents: cents,
          confirmedAt: DateTime.now().toUtc(),
        ),
      );
      await _load();
    } catch (_) {
      if (mounted) setState(() => _error = 'save');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove(GuidedDocumentType type) async {
    setState(() => _saving = true);
    try {
      await widget.repository.remove(widget.taxYear, type);
      await _load();
    } catch (_) {
      if (mounted) setState(() => _error = 'remove');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

final class _AmountConfirmationDialog extends StatefulWidget {
  const _AmountConfirmationDialog({
    required this.title,
    required this.prompt,
    required this.amountLabel,
    required this.cancelLabel,
    required this.saveLabel,
  });

  final String title;
  final String prompt;
  final String amountLabel;
  final String cancelLabel;
  final String saveLabel;

  @override
  State<_AmountConfirmationDialog> createState() =>
      _AmountConfirmationDialogState();
}

final class _AmountConfirmationDialogState
    extends State<_AmountConfirmationDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Text(widget.title),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.prompt),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: widget.amountLabel,
            suffixText: '€',
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(widget.cancelLabel),
      ),
      FilledButton(
        onPressed: () {
          final value = _parseCents(_controller.text);
          if (value != null) Navigator.pop(context, value);
        },
        child: Text(widget.saveLabel),
      ),
    ],
  );

  int? _parseCents(String source) {
    final normalized = source.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(normalized)) return null;
    final parts = normalized.split('.');
    final euros = int.parse(parts.first);
    final fraction = parts.length == 1 ? '00' : parts.last.padRight(2, '0');
    return euros * 100 + int.parse(fraction);
  }
}

final class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.type,
    required this.evidence,
    required this.enabled,
    required this.onConfirm,
    required this.onRemove,
  });

  final GuidedDocumentType type;
  final GuidedDocumentEvidence? evidence;
  final bool enabled;
  final VoidCallback onConfirm;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const CircleAvatar(child: Icon(Icons.description_outlined)),
        title: Text(_label(l10n, type)),
        subtitle: Text(
          evidence == null
              ? l10n.guidedDocumentsNotConfirmed
              : l10n.guidedDocumentsConfirmedAmount(
                  TaxyFormatters.euros(context, evidence!.amountCents),
                ),
        ),
        trailing: evidence == null
            ? const Icon(Icons.chevron_right)
            : IconButton(
                tooltip: l10n.remove,
                onPressed: enabled ? onRemove : null,
                icon: const Icon(Icons.delete_outline),
              ),
        onTap: enabled ? onConfirm : null,
      ),
    );
  }
}

String _label(AppLocalizations l10n, GuidedDocumentType type) => switch (type) {
  GuidedDocumentType.employmentIncomeStatement => l10n.guidedDocumentEmployment,
  GuidedDocumentType.withholdingProof => l10n.guidedDocumentWithholding,
  GuidedDocumentType.socialSecurityProof => l10n.guidedDocumentSocialSecurity,
};
