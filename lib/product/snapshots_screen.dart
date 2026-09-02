import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../l10n/taxy_formatters.dart';
import '../state/providers.dart';
import 'app_error_state.dart';
import 'app_failure.dart';
import 'product_models.dart';
import 'irs_scenario_models.dart';

final class SnapshotsScreen extends ConsumerWidget {
  const SnapshotsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(productStateProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.savedEstimates)),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => AppErrorState(
          failure: const AppFailure(AppFailureKind.localDataError),
          onRetry: () => ref.invalidate(productStateProvider),
        ),
        data: (product) {
          final snapshots = [...product.snapshots]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (snapshots.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bookmarks_outlined, size: 44),
                    const SizedBox(height: 12),
                    Text(l10n.noSavedEstimates),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            itemCount: snapshots.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final snapshot = snapshots[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    child: Icon(Icons.bookmark_outline),
                  ),
                  title: Text(snapshot.label),
                  subtitle: Text(
                    '${l10n.savedEstimate} · ${snapshot.taxYear}\n'
                    '${TaxyFormatters.date(context, snapshot.createdAt.toIso8601String())} · '
                    '${TaxyFormatters.euros(context, snapshot.balanceCents)}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) => value == 'delete'
                        ? _delete(ref, product, snapshot.id)
                        : _duplicate(ref, snapshot),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'duplicate',
                        child: Text(l10n.duplicateAsScenario),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(l10n.deleteSavedEstimate),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _delete(WidgetRef ref, ProductState product, String id) async {
    await ref
        .read(productRepositoryProvider)
        .save(
          product.copyWith(
            snapshots: product.snapshots
                .where((snapshot) => snapshot.id != id)
                .toList(growable: false),
          ),
        );
    ref.invalidate(productStateProvider);
  }

  Future<void> _duplicate(WidgetRef ref, IrsSnapshot snapshot) async {
    final now = DateTime.now();
    await ref
        .read(repositoryProvider)
        .save(
          snapshot.simulation.copyWith(
            id: now.microsecondsSinceEpoch.toString(),
            name: '${snapshot.label} — scenario',
            updatedAt: now,
          ),
        );
    ref.invalidate(simulationsProvider);
  }
}
