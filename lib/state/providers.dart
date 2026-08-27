import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/simulation_repository.dart';
import '../domain/models.dart';
import '../tax_engine/tax_rules.dart';

final repositoryProvider = Provider<SimulationRepository>(
  (ref) => LocalSimulationRepository(),
);

final taxRuleRepositoryProvider = Provider<TaxRuleRepository>(
  (ref) => TaxRuleRepository(rootBundle.loadString),
);

final rulesForProvider =
    FutureProvider.family<TaxRuleSet, ({int year, TaxRegion region})>(
      (ref, selection) => ref
          .watch(taxRuleRepositoryProvider)
          .load(selection.year, selection.region.name),
    );

/// Compatibilidade do shell atual enquanto a seleção inicial é migrada.
final rulesProvider = FutureProvider<TaxRuleSet>(
  (ref) =>
      ref.watch(taxRuleRepositoryProvider).load(2026, TaxRegion.continent.name),
);

final simulationsProvider = FutureProvider<List<TaxSimulation>>(
  (ref) => ref.watch(repositoryProvider).list(),
);
