enum TaxyModuleAvailability { active, experimental, comingSoon }

final class TaxyModule {
  const TaxyModule({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.availability,
    required this.version,
  });

  final String id;
  final String title;
  final String description;
  final String iconName;
  final TaxyModuleAvailability availability;
  final String version;

  bool get isActive => availability != TaxyModuleAvailability.comingSoon;
}

abstract final class TaxyModuleRegistry {
  static const modules = <TaxyModule>[
    TaxyModule(
      id: 'irs',
      title: 'IRS',
      description: 'Simula, compara e compreende a tua liquidação.',
      iconName: 'receipt_long',
      availability: TaxyModuleAvailability.active,
      version: '0.3.0',
    ),
    TaxyModule(
      id: 'efatura',
      title: 'e-Fatura',
      description: 'Consulta o resumo, setores e faturas sem alterar dados.',
      iconName: 'receipt_long',
      availability: TaxyModuleAvailability.experimental,
      version: '0.7.6',
    ),
    TaxyModule(
      id: 'salary',
      title: 'Salário líquido',
      description: 'Converte salário bruto em líquido.',
      iconName: 'payments',
      availability: TaxyModuleAvailability.comingSoon,
      version: 'planned',
    ),
    TaxyModule(
      id: 'self_employed',
      title: 'Recibos verdes',
      description: 'Trabalho independente e obrigações.',
      iconName: 'work_outline',
      availability: TaxyModuleAvailability.comingSoon,
      version: 'planned',
    ),
    TaxyModule(
      id: 'capital_gains',
      title: 'Mais-valias',
      description: 'Imóveis e investimentos.',
      iconName: 'trending_up',
      availability: TaxyModuleAvailability.comingSoon,
      version: 'planned',
    ),
    TaxyModule(
      id: 'imt',
      title: 'IMT',
      description: 'Aquisição de imóveis.',
      iconName: 'home_work',
      availability: TaxyModuleAvailability.comingSoon,
      version: 'planned',
    ),
    TaxyModule(
      id: 'iuc',
      title: 'IUC',
      description: 'Imposto anual do veículo.',
      iconName: 'directions_car',
      availability: TaxyModuleAvailability.comingSoon,
      version: 'planned',
    ),
  ];

  static TaxyModule byId(String id) =>
      modules.singleWhere((module) => module.id == id);
}
