enum AppFeature {
  basicSimulation,
  unlimitedSimulations,
  scenarioComparison,
  advancedModules,
}

enum SubscriptionTier { free, premium }

/// Preparação para monetização. O MVP não liga a pagamentos nem bloqueia o
/// comparador; a política pode ser alterada sem tocar no motor fiscal.
final class Entitlements {
  const Entitlements(this.tier);

  final SubscriptionTier tier;

  bool allows(AppFeature feature) => switch ((tier, feature)) {
    (_, AppFeature.basicSimulation) => true,
    (_, AppFeature.scenarioComparison) => true,
    (SubscriptionTier.premium, _) => true,
    _ => false,
  };
}
