import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../l10n/taxy_formatters.dart';
import 'document_evidence.dart';
import 'document_extraction_review_screen.dart';
import 'secure_document_capture.dart';

final class DocumentEvidenceScreen extends StatefulWidget {
  const DocumentEvidenceScreen({
    super.key,
    required this.taxYear,
    required this.repository,
    this.captureGateway,
    this.captureRepository,
    this.extractor,
  });

  final int taxYear;
  final GuidedDocumentEvidenceRepository repository;
  final TaxDocumentCaptureGateway? captureGateway;
  final CapturedTaxDocumentRepository? captureRepository;
  final TaxDocumentExtractor? extractor;

  @override
  State<DocumentEvidenceScreen> createState() => _DocumentEvidenceScreenState();
}

final class _DocumentEvidenceScreenState extends State<DocumentEvidenceScreen> {
  static const _screenChannel = MethodChannel('pt.taxy.app/efatura');
  List<GuidedDocumentEvidence> _items = const [];
  List<CapturedTaxDocument> _pending = const [];
  bool _loading = true;
  bool _saving = false;
  bool _processing = false;
  String? _error;
  late final TaxDocumentCaptureGateway _captureGateway;
  late final CapturedTaxDocumentRepository _captureRepository;
  late final TaxDocumentExtractor _extractor;

  @override
  void initState() {
    super.initState();
    _captureGateway =
        widget.captureGateway ?? AndroidTaxDocumentCaptureGateway();
    _captureRepository =
        widget.captureRepository ?? LocalCapturedTaxDocumentRepository();
    _extractor =
        widget.extractor ?? const PortugueseEmploymentDocumentExtractor();
    _screenChannel
        .invokeMethod<void>('setScreenSecure', true)
        .catchError((_) {});
    _captureGateway.cleanupExpired().catchError((_) => 0);
    _load();
  }

  @override
  void dispose() {
    _screenChannel
        .invokeMethod<void>('setScreenSecure', false)
        .catchError((_) {});
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final values = await widget.repository.load(widget.taxYear);
      final pending = (await _captureRepository.load())
          .where(
            (document) =>
                document.taxYear == widget.taxYear &&
                document.state == CapturedDocumentState.reviewRequired &&
                document.extraction != null,
          )
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _items = values;
        _pending = pending;
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
                _CaptureActions(
                  processing: _processing,
                  onTakePhoto: () => _capture(true),
                  onChooseFile: () => _capture(false),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.documentCaptureLimits,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.guidedDocumentsIntro,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.documentCapturePrivacyLocal,
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
                      child: Text(_captureError(l10n, _error!)),
                    ),
                  ),
                ],
                if (_processing) ...[
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    label: l10n.documentProcessing,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Text(l10n.documentProcessing)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                for (final document in _pending) ...[
                  const SizedBox(height: 10),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.fact_check_outlined),
                      title: Text(l10n.documentFoundValues),
                      subtitle: Text(l10n.taxReviewNeedsReview),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _processing ? null : () => _review(document),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  l10n.documentManualEntry,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
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

  Future<void> _capture(bool camera) async {
    setState(() {
      _processing = true;
      _error = null;
    });
    try {
      final result = camera
          ? await _captureGateway.takePhoto(widget.taxYear)
          : await _captureGateway.chooseFile(widget.taxYear);
      if (result == null || !mounted) return;
      final extraction = _extractor.extract(result.recognizedText);
      // OCR text is deliberately discarded here. Only normalized candidates
      // and stable warning categories can be persisted.
      final document = result.document.copyWith(
        state: CapturedDocumentState.reviewRequired,
        extraction: extraction,
      );
      await _captureRepository.save(document);
      if (!mounted) return;
      await _review(document);
    } on MissingPluginException {
      if (mounted) setState(() => _error = 'MissingPluginException');
    } on PlatformException catch (error) {
      if (mounted) setState(() => _error = error.code);
    } catch (_) {
      if (mounted) setState(() => _error = 'processing_failed');
    } finally {
      if (mounted) {
        setState(() => _processing = false);
        await _load();
      }
    }
  }

  Future<void> _review(CapturedTaxDocument document) async {
    final confirmed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentExtractionReviewScreen(
          document: document,
          captureGateway: _captureGateway,
          captureRepository: _captureRepository,
          evidenceRepository: widget.repository,
        ),
      ),
    );
    if (!mounted) return;
    if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).documentSavedAndDeleted),
        ),
      );
    }
    await _load();
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

final class _CaptureActions extends StatelessWidget {
  const _CaptureActions({
    required this.processing,
    required this.onTakePhoto,
    required this.onChooseFile,
  });

  final bool processing;
  final VoidCallback onTakePhoto;
  final VoidCallback onChooseFile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final vertical = constraints.maxWidth < 380;
        final photo = FilledButton.icon(
          key: const Key('document-capture-photo'),
          onPressed: processing ? null : onTakePhoto,
          icon: const Icon(Icons.photo_camera_outlined),
          label: Text(l10n.documentTakePhoto),
        );
        final file = OutlinedButton.icon(
          key: const Key('document-capture-file'),
          onPressed: processing ? null : onChooseFile,
          icon: const Icon(Icons.upload_file_outlined),
          label: Text(l10n.documentChooseFile),
        );
        return vertical
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [photo, const SizedBox(height: 8), file],
              )
            : Row(
                children: [
                  Expanded(child: photo),
                  const SizedBox(width: 10),
                  Expanded(child: file),
                ],
              );
      },
    );
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

String _captureError(AppLocalizations l10n, String code) => switch (code) {
  'FILE_TOO_LARGE' => l10n.documentTooLarge,
  'PAGE_LIMIT' => l10n.documentTooManyPages,
  'UNSUPPORTED_FILE' ||
  'MIME_MISMATCH' ||
  'INVALID_IMAGE' => l10n.documentUnsupportedFile,
  'MissingPluginException' => l10n.documentCaptureUnavailable,
  _ => l10n.documentReadFailure,
};
