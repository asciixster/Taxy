import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/simulation_repository.dart';
import '../domain/models.dart';
import '../tax_engine/tax_rules.dart';

final repositoryProvider = Provider<SimulationRepository>(
  (ref) => LocalSimulationRepository(),
);

final rulesProvider = FutureProvider<TaxRuleSet>((ref) async {
  final source = await rootBundle.loadString('assets/tax_rules/2026.json');
  return TaxRuleSet.fromJsonString(source);
});

final simulationsProvider = FutureProvider<List<TaxSimulation>>(
  (ref) => ref.watch(repositoryProvider).list(),
);
