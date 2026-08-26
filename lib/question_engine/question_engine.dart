import '../domain/models.dart';
import '../domain/money.dart';

enum QuestionSection { profile, income, deductions, review }

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
    invoiceVat = _raw(source.deductions.eligibleInvoiceVat);
    ppr = _raw(source.deductions.ppr);
    other = _raw(source.deductions.otherEligibleTaxCredit);
  }

  static String _raw(Money money) =>
      '${money.cents ~/ 100},${(money.cents.abs() % 100).toString().padLeft(2, '0')}';

  String? id;
  String name = 'Simulação principal';
  int taxYear = 2026;
  int age = 30;
  CivilStatus civilStatus = CivilStatus.single;
  List<int> dependentAges = [];
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
  String invoiceVat = '';
  String ppr = '';
  String other = '';
}

final class QuestionEngine {
  const QuestionEngine();

  List<QuestionStep> steps(TaxDraft draft) => [
    const QuestionStep('taxYear', QuestionSection.profile, 'Que ano queres simular?',
      'As regras fiscais mudam todos os anos.'),
    const QuestionStep('age', QuestionSection.profile, 'Qual é a tua idade?',
      'A idade pode alterar benefícios como a dedução do PPR.'),
    const QuestionStep('civilStatus', QuestionSection.profile, 'Qual é o teu estado civil?',
      'Usamos esta informação para preparar o agregado familiar.'),
    if (draft.civilStatus != CivilStatus.single)
      const QuestionStep('filingMode', QuestionSection.profile, 'Como queres simular a tributação?',
        'A tributação conjunta ficará disponível após validação específica.'),
    const QuestionStep('residency', QuestionSection.profile, 'Viveste fiscalmente em Portugal todo o ano?',
      'A residência parcial segue regras diferentes.'),
    const QuestionStep('region', QuestionSection.profile, 'Onde tens residência fiscal?',
      'Continente, Madeira e Açores podem ter tabelas diferentes.'),
    const QuestionStep('dependents', QuestionSection.profile, 'Tens filhos ou outros dependentes?',
      'Indica quantos fazem parte do teu agregado.'),
    if (draft.dependentAges.isNotEmpty)
      const QuestionStep('dependentAges', QuestionSection.profile, 'Que idade têm os dependentes?',
        'A idade em 31 de dezembro pode aumentar a dedução.'),
    const QuestionStep('incomeMode', QuestionSection.income, 'Como preferes indicar o rendimento?',
      'Podes usar o total anual ou um valor mensal.'),
    QuestionStep('gross', QuestionSection.income,
      draft.incomeEntryMode == IncomeEntryMode.annual
          ? 'Qual foi o teu rendimento bruto anual?'
          : 'Qual foi o rendimento bruto mensal?',
      'Usa valores antes de IRS e Segurança Social.'),
    const QuestionStep('withholding', QuestionSection.income, 'Quanto foi retido em IRS?',
      'É o total anual que aparece nos recibos ou declaração da entidade patronal.'),
    const QuestionStep('socialSecurity', QuestionSection.income, 'Quanto descontaste para a Segurança Social?',
      'Indica apenas contribuições obrigatórias do trabalhador.'),
    const QuestionStep('general', QuestionSection.deductions, 'Despesas gerais familiares',
      'Compras e serviços elegíveis no e-Fatura, sem contar saúde, educação ou rendas.'),
    const QuestionStep('health', QuestionSection.deductions, 'Quanto tiveste em despesas de saúde?',
      'Indica despesas elegíveis e não reembolsadas.'),
    const QuestionStep('education', QuestionSection.deductions, 'E em educação e formação?',
      'Inclui apenas despesas que cumprem os requisitos fiscais.'),
    const QuestionStep('rent', QuestionSection.deductions, 'Pagaste renda de habitação permanente?',
      'Indica o total anual de rendas comunicadas à AT.'),
    const QuestionStep('careHomes', QuestionSection.deductions, 'Tiveste encargos com lares?',
      'Pode incluir apoio domiciliário e instituições elegíveis.'),
    const QuestionStep('invoiceVat', QuestionSection.deductions, 'IVA de faturas elegíveis',
      'Indica o IVA, não o total da despesa, dos setores abrangidos.'),
    const QuestionStep('ppr', QuestionSection.deductions, 'Quanto aplicaste num PPR?',
      'O benefício depende da idade e das condições legais de manutenção.'),
    const QuestionStep('other', QuestionSection.deductions, 'Outras deduções já apuradas',
      'Opcional: introduz apenas o crédito fiscal elegível, não a despesa.'),
    const QuestionStep('review', QuestionSection.review, 'Está tudo pronto para calcular',
      'Revê os principais valores antes de guardar a simulação.'),
  ];
}
