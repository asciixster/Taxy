import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../modules/taxy_module.dart';

final class ModuleSection extends StatelessWidget {
  const ModuleSection({
    super.key,
    required this.onOpenIrs,
    this.onOpenEfatura,
    this.showExperimentalEfatura = false,
  });

  final VoidCallback onOpenIrs;
  final VoidCallback? onOpenEfatura;
  final bool showExperimentalEfatura;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final active = TaxyModuleRegistry.byId('irs');
    final comingCount = TaxyModuleRegistry.modules
        .where((module) => !module.isActive)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.simulators, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(18),
            leading: const CircleAvatar(
              child: Icon(Icons.receipt_long_rounded),
            ),
            title: Text(
              active.title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(active.description),
            trailing: Chip(label: Text(l10n.available)),
            onTap: onOpenIrs,
          ),
        ),
        if (showExperimentalEfatura) ...[
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              key: const Key('efatura-module-entry'),
              contentPadding: const EdgeInsets.all(18),
              leading: const CircleAvatar(child: Icon(Icons.receipt_outlined)),
              title: const Text(
                'e-Fatura',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(l10n.efaturaModuleDescription),
              trailing: Chip(label: Text(l10n.experimental)),
              onTap: onOpenEfatura,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Semantics(
          label: l10n.futureSimulatorsSemantics(comingCount),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 18),
                const SizedBox(width: 9),
                Expanded(child: Text(l10n.futureSimulators)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
