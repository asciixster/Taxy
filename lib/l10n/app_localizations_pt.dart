// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'taxy.pt';

  @override
  String get settings => 'Definições';

  @override
  String get language => 'Idioma';

  @override
  String get languageDescription => 'Escolhe o idioma da aplicação.';

  @override
  String get languageAutomatic => 'Automático';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSystemHint =>
      'Segue o idioma do telemóvel. Outros idiomas usam português.';

  @override
  String get back => 'Voltar';

  @override
  String get experimental => 'Experimental';

  @override
  String get efaturaTitle => 'e-Fatura';

  @override
  String get efaturaHeroTitle => 'As tuas despesas, só para consulta';

  @override
  String get efaturaCredentialNotice =>
      'As credenciais são utilizadas apenas para consultar o e-Fatura.';

  @override
  String get connectPortalTitle => 'Ligar ao e-Fatura';

  @override
  String get nif => 'NIF';

  @override
  String get password => 'Senha';

  @override
  String get connectEfatura => 'Ligar ao e-Fatura';

  @override
  String get disconnectEfatura => 'Desligar e-Fatura';

  @override
  String get disconnectTitle => 'Desligar e-Fatura?';

  @override
  String get disconnectExplanation =>
      'Isto termina a sessão guardada neste dispositivo.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get disconnect => 'Desligar';

  @override
  String get selectDeviceCertificate => 'Selecionar certificado do dispositivo';

  @override
  String get selectAtPublicKey => 'Selecionar chave pública da AT';

  @override
  String get refresh => 'Atualizar';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get overviewTitle => 'Resumo e-Fatura';

  @override
  String get provisionalTaxBenefit => 'Benefício provisório';

  @override
  String get invoicesToValidate => 'Faturas com informação pendente';

  @override
  String get invoicesToAssociate => 'Faturas por associar receita';

  @override
  String get expensesByCategory => 'Despesas por categoria';

  @override
  String get sectors => 'Setores';

  @override
  String get pendingInvoicesTitle => 'Faturas pendentes';

  @override
  String get sectorInvoicesTitle => 'Faturas do setor';

  @override
  String get viewPendingInvoices => 'Ver faturas por validar';

  @override
  String get noInvoicesToValidate => 'Sem faturas pendentes';

  @override
  String get noInvoicesInCategory => 'Sem faturas neste setor';

  @override
  String get noActivityInCategory => 'Sem atividade neste setor';

  @override
  String get noDataAvailable => 'Sem dados disponíveis';

  @override
  String get unavailable => 'Indisponível';

  @override
  String get partialEfaturaData =>
      'Alguns valores do e-Fatura não estão disponíveis. As faturas carregadas continuam acessíveis.';

  @override
  String get benefitUnavailable => 'Benefício não disponível';

  @override
  String get readOnlyNoValidation =>
      'A Taxy apresenta esta contagem apenas para consulta. A validação continua a ser feita no e-Fatura oficial.';

  @override
  String get irsPredictionDataTitle => 'Dados para previsão de IRS';

  @override
  String get officialProvisionalBenefit =>
      'Benefício provisório indicado pela AT';

  @override
  String get listedExpenses => 'Despesas listadas';

  @override
  String get listedVat => 'IVA das despesas listadas';

  @override
  String get irsPredictionDisclaimer =>
      'Estes dados ajudam a preparar a previsão. Não representam, por si só, o reembolso ou imposto final de IRS.';

  @override
  String get issuerUnavailable => 'Emitente não disponível';

  @override
  String invoiceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count faturas',
      one: '1 fatura',
      zero: 'Sem faturas',
    );
    return '$_temp0';
  }

  @override
  String get authErrorTitle => 'Não foi possível autenticar';

  @override
  String get authErrorMessage =>
      'Não foi possível autenticar no Portal das Finanças.';

  @override
  String get authorizationErrorTitle => 'Acesso não autorizado';

  @override
  String get authorizationErrorMessage =>
      'O Portal das Finanças não autorizou esta consulta.';

  @override
  String get operationUnavailableTitle => 'Consulta indisponível';

  @override
  String get operationUnavailableMessage =>
      'Esta consulta ainda não está disponível.';

  @override
  String get rateLimitedTitle => 'Demasiadas consultas';

  @override
  String get rateLimitedMessage =>
      'Aguarda um pouco antes de tentar novamente.';

  @override
  String get networkErrorTitle => 'Erro de ligação';

  @override
  String get networkErrorMessage => 'Não foi possível estabelecer ligação.';

  @override
  String get serviceErrorTitle => 'Serviço indisponível';

  @override
  String get serviceErrorMessage =>
      'O serviço e-Fatura não está disponível de momento.';

  @override
  String get parsingErrorTitle => 'Resposta inesperada';

  @override
  String get parsingErrorMessage =>
      'Recebemos uma resposta inesperada do e-Fatura.';

  @override
  String get sessionExpiredTitle => 'Sessão expirada';

  @override
  String get sessionExpiredMessage =>
      'Volta a ligar ao e-Fatura para continuar.';

  @override
  String get notConfiguredTitle => 'Ligação ainda não configurada';

  @override
  String get genericErrorTitle => 'Não foi possível atualizar';

  @override
  String get genericErrorMessage => 'Não foi possível ligar ao e-Fatura.';

  @override
  String get connecting => 'A ligar ao e-Fatura…';

  @override
  String get updating => 'A atualizar…';

  @override
  String get connected => 'Ligado';

  @override
  String get welcomeTagline => 'IRS, explicado para pessoas';

  @override
  String get welcomeTitle => 'Percebe o teu IRS.\nDecide com confiança.';

  @override
  String get welcomeBody =>
      'Uma conversa simples transforma os teus dados numa estimativa clara — sem formulários, sem fiscalês.';

  @override
  String get startSimulation => 'Começar simulação';

  @override
  String get resumeSimulation => 'Retomar simulação';

  @override
  String get howWeCalculate => 'Ver como fazemos as contas';

  @override
  String get dataOnDevice => 'Dados no dispositivo';

  @override
  String rulesVerified(int year) {
    return 'Regras $year verificadas';
  }

  @override
  String get simulators => 'Simuladores';

  @override
  String get available => 'Disponível';

  @override
  String get efaturaModuleDescription =>
      'Consulta read-only · funcionalidade interna';

  @override
  String get futureSimulators => 'Outros simuladores · Em breve';

  @override
  String futureSimulatorsSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count simuladores futuros em preparação',
      one: '1 simulador futuro em preparação',
    );
    return '$_temp0';
  }

  @override
  String get privateLabel => 'Privado';

  @override
  String get efaturaSemantics => 'e-Fatura experimental, consulta apenas';

  @override
  String get sectorCarRepairs => 'Reparação de automóveis';

  @override
  String get sectorMotorcycleRepairs => 'Reparação de motociclos';

  @override
  String get sectorHospitality => 'Alojamento e restauração';

  @override
  String get sectorHairdressing => 'Cabeleireiros';

  @override
  String get sectorHealth => 'Saúde';

  @override
  String get sectorEducation => 'Educação';

  @override
  String get sectorHousing => 'Habitação';

  @override
  String get sectorNursingHomes => 'Lares';

  @override
  String get sectorVeterinary => 'Veterinários';

  @override
  String get sectorPublicTransport => 'Transportes públicos';

  @override
  String get sectorGyms => 'Ginásios';

  @override
  String get sectorNewspapers => 'Jornais e revistas';

  @override
  String get sectorDomesticServices => 'Serviços domésticos';

  @override
  String get sectorOther => 'Outras despesas';

  @override
  String get invalidNif => 'Introduz um NIF com 9 algarismos.';

  @override
  String get passwordRequired => 'Introduz a senha.';

  @override
  String get rulesLoadError =>
      'Não foi possível carregar as regras fiscais com segurança. Fecha e volta a abrir a aplicação.';

  @override
  String get savedDataLoadError =>
      'Não foi possível abrir os dados guardados neste dispositivo.';

  @override
  String get simulationsLoadError =>
      'Não foi possível abrir as simulações guardadas neste dispositivo.';

  @override
  String get simulationRulesLoadError =>
      'Não foi possível carregar as regras desta simulação com segurança.';

  @override
  String get internalBetaBuild => 'Informação da beta interna';

  @override
  String get appVersion => 'Versão';

  @override
  String get gitRevision => 'Revisão';

  @override
  String get environment => 'Ambiente';

  @override
  String get apiHost => 'Servidor API';

  @override
  String get fiscalProfile => 'Perfil fiscal';

  @override
  String get profileComplete => 'Perfil completo';

  @override
  String get profileIncomplete => 'Perfil incompleto';

  @override
  String get profilePurpose =>
      'Estes dados mantêm o ano fiscal e as simulações coerentes. Valores desconhecidos continuam indisponíveis.';

  @override
  String get activeTaxYear => 'Ano fiscal ativo';

  @override
  String get taxResidence => 'Residência fiscal';

  @override
  String get unknownValue => 'Não indicado';

  @override
  String get mainlandPortugal => 'Portugal continental';

  @override
  String get madeira => 'Madeira';

  @override
  String get azores => 'Açores';

  @override
  String get civilStatusLabel => 'Estado civil';

  @override
  String get single => 'Solteiro/a';

  @override
  String get married => 'Casado/a';

  @override
  String get deFactoUnion => 'União de facto';

  @override
  String get dependants => 'Dependentes';

  @override
  String get employmentIncome => 'Rendimentos de trabalho dependente';

  @override
  String get selfEmploymentIncome => 'Rendimentos de trabalho independente';

  @override
  String get yes => 'Sim';

  @override
  String get no => 'Não';

  @override
  String get save => 'Guardar';

  @override
  String get localDataUnavailable =>
      'Não foi possível abrir os dados guardados neste dispositivo.';

  @override
  String get income => 'Rendimentos';

  @override
  String get expenses => 'Despesas';

  @override
  String get addIncome => 'Adicionar rendimento';

  @override
  String get addExpense => 'Adicionar despesa';

  @override
  String totalForYear(int year) {
    return 'Total de $year';
  }

  @override
  String get localIncomeNotice =>
      'Registos apenas locais. Não são importados nem apresentados como dados oficiais.';

  @override
  String get localExpenseNotice =>
      'Os registos locais são informação de apoio e não são tratados automaticamente como deduções de IRS.';

  @override
  String get noIncomeRegistered => 'Sem rendimentos registados neste ano';

  @override
  String get noExpensesRegistered => 'Sem despesas registadas neste ano';

  @override
  String get amountEuros => 'Valor em euros';

  @override
  String get remove => 'Remover';

  @override
  String get sourceManual => 'Introduzido manualmente';

  @override
  String get sourceImported => 'Importado';

  @override
  String get sourceExternal => 'Fonte externa';

  @override
  String get sourceCalculated => 'Calculado';

  @override
  String get statusConfirmed => 'Confirmado';

  @override
  String get statusEstimated => 'Estimado';

  @override
  String get statusPossibleDuplicate => 'Possível duplicado';

  @override
  String get privacyAndSecurity => 'Privacidade e segurança';

  @override
  String get privacyIntro =>
      'A Taxy guarda as simulações e os registos locais neste dispositivo. As credenciais e-Fatura são enviadas por HTTPS apenas para api.taxy.pt durante a ligação e não regressam à interface.';

  @override
  String get privacyEfatura =>
      'O acesso ao e-Fatura é apenas de leitura. Desligar remove deste dispositivo a capacidade de sessão guardada.';

  @override
  String get diagnostics => 'Diagnóstico';

  @override
  String get copyDiagnostics => 'Copiar informações de diagnóstico';

  @override
  String get diagnosticsCopied => 'Informações de diagnóstico copiadas';

  @override
  String get diagnosticsNotice =>
      'O diagnóstico contém apenas versão e ambiente — nunca NIF, credenciais, tokens ou dados de faturas.';

  @override
  String get sendFeedback => 'Enviar feedback';

  @override
  String get feedbackCopied => 'Foi copiado um modelo seguro de feedback.';

  @override
  String get appearance => 'Aparência';

  @override
  String get themeSystem => 'Usar definição do dispositivo';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get profileModuleDescription => 'Ano ativo e dados fiscais';

  @override
  String get incomeModuleDescription => 'Rendimentos locais com origem';

  @override
  String get expensesModuleDescription => 'Despesas locais de apoio';

  @override
  String get estimateBasis => 'O que esta estimativa considera';

  @override
  String get incomeConsidered => 'Rendimentos considerados';

  @override
  String get deductionsConsidered => 'Deduções consideradas';

  @override
  String get withholdingConsidered => 'Retenções consideradas';

  @override
  String get userEnteredSource => 'Introduzido por ti';

  @override
  String get estimateNotOfficial =>
      'Estimativa baseada na informação introduzida e nas regras suportadas pela Taxy. Não é uma liquidação oficial da AT.';

  @override
  String get missingInformationImprove =>
      'Falta informação para melhorar esta estimativa.';

  @override
  String get category => 'Categoria';

  @override
  String get categoryEmployment => 'Trabalho dependente';

  @override
  String get categorySelfEmployment => 'Trabalho independente';

  @override
  String get categoryPension => 'Pensão';

  @override
  String get categoryOther => 'Outra';

  @override
  String get categoryGeneral => 'Geral';

  @override
  String get categoryHealth => 'Saúde';

  @override
  String get categoryEducation => 'Educação';

  @override
  String get categoryHousing => 'Habitação';

  @override
  String get categoryProfessional => 'Atividade profissional';

  @override
  String get edit => 'Editar';

  @override
  String get profileChecklist => 'Checklist fiscal';

  @override
  String completedEssential(int completed, int total) {
    return '$completed de $total elementos essenciais preenchidos';
  }

  @override
  String get checkActiveYear => 'Ano fiscal ativo';

  @override
  String get checkResidence => 'Residência fiscal';

  @override
  String get checkCivilStatus => 'Estado civil';

  @override
  String get checkHousehold => 'Agregado';

  @override
  String get checkWorkContext => 'Situação profissional';

  @override
  String get checkIncome => 'Rendimentos do ano ativo';

  @override
  String get impactResidence =>
      'A residência determina as regras regionais suportadas aplicáveis.';

  @override
  String get impactCivilStatus =>
      'O estado civil é necessário para escolher um modo de cálculo aplicável.';

  @override
  String get impactHousehold =>
      'O agregado pode afetar deduções e benefícios suportados.';

  @override
  String get impactWorkContext =>
      'A situação profissional permite saber se o modelo atual suporta os rendimentos.';

  @override
  String get impactIncome =>
      'Os rendimentos e retenções são necessários para estimar o saldo final de IRS.';

  @override
  String get scenarioComparison => 'Comparar cenários';

  @override
  String get scenarioIntro =>
      'Testa alterações hipotéticas sem mudar a informação base.';

  @override
  String get currentScenario => 'Cenário atual';

  @override
  String get alternativeScenario => 'Cenário alternativo';

  @override
  String get resultDifference => 'Diferença no resultado';

  @override
  String get whatChanged => 'O que mudou';

  @override
  String get noScenarioChanges => 'Ainda não existem alterações hipotéticas.';

  @override
  String get scenarioOverrideNotice =>
      'Os valores alternativos são hipóteses do cenário, não dados confirmados do perfil.';

  @override
  String get savedEstimates => 'Estimativas guardadas';

  @override
  String get saveEstimate => 'Guardar estimativa';

  @override
  String get estimateSaved => 'Estimativa guardada neste dispositivo.';

  @override
  String get savedEstimate => 'Estimativa guardada';

  @override
  String get noSavedEstimates => 'Sem estimativas guardadas';

  @override
  String get deleteSavedEstimate => 'Apagar estimativa guardada';

  @override
  String get duplicateAsScenario => 'Duplicar como cenário';

  @override
  String get invoiceExplorer => 'Explorador de faturas';

  @override
  String get searchInvoices => 'Pesquisar emitente';

  @override
  String get documentTotal => 'Total dos documentos';

  @override
  String get monthlySummary => 'Resumo mensal';

  @override
  String get averageDocument => 'Média por documento';

  @override
  String get sortNewest => 'Mais recentes';

  @override
  String get sortOldest => 'Mais antigas';

  @override
  String get sortHighest => 'Maior valor';

  @override
  String get sortLowest => 'Menor valor';

  @override
  String get sortIssuer => 'Nome do emitente';

  @override
  String filteredInvoiceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count faturas correspondentes',
      one: '1 fatura correspondente',
      zero: 'Sem faturas correspondentes',
    );
    return '$_temp0';
  }

  @override
  String lastUpdatedThisSession(String time) {
    return 'Última atualização nesta sessão: $time';
  }

  @override
  String get offlineUnavailable =>
      'Esta área precisa de ligação. Verifica a rede e tenta novamente.';

  @override
  String get tryAgain => 'Tentar novamente';

  @override
  String get dateFilter => 'Intervalo de datas';

  @override
  String get minimumAmount => 'Valor mínimo';

  @override
  String get maximumAmount => 'Valor máximo';

  @override
  String get privacySnapshots =>
      'As estimativas IRS guardadas ficam apenas neste dispositivo. Contêm inputs e resultados normalizados, nunca credenciais ou respostas e-Fatura em bruto.';

  @override
  String get all => 'Todos';

  @override
  String get dashboardTitle => 'O teu IRS, num relance';

  @override
  String simulationUpdatedForYear(int year) {
    return 'Simulação atualizada com as regras de $year.';
  }

  @override
  String get resumeDraft => 'Retomar simulação em curso';

  @override
  String get viewCalculation => 'Ver cálculo';

  @override
  String get change => 'Alterar';

  @override
  String get compare => 'Comparar';

  @override
  String get exploreTaxOpportunities => 'Explorar oportunidades fiscais';

  @override
  String get readOnlyExperimental => 'Consulta experimental apenas de leitura';

  @override
  String get yourSimulations => 'As tuas simulações';

  @override
  String savedSimulationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count guardadas neste dispositivo',
      one: '1 guardada neste dispositivo',
      zero: 'Nenhuma guardada neste dispositivo',
    );
    return '$_temp0';
  }

  @override
  String get newSimulation => 'Nova';

  @override
  String refundAmount(String amount) {
    return 'Reembolso $amount';
  }

  @override
  String taxDueAmount(String amount) {
    return 'A pagar $amount';
  }

  @override
  String get calculationUnavailable => 'Cálculo indisponível';

  @override
  String get options => 'Opções';

  @override
  String get rename => 'Renomear';

  @override
  String get duplicate => 'Duplicar';

  @override
  String get changeData => 'Alterar dados';

  @override
  String get delete => 'Apagar';

  @override
  String get renameSimulation => 'Renomear simulação';

  @override
  String get name => 'Nome';

  @override
  String copySimulationName(String name) {
    return '$name — cópia';
  }

  @override
  String get deleteSimulationTitle => 'Apagar esta simulação?';

  @override
  String deleteSimulationMessage(String name) {
    return '“$name” será removida apenas deste dispositivo.';
  }

  @override
  String get estimatedRefund => 'Reembolso estimado';

  @override
  String get estimatedAdditionalTax => 'Imposto adicional estimado';

  @override
  String get estimateUnavailable => 'Estimativa indisponível';

  @override
  String get openDetails => 'Abrir detalhe';

  @override
  String get transparencyFirst => 'Transparência primeiro';

  @override
  String get calculationMethodIntro =>
      'O cálculo é determinístico e não usa inteligência artificial. Valores monetários são tratados em cêntimos inteiros, com arredondamento explícito.';

  @override
  String get netCategoryIncome => 'Rendimento líquido da categoria';

  @override
  String get netCategoryIncomeExplanation =>
      'Ao rendimento bruto subtraímos a dedução específica aplicável ao trabalho dependente.';

  @override
  String get minimumExistence => 'Mínimo de existência';

  @override
  String get minimumExistenceExplanation =>
      'Quando aplicável, calculamos o abatimento previsto no artigo 70.º do Código do IRS.';

  @override
  String get progressiveBrackets => 'Escalões progressivos';

  @override
  String progressiveBracketsExplanation(int year) {
    return 'Aplicamos as taxas gerais de $year ao rendimento coletável.';
  }

  @override
  String get deductionsAndWithholding => 'Deduções e retenções';

  @override
  String get deductionsAndWithholdingExplanation =>
      'Aplicamos limites por categoria e o limite conjunto. Por fim, descontamos o IRS já retido.';

  @override
  String get validatedScope => 'Âmbito validado';

  @override
  String get unsupportedScope => 'Não suportado / por verificar';

  @override
  String get openValidationLab => 'Abrir laboratório de validação fiscal';

  @override
  String validatedResidentScope(String jurisdiction) {
    return 'Residente durante todo o ano · $jurisdiction.';
  }

  @override
  String get categoryAOnlyScope => 'Rendimentos exclusivamente da Categoria A.';

  @override
  String get standardHouseholdScope =>
      'Individual, família monoparental, casamento ou união de facto standard.';

  @override
  String get couplesComparisonScope =>
      'Nos casais, calculamos separada e conjunta e mostramos a diferença.';

  @override
  String get standardDependantsScope =>
      'Dependentes standard, sem guarda partilhada, residência alternada ou alocação especial.';

  @override
  String get standardEducationScope =>
      'Educação standard, sem estudante deslocado ou majorações territoriais.';

  @override
  String verifiedRulesScope(String version, String date) {
    return 'Regras $version, verificadas em $date.';
  }

  @override
  String get regional2025Unsupported => 'Madeira e Açores em 2025.';

  @override
  String get partialResidenceUnsupported =>
      'Residência parcial ou não residência.';

  @override
  String get incomeTypesUnsupported =>
      'Liquidação IRS Jovem, Categoria B e pensões.';

  @override
  String get foreignIncomeUnsupported =>
      'Rendimentos estrangeiros, de capitais, prediais e mais-valias.';

  @override
  String get specialSituationsUnsupported =>
      'Deficiência, estudante deslocado, guarda partilhada e outras situações especiais.';
}

/// The translations for Portuguese, as used in Portugal (`pt_PT`).
class AppLocalizationsPtPt extends AppLocalizationsPt {
  AppLocalizationsPtPt() : super('pt_PT');

  @override
  String get appTitle => 'taxy.pt';

  @override
  String get settings => 'Definições';

  @override
  String get language => 'Idioma';

  @override
  String get languageDescription => 'Escolhe o idioma da aplicação.';

  @override
  String get languageAutomatic => 'Automático';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSystemHint =>
      'Segue o idioma do telemóvel. Outros idiomas usam português.';

  @override
  String get back => 'Voltar';

  @override
  String get experimental => 'Experimental';

  @override
  String get efaturaTitle => 'e-Fatura';

  @override
  String get efaturaHeroTitle => 'As tuas despesas, só para consulta';

  @override
  String get efaturaCredentialNotice =>
      'As credenciais são utilizadas apenas para consultar o e-Fatura.';

  @override
  String get connectPortalTitle => 'Ligar ao e-Fatura';

  @override
  String get nif => 'NIF';

  @override
  String get password => 'Senha';

  @override
  String get connectEfatura => 'Ligar ao e-Fatura';

  @override
  String get disconnectEfatura => 'Desligar e-Fatura';

  @override
  String get disconnectTitle => 'Desligar e-Fatura?';

  @override
  String get disconnectExplanation =>
      'Isto termina a sessão guardada neste dispositivo.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get disconnect => 'Desligar';

  @override
  String get selectDeviceCertificate => 'Selecionar certificado do dispositivo';

  @override
  String get selectAtPublicKey => 'Selecionar chave pública da AT';

  @override
  String get refresh => 'Atualizar';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get overviewTitle => 'Resumo e-Fatura';

  @override
  String get provisionalTaxBenefit => 'Benefício provisório';

  @override
  String get invoicesToValidate => 'Faturas com informação pendente';

  @override
  String get invoicesToAssociate => 'Faturas por associar receita';

  @override
  String get expensesByCategory => 'Despesas por categoria';

  @override
  String get sectors => 'Setores';

  @override
  String get pendingInvoicesTitle => 'Faturas pendentes';

  @override
  String get sectorInvoicesTitle => 'Faturas do setor';

  @override
  String get viewPendingInvoices => 'Ver faturas por validar';

  @override
  String get noInvoicesToValidate => 'Sem faturas pendentes';

  @override
  String get noInvoicesInCategory => 'Sem faturas neste setor';

  @override
  String get noActivityInCategory => 'Sem atividade neste setor';

  @override
  String get noDataAvailable => 'Sem dados disponíveis';

  @override
  String get unavailable => 'Indisponível';

  @override
  String get partialEfaturaData =>
      'Alguns valores do e-Fatura não estão disponíveis. As faturas carregadas continuam acessíveis.';

  @override
  String get benefitUnavailable => 'Benefício não disponível';

  @override
  String get readOnlyNoValidation =>
      'A Taxy apresenta esta contagem apenas para consulta. A validação continua a ser feita no e-Fatura oficial.';

  @override
  String get irsPredictionDataTitle => 'Dados para previsão de IRS';

  @override
  String get officialProvisionalBenefit =>
      'Benefício provisório indicado pela AT';

  @override
  String get listedExpenses => 'Despesas listadas';

  @override
  String get listedVat => 'IVA das despesas listadas';

  @override
  String get irsPredictionDisclaimer =>
      'Estes dados ajudam a preparar a previsão. Não representam, por si só, o reembolso ou imposto final de IRS.';

  @override
  String get issuerUnavailable => 'Emitente não disponível';

  @override
  String invoiceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count faturas',
      one: '1 fatura',
      zero: 'Sem faturas',
    );
    return '$_temp0';
  }

  @override
  String get authErrorTitle => 'Não foi possível autenticar';

  @override
  String get authErrorMessage =>
      'Não foi possível autenticar no Portal das Finanças.';

  @override
  String get authorizationErrorTitle => 'Acesso não autorizado';

  @override
  String get authorizationErrorMessage =>
      'O Portal das Finanças não autorizou esta consulta.';

  @override
  String get operationUnavailableTitle => 'Consulta indisponível';

  @override
  String get operationUnavailableMessage =>
      'Esta consulta ainda não está disponível.';

  @override
  String get rateLimitedTitle => 'Demasiadas consultas';

  @override
  String get rateLimitedMessage =>
      'Aguarda um pouco antes de tentar novamente.';

  @override
  String get networkErrorTitle => 'Erro de ligação';

  @override
  String get networkErrorMessage => 'Não foi possível estabelecer ligação.';

  @override
  String get serviceErrorTitle => 'Serviço indisponível';

  @override
  String get serviceErrorMessage =>
      'O serviço e-Fatura não está disponível de momento.';

  @override
  String get parsingErrorTitle => 'Resposta inesperada';

  @override
  String get parsingErrorMessage =>
      'Recebemos uma resposta inesperada do e-Fatura.';

  @override
  String get sessionExpiredTitle => 'Sessão expirada';

  @override
  String get sessionExpiredMessage =>
      'Volta a ligar ao e-Fatura para continuar.';

  @override
  String get notConfiguredTitle => 'Ligação ainda não configurada';

  @override
  String get genericErrorTitle => 'Não foi possível atualizar';

  @override
  String get genericErrorMessage => 'Não foi possível ligar ao e-Fatura.';

  @override
  String get connecting => 'A ligar ao e-Fatura…';

  @override
  String get updating => 'A atualizar…';

  @override
  String get connected => 'Ligado';

  @override
  String get welcomeTagline => 'IRS, explicado para pessoas';

  @override
  String get welcomeTitle => 'Percebe o teu IRS.\nDecide com confiança.';

  @override
  String get welcomeBody =>
      'Uma conversa simples transforma os teus dados numa estimativa clara — sem formulários, sem fiscalês.';

  @override
  String get startSimulation => 'Começar simulação';

  @override
  String get resumeSimulation => 'Retomar simulação';

  @override
  String get howWeCalculate => 'Ver como fazemos as contas';

  @override
  String get dataOnDevice => 'Dados no dispositivo';

  @override
  String rulesVerified(int year) {
    return 'Regras $year verificadas';
  }

  @override
  String get simulators => 'Simuladores';

  @override
  String get available => 'Disponível';

  @override
  String get efaturaModuleDescription =>
      'Consulta read-only · funcionalidade interna';

  @override
  String get futureSimulators => 'Outros simuladores · Em breve';

  @override
  String futureSimulatorsSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count simuladores futuros em preparação',
      one: '1 simulador futuro em preparação',
    );
    return '$_temp0';
  }

  @override
  String get privateLabel => 'Privado';

  @override
  String get efaturaSemantics => 'e-Fatura experimental, consulta apenas';

  @override
  String get sectorCarRepairs => 'Reparação de automóveis';

  @override
  String get sectorMotorcycleRepairs => 'Reparação de motociclos';

  @override
  String get sectorHospitality => 'Alojamento e restauração';

  @override
  String get sectorHairdressing => 'Cabeleireiros';

  @override
  String get sectorHealth => 'Saúde';

  @override
  String get sectorEducation => 'Educação';

  @override
  String get sectorHousing => 'Habitação';

  @override
  String get sectorNursingHomes => 'Lares';

  @override
  String get sectorVeterinary => 'Veterinários';

  @override
  String get sectorPublicTransport => 'Transportes públicos';

  @override
  String get sectorGyms => 'Ginásios';

  @override
  String get sectorNewspapers => 'Jornais e revistas';

  @override
  String get sectorDomesticServices => 'Serviços domésticos';

  @override
  String get sectorOther => 'Outras despesas';

  @override
  String get invalidNif => 'Introduz um NIF com 9 algarismos.';

  @override
  String get passwordRequired => 'Introduz a senha.';

  @override
  String get rulesLoadError =>
      'Não foi possível carregar as regras fiscais com segurança. Fecha e volta a abrir a aplicação.';

  @override
  String get savedDataLoadError =>
      'Não foi possível abrir os dados guardados neste dispositivo.';

  @override
  String get simulationsLoadError =>
      'Não foi possível abrir as simulações guardadas neste dispositivo.';

  @override
  String get simulationRulesLoadError =>
      'Não foi possível carregar as regras desta simulação com segurança.';

  @override
  String get internalBetaBuild => 'Informação da beta interna';

  @override
  String get appVersion => 'Versão';

  @override
  String get gitRevision => 'Revisão';

  @override
  String get environment => 'Ambiente';

  @override
  String get apiHost => 'Servidor API';

  @override
  String get fiscalProfile => 'Perfil fiscal';

  @override
  String get profileComplete => 'Perfil completo';

  @override
  String get profileIncomplete => 'Perfil incompleto';

  @override
  String get profilePurpose =>
      'Estes dados mantêm o ano fiscal e as simulações coerentes. Valores desconhecidos continuam indisponíveis.';

  @override
  String get activeTaxYear => 'Ano fiscal ativo';

  @override
  String get taxResidence => 'Residência fiscal';

  @override
  String get unknownValue => 'Não indicado';

  @override
  String get mainlandPortugal => 'Portugal continental';

  @override
  String get madeira => 'Madeira';

  @override
  String get azores => 'Açores';

  @override
  String get civilStatusLabel => 'Estado civil';

  @override
  String get single => 'Solteiro/a';

  @override
  String get married => 'Casado/a';

  @override
  String get deFactoUnion => 'União de facto';

  @override
  String get dependants => 'Dependentes';

  @override
  String get employmentIncome => 'Rendimentos de trabalho dependente';

  @override
  String get selfEmploymentIncome => 'Rendimentos de trabalho independente';

  @override
  String get yes => 'Sim';

  @override
  String get no => 'Não';

  @override
  String get save => 'Guardar';

  @override
  String get localDataUnavailable =>
      'Não foi possível abrir os dados guardados neste dispositivo.';

  @override
  String get income => 'Rendimentos';

  @override
  String get expenses => 'Despesas';

  @override
  String get addIncome => 'Adicionar rendimento';

  @override
  String get addExpense => 'Adicionar despesa';

  @override
  String totalForYear(int year) {
    return 'Total de $year';
  }

  @override
  String get localIncomeNotice =>
      'Registos apenas locais. Não são importados nem apresentados como dados oficiais.';

  @override
  String get localExpenseNotice =>
      'Os registos locais são informação de apoio e não são tratados automaticamente como deduções de IRS.';

  @override
  String get noIncomeRegistered => 'Sem rendimentos registados neste ano';

  @override
  String get noExpensesRegistered => 'Sem despesas registadas neste ano';

  @override
  String get amountEuros => 'Valor em euros';

  @override
  String get remove => 'Remover';

  @override
  String get sourceManual => 'Introduzido manualmente';

  @override
  String get sourceImported => 'Importado';

  @override
  String get sourceExternal => 'Fonte externa';

  @override
  String get sourceCalculated => 'Calculado';

  @override
  String get statusConfirmed => 'Confirmado';

  @override
  String get statusEstimated => 'Estimado';

  @override
  String get statusPossibleDuplicate => 'Possível duplicado';

  @override
  String get privacyAndSecurity => 'Privacidade e segurança';

  @override
  String get privacyIntro =>
      'A Taxy guarda as simulações e os registos locais neste dispositivo. As credenciais e-Fatura são enviadas por HTTPS apenas para api.taxy.pt durante a ligação e não regressam à interface.';

  @override
  String get privacyEfatura =>
      'O acesso ao e-Fatura é apenas de leitura. Desligar remove deste dispositivo a capacidade de sessão guardada.';

  @override
  String get diagnostics => 'Diagnóstico';

  @override
  String get copyDiagnostics => 'Copiar informações de diagnóstico';

  @override
  String get diagnosticsCopied => 'Informações de diagnóstico copiadas';

  @override
  String get diagnosticsNotice =>
      'O diagnóstico contém apenas versão e ambiente — nunca NIF, credenciais, tokens ou dados de faturas.';

  @override
  String get sendFeedback => 'Enviar feedback';

  @override
  String get feedbackCopied => 'Foi copiado um modelo seguro de feedback.';

  @override
  String get appearance => 'Aparência';

  @override
  String get themeSystem => 'Usar definição do dispositivo';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get profileModuleDescription => 'Ano ativo e dados fiscais';

  @override
  String get incomeModuleDescription => 'Rendimentos locais com origem';

  @override
  String get expensesModuleDescription => 'Despesas locais de apoio';

  @override
  String get estimateBasis => 'O que esta estimativa considera';

  @override
  String get incomeConsidered => 'Rendimentos considerados';

  @override
  String get deductionsConsidered => 'Deduções consideradas';

  @override
  String get withholdingConsidered => 'Retenções consideradas';

  @override
  String get userEnteredSource => 'Introduzido por ti';

  @override
  String get estimateNotOfficial =>
      'Estimativa baseada na informação introduzida e nas regras suportadas pela Taxy. Não é uma liquidação oficial da AT.';

  @override
  String get missingInformationImprove =>
      'Falta informação para melhorar esta estimativa.';

  @override
  String get category => 'Categoria';

  @override
  String get categoryEmployment => 'Trabalho dependente';

  @override
  String get categorySelfEmployment => 'Trabalho independente';

  @override
  String get categoryPension => 'Pensão';

  @override
  String get categoryOther => 'Outra';

  @override
  String get categoryGeneral => 'Geral';

  @override
  String get categoryHealth => 'Saúde';

  @override
  String get categoryEducation => 'Educação';

  @override
  String get categoryHousing => 'Habitação';

  @override
  String get categoryProfessional => 'Atividade profissional';

  @override
  String get edit => 'Editar';

  @override
  String get profileChecklist => 'Checklist fiscal';

  @override
  String completedEssential(int completed, int total) {
    return '$completed de $total elementos essenciais preenchidos';
  }

  @override
  String get checkActiveYear => 'Ano fiscal ativo';

  @override
  String get checkResidence => 'Residência fiscal';

  @override
  String get checkCivilStatus => 'Estado civil';

  @override
  String get checkHousehold => 'Agregado';

  @override
  String get checkWorkContext => 'Situação profissional';

  @override
  String get checkIncome => 'Rendimentos do ano ativo';

  @override
  String get impactResidence =>
      'A residência determina as regras regionais suportadas aplicáveis.';

  @override
  String get impactCivilStatus =>
      'O estado civil é necessário para escolher um modo de cálculo aplicável.';

  @override
  String get impactHousehold =>
      'O agregado pode afetar deduções e benefícios suportados.';

  @override
  String get impactWorkContext =>
      'A situação profissional permite saber se o modelo atual suporta os rendimentos.';

  @override
  String get impactIncome =>
      'Os rendimentos e retenções são necessários para estimar o saldo final de IRS.';

  @override
  String get scenarioComparison => 'Comparar cenários';

  @override
  String get scenarioIntro =>
      'Testa alterações hipotéticas sem mudar a informação base.';

  @override
  String get currentScenario => 'Cenário atual';

  @override
  String get alternativeScenario => 'Cenário alternativo';

  @override
  String get resultDifference => 'Diferença no resultado';

  @override
  String get whatChanged => 'O que mudou';

  @override
  String get noScenarioChanges => 'Ainda não existem alterações hipotéticas.';

  @override
  String get scenarioOverrideNotice =>
      'Os valores alternativos são hipóteses do cenário, não dados confirmados do perfil.';

  @override
  String get savedEstimates => 'Estimativas guardadas';

  @override
  String get saveEstimate => 'Guardar estimativa';

  @override
  String get estimateSaved => 'Estimativa guardada neste dispositivo.';

  @override
  String get savedEstimate => 'Estimativa guardada';

  @override
  String get noSavedEstimates => 'Sem estimativas guardadas';

  @override
  String get deleteSavedEstimate => 'Apagar estimativa guardada';

  @override
  String get duplicateAsScenario => 'Duplicar como cenário';

  @override
  String get invoiceExplorer => 'Explorador de faturas';

  @override
  String get searchInvoices => 'Pesquisar emitente';

  @override
  String get documentTotal => 'Total dos documentos';

  @override
  String get monthlySummary => 'Resumo mensal';

  @override
  String get averageDocument => 'Média por documento';

  @override
  String get sortNewest => 'Mais recentes';

  @override
  String get sortOldest => 'Mais antigas';

  @override
  String get sortHighest => 'Maior valor';

  @override
  String get sortLowest => 'Menor valor';

  @override
  String get sortIssuer => 'Nome do emitente';

  @override
  String filteredInvoiceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count faturas correspondentes',
      one: '1 fatura correspondente',
      zero: 'Sem faturas correspondentes',
    );
    return '$_temp0';
  }

  @override
  String lastUpdatedThisSession(String time) {
    return 'Última atualização nesta sessão: $time';
  }

  @override
  String get offlineUnavailable =>
      'Esta área precisa de ligação. Verifica a rede e tenta novamente.';

  @override
  String get tryAgain => 'Tentar novamente';

  @override
  String get dateFilter => 'Intervalo de datas';

  @override
  String get minimumAmount => 'Valor mínimo';

  @override
  String get maximumAmount => 'Valor máximo';

  @override
  String get privacySnapshots =>
      'As estimativas IRS guardadas ficam apenas neste dispositivo. Contêm inputs e resultados normalizados, nunca credenciais ou respostas e-Fatura em bruto.';

  @override
  String get all => 'Todos';

  @override
  String get dashboardTitle => 'O teu IRS, num relance';

  @override
  String simulationUpdatedForYear(int year) {
    return 'Simulação atualizada com as regras de $year.';
  }

  @override
  String get resumeDraft => 'Retomar simulação em curso';

  @override
  String get viewCalculation => 'Ver cálculo';

  @override
  String get change => 'Alterar';

  @override
  String get compare => 'Comparar';

  @override
  String get exploreTaxOpportunities => 'Explorar oportunidades fiscais';

  @override
  String get readOnlyExperimental => 'Consulta experimental apenas de leitura';

  @override
  String get yourSimulations => 'As tuas simulações';

  @override
  String savedSimulationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count guardadas neste dispositivo',
      one: '1 guardada neste dispositivo',
      zero: 'Nenhuma guardada neste dispositivo',
    );
    return '$_temp0';
  }

  @override
  String get newSimulation => 'Nova';

  @override
  String refundAmount(String amount) {
    return 'Reembolso $amount';
  }

  @override
  String taxDueAmount(String amount) {
    return 'A pagar $amount';
  }

  @override
  String get calculationUnavailable => 'Cálculo indisponível';

  @override
  String get options => 'Opções';

  @override
  String get rename => 'Renomear';

  @override
  String get duplicate => 'Duplicar';

  @override
  String get changeData => 'Alterar dados';

  @override
  String get delete => 'Apagar';

  @override
  String get renameSimulation => 'Renomear simulação';

  @override
  String get name => 'Nome';

  @override
  String copySimulationName(String name) {
    return '$name — cópia';
  }

  @override
  String get deleteSimulationTitle => 'Apagar esta simulação?';

  @override
  String deleteSimulationMessage(String name) {
    return '“$name” será removida apenas deste dispositivo.';
  }

  @override
  String get estimatedRefund => 'Reembolso estimado';

  @override
  String get estimatedAdditionalTax => 'Imposto adicional estimado';

  @override
  String get estimateUnavailable => 'Estimativa indisponível';

  @override
  String get openDetails => 'Abrir detalhe';

  @override
  String get transparencyFirst => 'Transparência primeiro';

  @override
  String get calculationMethodIntro =>
      'O cálculo é determinístico e não usa inteligência artificial. Valores monetários são tratados em cêntimos inteiros, com arredondamento explícito.';

  @override
  String get netCategoryIncome => 'Rendimento líquido da categoria';

  @override
  String get netCategoryIncomeExplanation =>
      'Ao rendimento bruto subtraímos a dedução específica aplicável ao trabalho dependente.';

  @override
  String get minimumExistence => 'Mínimo de existência';

  @override
  String get minimumExistenceExplanation =>
      'Quando aplicável, calculamos o abatimento previsto no artigo 70.º do Código do IRS.';

  @override
  String get progressiveBrackets => 'Escalões progressivos';

  @override
  String progressiveBracketsExplanation(int year) {
    return 'Aplicamos as taxas gerais de $year ao rendimento coletável.';
  }

  @override
  String get deductionsAndWithholding => 'Deduções e retenções';

  @override
  String get deductionsAndWithholdingExplanation =>
      'Aplicamos limites por categoria e o limite conjunto. Por fim, descontamos o IRS já retido.';

  @override
  String get validatedScope => 'Âmbito validado';

  @override
  String get unsupportedScope => 'Não suportado / por verificar';

  @override
  String get openValidationLab => 'Abrir laboratório de validação fiscal';

  @override
  String validatedResidentScope(String jurisdiction) {
    return 'Residente durante todo o ano · $jurisdiction.';
  }

  @override
  String get categoryAOnlyScope => 'Rendimentos exclusivamente da Categoria A.';

  @override
  String get standardHouseholdScope =>
      'Individual, família monoparental, casamento ou união de facto standard.';

  @override
  String get couplesComparisonScope =>
      'Nos casais, calculamos separada e conjunta e mostramos a diferença.';

  @override
  String get standardDependantsScope =>
      'Dependentes standard, sem guarda partilhada, residência alternada ou alocação especial.';

  @override
  String get standardEducationScope =>
      'Educação standard, sem estudante deslocado ou majorações territoriais.';

  @override
  String verifiedRulesScope(String version, String date) {
    return 'Regras $version, verificadas em $date.';
  }

  @override
  String get regional2025Unsupported => 'Madeira e Açores em 2025.';

  @override
  String get partialResidenceUnsupported =>
      'Residência parcial ou não residência.';

  @override
  String get incomeTypesUnsupported =>
      'Liquidação IRS Jovem, Categoria B e pensões.';

  @override
  String get foreignIncomeUnsupported =>
      'Rendimentos estrangeiros, de capitais, prediais e mais-valias.';

  @override
  String get specialSituationsUnsupported =>
      'Deficiência, estudante deslocado, guarda partilhada e outras situações especiais.';
}
