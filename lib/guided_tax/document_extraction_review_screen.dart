import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import 'document_evidence.dart';
import 'secure_document_capture.dart';

final class DocumentExtractionReviewScreen extends StatefulWidget {
  const DocumentExtractionReviewScreen({
    super.key,
    required this.document,
    required this.captureGateway,
    required this.captureRepository,
    required this.evidenceRepository,
  });

  final CapturedTaxDocument document;
  final TaxDocumentCaptureGateway captureGateway;
  final CapturedTaxDocumentRepository captureRepository;
  final GuidedDocumentEvidenceRepository evidenceRepository;

  @override
  State<DocumentExtractionReviewScreen> createState() =>
      _DocumentExtractionReviewScreenState();
}

final class _DocumentExtractionReviewScreenState
    extends State<DocumentExtractionReviewScreen> {
  static const _screenChannel = MethodChannel('pt.taxy.app/efatura');
  final Map<TaxDocumentFieldType, TextEditingController> _controllers = {};
  final Set<TaxDocumentFieldType> _selected = {};
  bool _saving = false;
  String? _error;

  TaxDocumentExtraction get _extraction => widget.document.extraction!;

  @override
  void initState() {
    super.initState();
    _screenChannel
        .invokeMethod<void>('setScreenSecure', true)
        .catchError((_) {});
    for (final field in _extraction.fields) {
      final value = field.normalizedCandidate;
      _controllers[field.type] = TextEditingController(
        text: switch (field.type) {
          TaxDocumentFieldType.taxYear => value?.toString() ?? '',
          TaxDocumentFieldType.employmentGross ||
          TaxDocumentFieldType.irsWithholding ||
          TaxDocumentFieldType.socialSecurityContributions =>
            value is int
                ? '${value ~/ 100},${(value % 100).toString().padLeft(2, '0')}'
                : '',
          TaxDocumentFieldType.employerName => value?.toString() ?? '',
        },
      );
      if (value != null &&
          field.confidence != ExtractionConfidence.low &&
          field.type != TaxDocumentFieldType.taxYear &&
          field.type != TaxDocumentFieldType.employerName) {
        _selected.add(field.type);
      }
    }
  }

  @override
  void dispose() {
    // The parent document-evidence route owns FLAG_SECURE for the entire
    // capture/review flow. Clearing it here would briefly expose that route
    // when this screen is popped.
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unsupported =
        _extraction.documentTypeCandidate ==
        TaxDocumentTypeCandidate.unsupported;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.documentFoundValues),
        actions: [
          IconButton(
            tooltip: l10n.documentDelete,
            onPressed: _saving ? null : _delete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _DocumentPreview(
            future: widget.captureGateway.preview(widget.document.id),
          ),
          const SizedBox(height: 16),
          Text(
            _documentTypeLabel(l10n, _extraction.documentTypeCandidate),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(l10n.documentReviewIntro),
          const SizedBox(height: 4),
          Text(
            l10n.documentConfirmExplanation,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (unsupported) ...[
            const SizedBox(height: 16),
            Semantics(
              label: l10n.taxReviewNotIncluded,
              child: Card(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.documentTypeUnsupported),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 18),
            for (final field in _extraction.fields)
              if (field.type != TaxDocumentFieldType.employerName)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FieldReviewCard(
                    field: field,
                    controller: _controllers[field.type]!,
                    selected: _selected.contains(field.type),
                    onChanged: () => setState(() {}),
                    onSelected: field.type == TaxDocumentFieldType.taxYear
                        ? null
                        : (selected) => setState(() {
                            if (selected) {
                              _selected.add(field.type);
                            } else {
                              _selected.remove(field.type);
                            }
                          }),
                  ),
                ),
            Text(
              l10n.documentPartialHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (_yearMismatch case final year?) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                l10n.documentYearMismatch(year),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                l10n.documentReadFailure,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (!unsupported)
            FilledButton.icon(
              key: const Key('document-review-confirm'),
              onPressed: _saving || _yearMismatch != null || _selected.isEmpty
                  ? null
                  : _confirm,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.verified_outlined),
              label: Text(l10n.documentConfirmValues),
            ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _saving ? null : _delete,
            child: Text(l10n.documentDelete),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.documentOriginalNotStored,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  int? get _yearMismatch {
    final controller = _controllers[TaxDocumentFieldType.taxYear];
    if (controller == null || controller.text.trim().isEmpty) return null;
    final year = int.tryParse(controller.text.trim());
    if (year != null && year != widget.document.taxYear) return year;
    return null;
  }

  Future<void> _confirm() async {
    final values = <GuidedDocumentType, int>{};
    for (final type in _selected) {
      final documentType = _evidenceType(type);
      if (documentType == null) continue;
      final cents = parsePortugueseMoneyCents(_controllers[type]!.text);
      if (cents == null) {
        setState(() => _error = 'invalid_value');
        return;
      }
      values[documentType] = cents;
    }
    if (values.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final before = await widget.evidenceRepository.load(
      widget.document.taxYear,
    );
    try {
      for (final entry in values.entries) {
        await widget.evidenceRepository.save(
          GuidedDocumentEvidence(
            type: entry.key,
            taxYear: widget.document.taxYear,
            amountCents: entry.value,
            confirmedAt: DateTime.now().toUtc(),
          ),
        );
      }
      await widget.captureGateway.confirmAndDeleteRaw(widget.document.id);
      await widget.captureRepository.remove(widget.document.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      // Fail closed: if raw deletion fails, do not leave newly confirmed values
      // active. Restore the exact evidence state that existed before review.
      for (final type in values.keys) {
        await widget.evidenceRepository.remove(widget.document.taxYear, type);
        for (final previous in before.where((item) => item.type == type)) {
          await widget.evidenceRepository.save(previous);
        }
      }
      if (mounted) setState(() => _error = 'confirm_failed');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.documentDeleteTitle),
        content: Text(l10n.documentDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.documentDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await widget.captureGateway.delete(widget.document.id);
      await widget.captureRepository.remove(widget.document.id);
      if (mounted) Navigator.pop(context, false);
    } catch (_) {
      if (mounted) setState(() => _error = 'delete_failed');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

final class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({required this.future});

  final Future<Uint8List?> future;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.documentPreview,
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: SizedBox(
            height: 220,
            child: FutureBuilder<Uint8List?>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final bytes = snapshot.data;
                if (bytes == null || bytes.isEmpty) {
                  return Center(child: Text(l10n.documentPreviewUnavailable));
                }
                return Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

final class _FieldReviewCard extends StatelessWidget {
  const _FieldReviewCard({
    required this.field,
    required this.controller,
    required this.selected,
    required this.onChanged,
    required this.onSelected,
  });

  final TaxDocumentExtractedField field;
  final TextEditingController controller;
  final bool selected;
  final VoidCallback onChanged;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final confidence = _confidenceLabel(l10n, field.confidence);
    return Semantics(
      label: '${_fieldLabel(l10n, field.type)}. $confidence',
      checked: onSelected == null ? null : selected,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (onSelected != null)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: selected,
                  onChanged: (value) => onSelected?.call(value ?? false),
                  title: Text(_fieldLabel(l10n, field.type)),
                  subtitle: Text(confidence),
                  controlAffinity: ListTileControlAffinity.leading,
                )
              else ...[
                Text(
                  _fieldLabel(l10n, field.type),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(confidence),
              ],
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                onChanged: (_) => onChanged(),
                enabled: onSelected == null || selected,
                keyboardType: field.type == TaxDocumentFieldType.taxYear
                    ? TextInputType.number
                    : const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _fieldLabel(l10n, field.type),
                  suffixText: field.type == TaxDocumentFieldType.taxYear
                      ? null
                      : '€',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

GuidedDocumentType? _evidenceType(TaxDocumentFieldType type) => switch (type) {
  TaxDocumentFieldType.employmentGross =>
    GuidedDocumentType.employmentIncomeStatement,
  TaxDocumentFieldType.irsWithholding => GuidedDocumentType.withholdingProof,
  TaxDocumentFieldType.socialSecurityContributions =>
    GuidedDocumentType.socialSecurityProof,
  TaxDocumentFieldType.taxYear || TaxDocumentFieldType.employerName => null,
};

String _fieldLabel(AppLocalizations l10n, TaxDocumentFieldType type) =>
    switch (type) {
      TaxDocumentFieldType.employmentGross => l10n.documentValueEmployment,
      TaxDocumentFieldType.irsWithholding => l10n.documentValueWithholding,
      TaxDocumentFieldType.socialSecurityContributions =>
        l10n.documentValueSocialSecurity,
      TaxDocumentFieldType.taxYear => l10n.documentValueTaxYear,
      TaxDocumentFieldType.employerName => l10n.documentType,
    };

String _confidenceLabel(
  AppLocalizations l10n,
  ExtractionConfidence confidence,
) => switch (confidence) {
  ExtractionConfidence.high => l10n.documentConfidenceHigh,
  ExtractionConfidence.medium => l10n.documentConfidenceMedium,
  ExtractionConfidence.low => l10n.documentConfidenceLow,
};

String _documentTypeLabel(
  AppLocalizations l10n,
  TaxDocumentTypeCandidate type,
) => switch (type) {
  TaxDocumentTypeCandidate.employmentStatement => l10n.documentTypeEmployment,
  TaxDocumentTypeCandidate.withholdingProof => l10n.documentTypeWithholding,
  TaxDocumentTypeCandidate.socialSecurityProof =>
    l10n.documentTypeSocialSecurity,
  TaxDocumentTypeCandidate.combinedEmploymentStatement =>
    l10n.documentTypeCombined,
  TaxDocumentTypeCandidate.unsupported => l10n.documentTypeUnsupported,
  TaxDocumentTypeCandidate.unknown => l10n.documentTypeUnknown,
};
