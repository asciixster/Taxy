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
}
