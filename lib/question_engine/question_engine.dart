import '../domain/models.dart';
import '../domain/money.dart';

enum QuestionSection { eligibility, profile, income, deductions, review }

final class QuestionStep {
  const QuestionStep(this.id, this.section, this.title, this.helper);
  final String id;
  final QuestionSection section;
  final String title;
  final String helper;
}

final class TaxDraft {
  TaxDraft({TaxSimulation? source}) {
    if (source == null) return;
    id = source.id;
    name = source.name;
    taxYear = source.profile.taxYear;
    age = source.profile.age;
    civilStatus = source.profile.civilStatus;
    dependentAges = [...source.profile.dependentAges];
    isSingleParentHousehold = source.profile.isSingleParentHousehold;
    fullYearResident = source.profile.fullYearResident;
    region = source.profile.region;
    filingMode = source.profile.filingMode;
    incomeEntryMode = source.income.entryMode;
    gross = _raw(source.income.gross);
    monthly = _raw(source.income.monthlyAmount);
    months = source.income.months;
    withholding = _raw(source.income.withholding);
    socialSecurity = _raw(source.income.socialSecurity);
    general = _raw(source.deductions.general);
    health = _raw(source.deductions.health);
    education = _raw(source.deductions.education);
    rent = _raw(source.deductions.rent);
    careHomes = _raw(source.deductions.careHomes);
    invoiceVat15 = _raw(source.deductions.invoiceVat15);
    invoiceVat30 = _raw(source.deductions.invoiceVat30);
    invoiceVat35 = _raw(source.deductions.invoiceVat35);
    invoiceVat100 = _raw(source.deductions.invoiceVat100);
    ppr = _raw(source.deductions.ppr);
    incomeTypes = {...source.incomeTypes};
    wantsIrsJovemA = source.primaryIrsJovem.requested;
    irsJovemRegularizedA =
        source.primaryIrsJovem.taxSituationRegularized ?? true;
    irsJovemHistoryA = _historyRaw(source.primaryIrsJovem.incomeHistory);
    irsJovemHistoryCompleteA = source.primaryIrsJovem.historyConfirmedComplete;
    if (source.secondaryTaxpayer case final secondary?) {
      secondaryAge = secondary.age;
      secondaryGross = _raw(secondary.income.gross);
      secondaryWithholding = _raw(secondary.income.withholding);
      secondarySocialSecurity = _raw(secondary.income.socialSecurity);
      secondaryGeneral = _raw(secondary.deductions.general);
      secondaryHealth = _raw(secondary.deductions.health);
      secondaryEducation = _raw(secondary.deductions.education);
      secondaryRent = _raw(secondary.deductions.rent);
      secondaryCareHomes = _raw(secondary.deductions.careHomes);
      secondaryPpr = _raw(secondary.deductions.ppr);
      secondaryVat15 = _raw(secondary.deductions.invoiceVat15);
      secondaryVat30 = _raw(secondary.deductions.invoiceVat30);
      secondaryVat35 = _raw(secondary.deductions.invoiceVat35);
      secondaryVat100 = _raw(secondary.deductions.invoiceVat100);
      wantsIrsJovemB = secondary.irsJovem.requested;
      irsJovemRegularizedB = secondary.irsJovem.taxSituationRegularized ?? true;
      irsJovemHistoryB = _historyRaw(secondary.irsJovem.incomeHistory);
      irsJovemHistoryCompleteB = secondary.irsJovem.historyConfirmedComplete;
    }
  }

  static String _raw(Money money) =>
      '${money.cents ~/ 100},${(money.cents.abs() % 100).toString().padLeft(2, '0')}';

  static String _historyRaw(List<IrsJovemIncomeYear> history) => history
      .map(
        (entry) =>
            '${entry.year},${entry.hadCategoryAIncome ? 'A' : ''}${entry.hadCategoryBIncome ? 'B' : ''},${entry.wasDependent},${entry.residentInPortugal},${entry.usedIncompatibleRegime}',
      )
      .join('\n');

  String? id;
  String name = 'Simulação principal';
  int taxYear = 2026;
  int age = 30;
  CivilStatus civilStatus = CivilStatus.single;
  List<int> dependentAges = [];
  bool isSingleParentHousehold = false;
  bool fullYearResident = true;
  TaxRegion region = TaxRegion.continent;
  FilingMode filingMode = FilingMode.separate;
  IncomeEntryMode incomeEntryMode = IncomeEntryMode.annual;
  String gross = '';
  String monthly = '';
  int months = 14;
  String withholding = '';
  String socialSecurity = '';
  String general = '';
  String health = '';
  String education = '';
  String rent = '';
  String careHomes = '';
  String invoiceVat15 = '';
  String invoiceVat30 = '';
  String invoiceVat35 = '';
  String invoiceVat100 = '';
  String ppr = '';
  Set<IncomeType> incomeTypes = {IncomeType.employment};
  bool hasSpecialSituation = false;
  bool wantsIrsJovemA = false;
  bool wantsIrsJovemB = false;
  String irsJovemHistoryA = '';
  String irsJovemHistoryB = '';
  bool irsJovemHistoryCompleteA = false;
  bool irsJovemHistoryCompleteB = false;
  bool irsJovemRegularizedA = true;
  bool irsJovemRegularizedB = true;
  int secondaryAge = 30;
  String secondaryGross = '';
  String secondaryWithholding = '';
  String secondarySocialSecurity = '';
  String secondaryGeneral = '';
  String secondaryHealth = '';
  String secondaryEducation = '';
  String secondaryRent = '';
  String secondaryCareHomes = '';
  String secondaryPpr = '';
  String secondaryVat15 = '';
  String secondaryVat30 = '';
  String secondaryVat35 = '';
  String secondaryVat100 = '';
}

final class QuestionEngine {
  const QuestionEngine();

  List<QuestionStep> steps(TaxDraft draft) => [
    const QuestionStep(
      'taxYear',
      QuestionSection.eligibility,
      'Que ano queres simular?',
      'As regras fiscais mudam todos os anos.',
    ),
    const QuestionStep(
      'residency',
      QuestionSection.eligibility,
      'Viveste fiscalmente em Portugal todo o ano?',
      'A residência parcial segue regras diferentes.',
    ),
    const QuestionStep(
      'region',
      QuestionSection.eligibility,
      'Onde tens residência fiscal?',
      'Continente, Madeira e Açores podem ter tabelas diferentes.',
    ),
    const QuestionStep(
      'civilStatus',
      QuestionSection.eligibility,
      'Qual é o teu estado civil?',
      'Casados e unidos de facto podem comparar conjunta e separada.',
    ),
    const QuestionStep(
      'incomeTypes',
      QuestionSection.eligibility,
      'Que tipos de rendimento tiveste?',
      'Se existir um tipo ainda não suportado, avisamos já e não ignoramos rendimentos.',
    ),
    const QuestionStep(
      'specialSituations',
      QuestionSection.eligibility,
      'Existe alguma situação fiscal especial?',
      'Guarda partilhada, deficiência, residência parcial e outros regimes exigem tratamento próprio.',
    ),
    const QuestionStep(
      'irsJovemInterest',
      QuestionSection.eligibility,
      'Queres verificar o IRS Jovem?',
      'Se não fores elegível, continuamos a calcular o IRS normal.',
    ),
    if (draft.wantsIrsJovemA || draft.wantsIrsJovemB)
      const QuestionStep(
        'irsJovemHistory',
        QuestionSection.eligibility,
        'Confirma o histórico anual de trabalho',
        'Cada ano é descrito objetivamente; anos como dependente ou sem rendimentos A/B não consomem o benefício.',
      ),
    const QuestionStep(
      'age',
      QuestionSection.profile,
      'Qual é a tua idade?',
      'A idade pode alterar benefícios como a dedução do PPR.',
    ),
    if (draft.civilStatus != CivilStatus.single) ...[
      const QuestionStep(
        'secondaryAge',
        QuestionSection.profile,
        'Qual é a idade do segundo titular?',
        'Os dois titulares são calculados individualmente e em conjunto.',
      ),
      const QuestionStep(
        'filingMode',
        QuestionSection.profile,
        'Que opção queres ver primeiro?',
        'A Taxy calculará sempre conjunta e separada para comparar.',
      ),
    ],
    const QuestionStep(
      'dependents',
      QuestionSection.profile,
      'Tens filhos ou outros dependentes?',
      'Indica quantos fazem parte do teu agregado.',
    ),
    if (draft.dependentAges.isNotEmpty)
      const QuestionStep(
        'dependentAges',
        QuestionSection.profile,
        'Que idade têm os dependentes?',
        'A idade em 31 de dezembro pode aumentar a dedução.',
      ),
    if (draft.dependentAges.isNotEmpty &&
        draft.civilStatus == CivilStatus.single)
      const QuestionStep(
        'singleParent',
        QuestionSection.profile,
        'O teu agregado é uma família monoparental?',
        'Confirma apenas um agregado monoparental standard. Residência alternada ou responsabilidades partilhadas ainda não são suportadas.',
      ),
    const QuestionStep(
      'incomeMode',
      QuestionSection.income,
      'Como preferes indicar o rendimento?',
      'Podes usar o total anual ou um valor mensal.',
    ),
    QuestionStep(
      'gross',
      QuestionSection.income,
      draft.incomeEntryMode == IncomeEntryMode.annual
          ? 'Qual foi o teu rendimento bruto anual?'
          : 'Qual foi o rendimento bruto mensal?',
      'Usa valores antes de IRS e Segurança Social.',
    ),
    const QuestionStep(
      'withholding',
      QuestionSection.income,
      'Quanto foi retido em IRS?',
      'É o total anual que aparece nos recibos ou declaração da entidade patronal.',
    ),
    const QuestionStep(
      'socialSecurity',
      QuestionSection.income,
      'Quanto descontaste para a Segurança Social?',
      'Indica apenas contribuições obrigatórias do trabalhador.',
    ),
    if (draft.civilStatus != CivilStatus.single) ...[
      const QuestionStep(
        'secondaryGross',
        QuestionSection.income,
        'Rendimento bruto anual do segundo titular',
        'Introduz apenas Categoria A deste titular.',
      ),
      const QuestionStep(
        'secondaryWithholding',
        QuestionSection.income,
        'Retenção anual do segundo titular',
        'Total de IRS já retido.',
      ),
      const QuestionStep(
        'secondarySocialSecurity',
        QuestionSection.income,
        'Segurança Social do segundo titular',
        'Contribuições obrigatórias anuais.',
      ),
    ],
    const QuestionStep(
      'general',
      QuestionSection.deductions,
      'Despesas gerais familiares',
      'Compras e serviços elegíveis no e-Fatura, sem contar saúde, educação ou rendas.',
    ),
    const QuestionStep(
      'health',
      QuestionSection.deductions,
      'Quanto tiveste em despesas de saúde?',
      'Indica despesas elegíveis e não reembolsadas.',
    ),
    const QuestionStep(
      'education',
      QuestionSection.deductions,
      'E em educação e formação?',
      'Inclui apenas educação standard. Estudante deslocado e majorações territoriais não são suportados.',
    ),
    const QuestionStep(
      'rent',
      QuestionSection.deductions,
      'Pagaste renda de habitação permanente?',
      'Indica o total anual de rendas comunicadas à AT.',
    ),
    const QuestionStep(
      'careHomes',
      QuestionSection.deductions,
      'Tiveste encargos com lares?',
      'Pode incluir apoio domiciliário e instituições elegíveis.',
    ),
    const QuestionStep(
      'invoiceVat15',
      QuestionSection.deductions,
      'IVA com dedução de 15%',
      'Indica o IVA, não o total da despesa, dos setores standard elegíveis.',
    ),
    const QuestionStep(
      'invoiceVat30',
      QuestionSection.deductions,
      'IVA com dedução de 30%',
      'Indica o IVA de ensino desportivo, clubes e ginásios elegíveis.',
    ),
    const QuestionStep(
      'invoiceVat35',
      QuestionSection.deductions,
      'IVA com dedução de 35%',
      'Indica apenas IVA de medicamentos de uso veterinário elegíveis.',
    ),
    const QuestionStep(
      'invoiceVat100',
      QuestionSection.deductions,
      'IVA com dedução de 100%',
      'Indica o IVA de transportes públicos e assinaturas de periódicos elegíveis.',
    ),
    const QuestionStep(
      'ppr',
      QuestionSection.deductions,
      'Quanto aplicaste num PPR?',
      'O benefício depende da idade e das condições legais de manutenção.',
    ),
    if (draft.civilStatus != CivilStatus.single)
      const QuestionStep(
        'secondaryDeductions',
        QuestionSection.deductions,
        'Despesas do segundo titular',
        'Introduz as despesas tituladas pelo segundo titular; não dividimos automaticamente as despesas próprias.',
      ),
    const QuestionStep(
      'review',
      QuestionSection.review,
      'Está tudo pronto para calcular',
      'Revê os principais valores antes de guardar a simulação.',
    ),
  ];
}
