import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/simulation_repository.dart';
import '../domain/models.dart';
import '../tax_engine/tax_rules.dart';
import '../product/product_repository.dart';
import '../product/product_models.dart';

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

final rulesProvider = FutureProvider<TaxRuleSet>((ref) async {
  final product = await ref.watch(productStateProvider.future);
  return ref
      .watch(taxRuleRepositoryProvider)
      .load(
        product.profile.activeTaxYear,
        (product.profile.region ?? TaxRegion.continent).name,
      );
});

final simulationsProvider = FutureProvider<List<TaxSimulation>>(
  (ref) => ref.watch(repositoryProvider).list(),
);

final simulationDraftProvider = FutureProvider<Map<String, Object?>?>(
  (ref) => ref.watch(repositoryProvider).loadDraft(),
);

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => LocalProductRepository(),
);

final productStateProvider = FutureProvider<ProductState>(
  (ref) => ref.watch(productRepositoryProvider).load(),
);
