import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../modules/taxy_module.dart';

final class ModuleSection extends StatelessWidget {
  const ModuleSection({
    super.key,
    required this.onOpenIrs,
    required this.onOpenProfile,
    required this.onOpenIncome,
    required this.onOpenExpenses,
    this.onOpenEfatura,
    this.showExperimentalEfatura = false,
  });

  final VoidCallback onOpenIrs;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenIncome;
  final VoidCallback onOpenExpenses;
  final VoidCallback? onOpenEfatura;
  final bool showExperimentalEfatura;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compactBadges =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.5;
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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.irsModuleDescription),
                if (compactBadges) Text(l10n.available),
              ],
            ),
            trailing: compactBadges ? null : Chip(label: Text(l10n.available)),
            onTap: onOpenIrs,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              ListTile(
                key: const Key('fiscal-profile-entry'),
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(l10n.fiscalProfile),
                subtitle: Text(l10n.profileModuleDescription),
                trailing: const Icon(Icons.chevron_right),
                onTap: onOpenProfile,
              ),
              const Divider(height: 1),
              ListTile(
                key: const Key('income-entry'),
                leading: const CircleAvatar(
                  child: Icon(Icons.payments_outlined),
                ),
                title: Text(l10n.income),
                subtitle: Text(l10n.incomeModuleDescription),
                trailing: const Icon(Icons.chevron_right),
                onTap: onOpenIncome,
              ),
              const Divider(height: 1),
              ListTile(
                key: const Key('expenses-entry'),
                leading: const CircleAvatar(
                  child: Icon(Icons.shopping_bag_outlined),
                ),
                title: Text(l10n.expenses),
                subtitle: Text(l10n.expensesModuleDescription),
                trailing: const Icon(Icons.chevron_right),
                onTap: onOpenExpenses,
              ),
            ],
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
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.efaturaModuleDescription),
                  if (compactBadges) Text(l10n.experimental),
                ],
              ),
              trailing: compactBadges
                  ? null
                  : Chip(label: Text(l10n.experimental)),
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
