import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/internal_beta_build_info.dart';
import '../l10n/app_localizations.dart';
import '../l10n/language_controller.dart';
import '../l10n/theme_controller.dart';
import '../state/providers.dart';

import 'package:flutter/services.dart';

final class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.languageController,
    this.themeController,
  });

  final LanguageController languageController;
  final ThemeController? themeController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.language,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.languageDescription,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: RadioGroup<LanguagePreference>(
              groupValue: languageController.preference,
              onChanged: (value) {
                if (value != null) languageController.select(value);
              },
              child: Column(
                children: [
                  _LanguageTile(
                    key: const Key('language-automatic'),
                    value: LanguagePreference.automatic,
                    label: l10n.languageAutomatic,
                    subtitle: l10n.languageSystemHint,
                  ),
                  const Divider(height: 1),
                  _LanguageTile(
                    key: const Key('language-portuguese'),
                    value: LanguagePreference.portuguese,
                    label: l10n.languagePortuguese,
                  ),
                  const Divider(height: 1),
                  _LanguageTile(
                    key: const Key('language-english'),
                    value: LanguagePreference.english,
                    label: l10n.languageEnglish,
                  ),
                ],
              ),
            ),
          ),
          if (themeController != null) ...[
            const SizedBox(height: 24),
            Semantics(
              header: true,
              child: Text(
                l10n.appearance,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: RadioGroup<ThemePreference>(
                groupValue: themeController!.preference,
                onChanged: (value) {
                  if (value != null) themeController!.select(value);
                },
                child: Column(
                  children: [
                    RadioListTile(
                      value: ThemePreference.system,
                      title: Text(l10n.themeSystem),
                    ),
                    const Divider(height: 1),
                    RadioListTile(
                      value: ThemePreference.light,
                      title: Text(l10n.themeLight),
                    ),
                    const Divider(height: 1),
                    RadioListTile(
                      value: ThemePreference.dark,
                      title: Text(l10n.themeDark),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Semantics(
            header: true,
            child: Text(
              l10n.privacyAndSecurity,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.privacyIntro),
                  const SizedBox(height: 10),
                  Text(l10n.privacyEfatura),
                  const SizedBox(height: 10),
                  Text(l10n.privacySnapshots),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Semantics(
            header: true,
            child: Text(
              l10n.diagnostics,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.copy_outlined),
                  title: Text(l10n.copyDiagnostics),
                  subtitle: Text(l10n.diagnosticsNotice),
                  onTap: () => _copyDiagnostics(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.feedback_outlined),
                  title: Text(l10n.sendFeedback),
                  onTap: () => _copyFeedback(context),
                ),
              ],
            ),
          ),
          if (InternalBetaBuildInfo.isInternalBeta) ...[
            const SizedBox(height: 24),
            Semantics(
              header: true,
              child: Text(
                l10n.internalBetaBuild,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              key: const Key('internal-beta-build-info'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.appVersion}: ${InternalBetaBuildInfo.appVersion}+${InternalBetaBuildInfo.buildNumber}',
                    ),
                    Text(
                      '${l10n.gitRevision}: ${InternalBetaBuildInfo.gitShortSha}',
                    ),
                    Text(
                      '${l10n.environment}: ${InternalBetaBuildInfo.environment}',
                    ),
                    Text('${l10n.apiHost}: ${InternalBetaBuildInfo.apiHost}'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _copyDiagnostics(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    int? activeYear;
    try {
      activeYear = (await ProviderScope.containerOf(
        context,
      ).read(productStateProvider.future)).profile.activeTaxYear;
    } on Object {
      activeYear = null;
    }
    final value = <String>[
      'Taxy ${InternalBetaBuildInfo.appVersion}+${InternalBetaBuildInfo.buildNumber}',
      'revision=${InternalBetaBuildInfo.gitShortSha}',
      'environment=${InternalBetaBuildInfo.environment}',
      'api=${InternalBetaBuildInfo.apiHost}',
      'activeTaxYear=${activeYear ?? 'unavailable'}',
      'engine=rules-bundle-v1',
      'apiHealth=not-probed',
      'lastErrorCategory=unavailable',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.diagnosticsCopied)));
    }
  }

  Future<void> _copyFeedback(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(
      ClipboardData(
        text:
            'Taxy ${InternalBetaBuildInfo.appVersion}+${InternalBetaBuildInfo.buildNumber}\nWhat happened / O que aconteceu:\nSteps / Passos:\nExpected / Esperado:',
      ),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.feedbackCopied)));
    }
  }
}

final class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    super.key,
    required this.value,
    required this.label,
    this.subtitle,
  });

  final LanguagePreference value;
  final String label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => RadioListTile<LanguagePreference>(
    value: value,
    title: Text(label),
    subtitle: subtitle == null ? null : Text(subtitle!),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
  );
}
