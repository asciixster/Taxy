import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/taxy_formatters.dart';
import '../../efatura/infrastructure/efatura_screen_protection.dart';
import '../domain/official_prefill_confirmation.dart';
import '../domain/official_prefill_evidence.dart';
import '../infrastructure/official_prefill_backend_bridge.dart';

final class OfficialPrefillScreen extends StatefulWidget {
  const OfficialPrefillScreen({
    super.key,
    required this.taxYear,
    required this.gateway,
  });

  final int taxYear;
  final OfficialPrefillGateway gateway;

  @override
  State<OfficialPrefillScreen> createState() => _OfficialPrefillScreenState();
}

final class _OfficialPrefillScreenState extends State<OfficialPrefillScreen> {
  final _nif = TextEditingController();
  final _password = TextEditingController();
  final _selected = <OfficialPrefillField>{};
  final _protection = AndroidEfaturaScreenProtection();
  OfficialPrefillEvidence? _evidence;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _protection.setScreenSecure(true).catchError((_) {});
  }

  @override
  void dispose() {
    _protection.setScreenSecure(false).catchError((_) {});
    _nif.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.officialPrefillTitle)),
      body: ListView(
        key: const Key('official-prefill-screen'),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            l10n.officialPrefillHeading,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(l10n.officialPrefillPrivacy),
          const SizedBox(height: 16),
          if (_evidence == null) _login(l10n) else _review(l10n),
        ],
      ),
    );
  }

  Widget _login(AppLocalizations l10n) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        key: const Key('official-prefill-nif'),
        controller: _nif,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.username],
        maxLength: 9,
        decoration: InputDecoration(labelText: l10n.nif),
      ),
      const SizedBox(height: 8),
      TextField(
        key: const Key('official-prefill-password'),
        controller: _password,
        obscureText: true,
        enableSuggestions: false,
        autocorrect: false,
        autofillHints: const [AutofillHints.password],
        decoration: InputDecoration(labelText: l10n.password),
      ),
      if (_error != null) ...[
        const SizedBox(height: 12),
        Semantics(
          liveRegion: true,
          child: Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!),
            ),
          ),
        ),
      ],
      const SizedBox(height: 16),
      FilledButton.icon(
        key: const Key('official-prefill-load'),
        onPressed: _loading ? null : _load,
        icon: _loading
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.cloud_download_outlined),
        label: Text(
          _loading ? l10n.officialPrefillLoading : l10n.officialPrefillAction,
        ),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(l10n.officialPrefillContinueManual),
      ),
    ],
  );

  Widget _review(AppLocalizations l10n) {
    final evidence = _evidence!;
    final totals = evidence.categoryATotals;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.officialPrefillFound,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final annex in evidence.annexes)
              Chip(label: Text('${l10n.officialPrefillAnnex} $annex')),
          ],
        ),
        const SizedBox(height: 12),
        if (evidence.hasCategoryA) ...[
          _field(
            field: OfficialPrefillField.employmentGross,
            title: l10n.documentValueEmployment,
            value: TaxyFormatters.euros(context, totals.grossIncomeCents),
          ),
          _field(
            field: OfficialPrefillField.withholding,
            title: l10n.documentValueWithholding,
            value: TaxyFormatters.euros(context, totals.withholdingCents),
          ),
          _field(
            field: OfficialPrefillField.socialSecurity,
            title: l10n.documentValueSocialSecurity,
            value: TaxyFormatters.euros(context, totals.socialSecurityCents),
          ),
        ],
        if (evidence.hasCategoryB)
          _field(
            field: OfficialPrefillField.selfEmploymentPresence,
            title: l10n.irsHistoryCategoryB,
            value: l10n.officialPrefillCategoryBUnsupported,
          ),
        const SizedBox(height: 10),
        Text(l10n.officialPrefillConfirmationNotice),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('official-prefill-confirm'),
          onPressed: _selected.isEmpty ? null : _confirm,
          child: Text(l10n.officialPrefillConfirm),
        ),
        TextButton(
          onPressed: () => setState(() {
            _evidence = null;
            _selected.clear();
          }),
          child: Text(l10n.officialPrefillUseAnotherLogin),
        ),
      ],
    );
  }

  Widget _field({
    required OfficialPrefillField field,
    required String title,
    required String value,
  }) => Card(
    child: CheckboxListTile(
      key: Key('official-prefill-${field.name}'),
      value: _selected.contains(field),
      onChanged: (checked) => setState(() {
        if (checked == true) {
          _selected.add(field);
        } else {
          _selected.remove(field);
        }
      }),
      title: Text(title),
      subtitle: Text(value),
      controlAffinity: ListTileControlAffinity.leading,
    ),
  );

  Future<void> _load() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final evidence = await widget.gateway.load(
        credentials: OfficialPrefillCredentials(
          nif: _nif.text.trim(),
          password: _password.text,
        ),
        taxYear: widget.taxYear,
      );
      _password.clear();
      if (!mounted) return;
      setState(() {
        _evidence = evidence;
        _loading = false;
      });
    } on OfficialPrefillException catch (error) {
      _password.clear();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = switch (error.kind) {
          OfficialPrefillFailureKind.authentication =>
            l10n.officialPrefillAuthenticationError,
          OfficialPrefillFailureKind.network =>
            l10n.officialPrefillNetworkError,
          OfficialPrefillFailureKind.parsing =>
            l10n.officialPrefillParsingError,
          _ => l10n.officialPrefillUnavailable,
        };
      });
    } catch (_) {
      _password.clear();
      if (mounted) {
        setState(() {
          _loading = false;
          _error = l10n.officialPrefillUnavailable;
        });
      }
    }
  }

  void _confirm() => Navigator.pop(
    context,
    OfficialPrefillConfirmation(
      taxYear: widget.taxYear,
      fields: Set.unmodifiable(_selected),
      evidence: _evidence!,
    ),
  );
}
