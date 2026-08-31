import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/language_controller.dart';

final class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.languageController});

  final LanguageController languageController;

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
        ],
      ),
    );
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
