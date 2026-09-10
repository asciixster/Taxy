import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/simulation_repository.dart';
import '../domain/models.dart';
import '../tax_engine/tax_rules.dart';
import '../product/product_repository.dart';
import '../product/product_models.dart';
import '../fiscal_data/fiscal_data_orchestrator.dart';
import '../fiscal_data/fiscal_evidence_repository.dart';
import '../guided_tax/document_evidence.dart';
import '../modules/dm3irs/infrastructure/dm3irs_history_bridge.dart';
import '../modules/dm3irs/infrastructure/historical_tax_confirmation_repository.dart';
import '../modules/dm3irs/domain/historical_tax_evidence.dart';

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

final fiscalEvidenceRepositoryProvider = Provider<FiscalEvidenceRepository>(
  (ref) => LocalFiscalEvidenceRepository(),
);

final efaturaEvidenceForYearProvider =
    FutureProvider.family<EfaturaCompanionEvidence?, int>(
      (ref, year) =>
          ref.watch(fiscalEvidenceRepositoryProvider).loadEfatura(year),
    );

final documentEvidenceRepositoryProvider =
    Provider<GuidedDocumentEvidenceRepository>(
      (ref) => LocalGuidedDocumentEvidenceRepository(),
    );

final documentEvidenceForYearProvider =
    FutureProvider.family<List<GuidedDocumentEvidence>, int>(
      (ref, year) => ref.watch(documentEvidenceRepositoryProvider).load(year),
    );

final dm3IrsHistoryGatewayProvider = Provider<Dm3IrsHistoryGateway>(
  (_) => AndroidDm3IrsHistoryGateway(),
);

final historicalTaxConfirmationRepositoryProvider =
    Provider<HistoricalTaxConfirmationRepository>(
      (_) => LocalHistoricalTaxConfirmationRepository(),
    );

final historicalTaxConfirmationsForYearProvider =
    FutureProvider.family<List<HistoricalTaxConfirmation>, int>(
      (ref, year) =>
          ref.watch(historicalTaxConfirmationRepositoryProvider).load(year),
    );
