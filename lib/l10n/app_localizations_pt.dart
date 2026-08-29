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
      'Isto remove as credenciais guardadas neste dispositivo.';

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
  String get invoicesToValidate => 'Faturas por validar';

  @override
  String get invoicesToAssociate => 'Faturas por associar receita';

  @override
  String get expensesByCategory => 'Despesas por categoria';

  @override
  String get sectors => 'Setores';

  @override
  String get pendingInvoicesTitle => 'Faturas por validar';

  @override
  String get sectorInvoicesTitle => 'Faturas do setor';

  @override
  String get viewPendingInvoices => 'Ver faturas por validar';

  @override
  String get noInvoicesToValidate => 'Sem faturas por validar';

  @override
  String get noInvoicesInCategory => 'Sem faturas neste setor';

  @override
  String get noActivityInCategory => 'Sem atividade neste setor';

  @override
  String get noDataAvailable => 'Sem dados disponíveis';

  @override
  String get benefitUnavailable => 'Benefício não disponível';

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
      'Isto remove as credenciais guardadas neste dispositivo.';

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
  String get invoicesToValidate => 'Faturas por validar';

  @override
  String get invoicesToAssociate => 'Faturas por associar receita';

  @override
  String get expensesByCategory => 'Despesas por categoria';

  @override
  String get sectors => 'Setores';

  @override
  String get pendingInvoicesTitle => 'Faturas por validar';

  @override
  String get sectorInvoicesTitle => 'Faturas do setor';

  @override
  String get viewPendingInvoices => 'Ver faturas por validar';

  @override
  String get noInvoicesToValidate => 'Sem faturas por validar';

  @override
  String get noInvoicesInCategory => 'Sem faturas neste setor';

  @override
  String get noActivityInCategory => 'Sem atividade neste setor';

  @override
  String get noDataAvailable => 'Sem dados disponíveis';

  @override
  String get benefitUnavailable => 'Benefício não disponível';

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
}
