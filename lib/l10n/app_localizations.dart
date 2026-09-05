import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('pt', 'PT'),
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'taxy.pt'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In pt, this message translates to:
  /// **'Definições'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @languageDescription.
  ///
  /// In pt, this message translates to:
  /// **'Escolhe o idioma da aplicação.'**
  String get languageDescription;

  /// No description provided for @languageAutomatic.
  ///
  /// In pt, this message translates to:
  /// **'Automático'**
  String get languageAutomatic;

  /// No description provided for @languagePortuguese.
  ///
  /// In pt, this message translates to:
  /// **'Português'**
  String get languagePortuguese;

  /// No description provided for @languageEnglish.
  ///
  /// In pt, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSystemHint.
  ///
  /// In pt, this message translates to:
  /// **'Segue o idioma do telemóvel. Outros idiomas usam português.'**
  String get languageSystemHint;

  /// No description provided for @back.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get back;

  /// No description provided for @experimental.
  ///
  /// In pt, this message translates to:
  /// **'Experimental'**
  String get experimental;

  /// No description provided for @efaturaTitle.
  ///
  /// In pt, this message translates to:
  /// **'e-Fatura'**
  String get efaturaTitle;

  /// No description provided for @efaturaHeroTitle.
  ///
  /// In pt, this message translates to:
  /// **'As tuas despesas, só para consulta'**
  String get efaturaHeroTitle;

  /// No description provided for @efaturaCredentialNotice.
  ///
  /// In pt, this message translates to:
  /// **'As credenciais são utilizadas apenas para consultar o e-Fatura.'**
  String get efaturaCredentialNotice;

  /// No description provided for @connectPortalTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ligar ao e-Fatura'**
  String get connectPortalTitle;

  /// No description provided for @nif.
  ///
  /// In pt, this message translates to:
  /// **'NIF'**
  String get nif;

  /// No description provided for @password.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get password;

  /// No description provided for @connectEfatura.
  ///
  /// In pt, this message translates to:
  /// **'Ligar ao e-Fatura'**
  String get connectEfatura;

  /// No description provided for @disconnectEfatura.
  ///
  /// In pt, this message translates to:
  /// **'Desligar e-Fatura'**
  String get disconnectEfatura;

  /// No description provided for @disconnectTitle.
  ///
  /// In pt, this message translates to:
  /// **'Desligar e-Fatura?'**
  String get disconnectTitle;

  /// No description provided for @disconnectExplanation.
  ///
  /// In pt, this message translates to:
  /// **'Isto termina a sessão guardada neste dispositivo.'**
  String get disconnectExplanation;

  /// No description provided for @cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @disconnect.
  ///
  /// In pt, this message translates to:
  /// **'Desligar'**
  String get disconnect;

  /// No description provided for @selectDeviceCertificate.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar certificado do dispositivo'**
  String get selectDeviceCertificate;

  /// No description provided for @selectAtPublicKey.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar chave pública da AT'**
  String get selectAtPublicKey;

  /// No description provided for @refresh.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar'**
  String get refresh;

  /// No description provided for @retry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get retry;

  /// No description provided for @overviewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Resumo e-Fatura'**
  String get overviewTitle;

  /// No description provided for @provisionalTaxBenefit.
  ///
  /// In pt, this message translates to:
  /// **'Benefício provisório'**
  String get provisionalTaxBenefit;

  /// No description provided for @invoicesToValidate.
  ///
  /// In pt, this message translates to:
  /// **'Faturas com informação pendente'**
  String get invoicesToValidate;

  /// No description provided for @invoicesToAssociate.
  ///
  /// In pt, this message translates to:
  /// **'Faturas por associar receita'**
  String get invoicesToAssociate;

  /// No description provided for @expensesByCategory.
  ///
  /// In pt, this message translates to:
  /// **'Despesas por categoria'**
  String get expensesByCategory;

  /// No description provided for @sectors.
  ///
  /// In pt, this message translates to:
  /// **'Setores'**
  String get sectors;

  /// No description provided for @pendingInvoicesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Faturas pendentes'**
  String get pendingInvoicesTitle;

  /// No description provided for @sectorInvoicesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Faturas do setor'**
  String get sectorInvoicesTitle;

  /// No description provided for @viewPendingInvoices.
  ///
  /// In pt, this message translates to:
  /// **'Ver faturas por validar'**
  String get viewPendingInvoices;

  /// No description provided for @noInvoicesToValidate.
  ///
  /// In pt, this message translates to:
  /// **'Sem faturas pendentes'**
  String get noInvoicesToValidate;

  /// No description provided for @noInvoicesInCategory.
  ///
  /// In pt, this message translates to:
  /// **'Sem faturas neste setor'**
  String get noInvoicesInCategory;

  /// No description provided for @noActivityInCategory.
  ///
  /// In pt, this message translates to:
  /// **'Sem atividade neste setor'**
  String get noActivityInCategory;

  /// No description provided for @noDataAvailable.
  ///
  /// In pt, this message translates to:
  /// **'Sem dados disponíveis'**
  String get noDataAvailable;

  /// No description provided for @unavailable.
  ///
  /// In pt, this message translates to:
  /// **'Indisponível'**
  String get unavailable;

  /// No description provided for @partialEfaturaData.
  ///
  /// In pt, this message translates to:
  /// **'Alguns valores do e-Fatura não estão disponíveis. As faturas carregadas continuam acessíveis.'**
  String get partialEfaturaData;

  /// No description provided for @benefitUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Benefício não disponível'**
  String get benefitUnavailable;

  /// No description provided for @readOnlyNoValidation.
  ///
  /// In pt, this message translates to:
  /// **'A Taxy apresenta esta contagem apenas para consulta. A validação continua a ser feita no e-Fatura oficial.'**
  String get readOnlyNoValidation;

  /// No description provided for @irsPredictionDataTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dados para previsão de IRS'**
  String get irsPredictionDataTitle;

  /// No description provided for @officialProvisionalBenefit.
  ///
  /// In pt, this message translates to:
  /// **'Benefício provisório indicado pela AT'**
  String get officialProvisionalBenefit;

  /// No description provided for @listedExpenses.
  ///
  /// In pt, this message translates to:
  /// **'Despesas listadas'**
  String get listedExpenses;

  /// No description provided for @listedVat.
  ///
  /// In pt, this message translates to:
  /// **'IVA das despesas listadas'**
  String get listedVat;

  /// No description provided for @irsPredictionDisclaimer.
  ///
  /// In pt, this message translates to:
  /// **'Estes dados ajudam a preparar a previsão. Não representam, por si só, o reembolso ou imposto final de IRS.'**
  String get irsPredictionDisclaimer;

  /// No description provided for @issuerUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Emitente não disponível'**
  String get issuerUnavailable;

  /// No description provided for @invoiceCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Sem faturas} =1{1 fatura} other{{count} faturas}}'**
  String invoiceCount(int count);

  /// No description provided for @authErrorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível autenticar'**
  String get authErrorTitle;

  /// No description provided for @authErrorMessage.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível autenticar no Portal das Finanças.'**
  String get authErrorMessage;

  /// No description provided for @authorizationErrorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Acesso não autorizado'**
  String get authorizationErrorTitle;

  /// No description provided for @authorizationErrorMessage.
  ///
  /// In pt, this message translates to:
  /// **'O Portal das Finanças não autorizou esta consulta.'**
  String get authorizationErrorMessage;

  /// No description provided for @operationUnavailableTitle.
  ///
  /// In pt, this message translates to:
  /// **'Consulta indisponível'**
  String get operationUnavailableTitle;

  /// No description provided for @operationUnavailableMessage.
  ///
  /// In pt, this message translates to:
  /// **'Esta consulta ainda não está disponível.'**
  String get operationUnavailableMessage;

  /// No description provided for @rateLimitedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Demasiadas consultas'**
  String get rateLimitedTitle;

  /// No description provided for @rateLimitedMessage.
  ///
  /// In pt, this message translates to:
  /// **'Aguarda um pouco antes de tentar novamente.'**
  String get rateLimitedMessage;

  /// No description provided for @networkErrorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Erro de ligação'**
  String get networkErrorTitle;

  /// No description provided for @networkErrorMessage.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível estabelecer ligação.'**
  String get networkErrorMessage;

  /// No description provided for @serviceErrorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Serviço indisponível'**
  String get serviceErrorTitle;

  /// No description provided for @serviceErrorMessage.
  ///
  /// In pt, this message translates to:
  /// **'O serviço e-Fatura não está disponível de momento.'**
  String get serviceErrorMessage;

  /// No description provided for @parsingErrorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Resposta inesperada'**
  String get parsingErrorTitle;

  /// No description provided for @parsingErrorMessage.
  ///
  /// In pt, this message translates to:
  /// **'Recebemos uma resposta inesperada do e-Fatura.'**
  String get parsingErrorMessage;

  /// No description provided for @sessionExpiredTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sessão expirada'**
  String get sessionExpiredTitle;

  /// No description provided for @sessionExpiredMessage.
  ///
  /// In pt, this message translates to:
  /// **'Volta a ligar ao e-Fatura para continuar.'**
  String get sessionExpiredMessage;

  /// No description provided for @notConfiguredTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ligação ainda não configurada'**
  String get notConfiguredTitle;

  /// No description provided for @genericErrorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível atualizar'**
  String get genericErrorTitle;

  /// No description provided for @genericErrorMessage.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível ligar ao e-Fatura.'**
  String get genericErrorMessage;

  /// No description provided for @connecting.
  ///
  /// In pt, this message translates to:
  /// **'A ligar ao e-Fatura…'**
  String get connecting;

  /// No description provided for @updating.
  ///
  /// In pt, this message translates to:
  /// **'A atualizar…'**
  String get updating;

  /// No description provided for @connected.
  ///
  /// In pt, this message translates to:
  /// **'Ligado'**
  String get connected;

  /// No description provided for @welcomeTagline.
  ///
  /// In pt, this message translates to:
  /// **'IRS, explicado para pessoas'**
  String get welcomeTagline;

  /// No description provided for @welcomeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Percebe o teu IRS.\nDecide com confiança.'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In pt, this message translates to:
  /// **'Uma conversa simples transforma os teus dados numa estimativa clara — sem formulários, sem fiscalês.'**
  String get welcomeBody;

  /// No description provided for @startSimulation.
  ///
  /// In pt, this message translates to:
  /// **'Começar simulação'**
  String get startSimulation;

  /// No description provided for @resumeSimulation.
  ///
  /// In pt, this message translates to:
  /// **'Retomar simulação'**
  String get resumeSimulation;

  /// No description provided for @howWeCalculate.
  ///
  /// In pt, this message translates to:
  /// **'Ver como fazemos as contas'**
  String get howWeCalculate;

  /// No description provided for @dataOnDevice.
  ///
  /// In pt, this message translates to:
  /// **'Dados no dispositivo'**
  String get dataOnDevice;

  /// No description provided for @rulesVerified.
  ///
  /// In pt, this message translates to:
  /// **'Regras {year} verificadas'**
  String rulesVerified(int year);

  /// No description provided for @simulators.
  ///
  /// In pt, this message translates to:
  /// **'Simuladores'**
  String get simulators;

  /// No description provided for @available.
  ///
  /// In pt, this message translates to:
  /// **'Disponível'**
  String get available;

  /// No description provided for @efaturaModuleDescription.
  ///
  /// In pt, this message translates to:
  /// **'Consulta read-only · funcionalidade interna'**
  String get efaturaModuleDescription;

  /// No description provided for @futureSimulators.
  ///
  /// In pt, this message translates to:
  /// **'Outros simuladores · Em breve'**
  String get futureSimulators;

  /// No description provided for @futureSimulatorsSemantics.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 simulador futuro em preparação} other{{count} simuladores futuros em preparação}}'**
  String futureSimulatorsSemantics(int count);

  /// No description provided for @privateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Privado'**
  String get privateLabel;

  /// No description provided for @efaturaSemantics.
  ///
  /// In pt, this message translates to:
  /// **'e-Fatura experimental, consulta apenas'**
  String get efaturaSemantics;

  /// No description provided for @sectorCarRepairs.
  ///
  /// In pt, this message translates to:
  /// **'Reparação de automóveis'**
  String get sectorCarRepairs;

  /// No description provided for @sectorMotorcycleRepairs.
  ///
  /// In pt, this message translates to:
  /// **'Reparação de motociclos'**
  String get sectorMotorcycleRepairs;

  /// No description provided for @sectorHospitality.
  ///
  /// In pt, this message translates to:
  /// **'Alojamento e restauração'**
  String get sectorHospitality;

  /// No description provided for @sectorHairdressing.
  ///
  /// In pt, this message translates to:
  /// **'Cabeleireiros'**
  String get sectorHairdressing;

  /// No description provided for @sectorHealth.
  ///
  /// In pt, this message translates to:
  /// **'Saúde'**
  String get sectorHealth;

  /// No description provided for @sectorEducation.
  ///
  /// In pt, this message translates to:
  /// **'Educação'**
  String get sectorEducation;

  /// No description provided for @sectorHousing.
  ///
  /// In pt, this message translates to:
  /// **'Habitação'**
  String get sectorHousing;

  /// No description provided for @sectorNursingHomes.
  ///
  /// In pt, this message translates to:
  /// **'Lares'**
  String get sectorNursingHomes;

  /// No description provided for @sectorVeterinary.
  ///
  /// In pt, this message translates to:
  /// **'Veterinários'**
  String get sectorVeterinary;

  /// No description provided for @sectorPublicTransport.
  ///
  /// In pt, this message translates to:
  /// **'Transportes públicos'**
  String get sectorPublicTransport;

  /// No description provided for @sectorGyms.
  ///
  /// In pt, this message translates to:
  /// **'Ginásios'**
  String get sectorGyms;

  /// No description provided for @sectorNewspapers.
  ///
  /// In pt, this message translates to:
  /// **'Jornais e revistas'**
  String get sectorNewspapers;

  /// No description provided for @sectorDomesticServices.
  ///
  /// In pt, this message translates to:
  /// **'Serviços domésticos'**
  String get sectorDomesticServices;

  /// No description provided for @sectorOther.
  ///
  /// In pt, this message translates to:
  /// **'Outras despesas'**
  String get sectorOther;

  /// No description provided for @invalidNif.
  ///
  /// In pt, this message translates to:
  /// **'Introduz um NIF com 9 algarismos.'**
  String get invalidNif;

  /// No description provided for @passwordRequired.
  ///
  /// In pt, this message translates to:
  /// **'Introduz a senha.'**
  String get passwordRequired;

  /// No description provided for @rulesLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as regras fiscais com segurança. Fecha e volta a abrir a aplicação.'**
  String get rulesLoadError;

  /// No description provided for @savedDataLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir os dados guardados neste dispositivo.'**
  String get savedDataLoadError;

  /// No description provided for @simulationsLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir as simulações guardadas neste dispositivo.'**
  String get simulationsLoadError;

  /// No description provided for @simulationRulesLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as regras desta simulação com segurança.'**
  String get simulationRulesLoadError;

  /// No description provided for @internalBetaBuild.
  ///
  /// In pt, this message translates to:
  /// **'Informação da beta interna'**
  String get internalBetaBuild;

  /// No description provided for @appVersion.
  ///
  /// In pt, this message translates to:
  /// **'Versão'**
  String get appVersion;

  /// No description provided for @gitRevision.
  ///
  /// In pt, this message translates to:
  /// **'Revisão'**
  String get gitRevision;

  /// No description provided for @environment.
  ///
  /// In pt, this message translates to:
  /// **'Ambiente'**
  String get environment;

  /// No description provided for @apiHost.
  ///
  /// In pt, this message translates to:
  /// **'Servidor API'**
  String get apiHost;

  /// No description provided for @fiscalProfile.
  ///
  /// In pt, this message translates to:
  /// **'Perfil fiscal'**
  String get fiscalProfile;

  /// No description provided for @profileComplete.
  ///
  /// In pt, this message translates to:
  /// **'Perfil completo'**
  String get profileComplete;

  /// No description provided for @profileIncomplete.
  ///
  /// In pt, this message translates to:
  /// **'Perfil incompleto'**
  String get profileIncomplete;

  /// No description provided for @profilePurpose.
  ///
  /// In pt, this message translates to:
  /// **'Estes dados mantêm o ano fiscal e as simulações coerentes. Valores desconhecidos continuam indisponíveis.'**
  String get profilePurpose;

  /// No description provided for @activeTaxYear.
  ///
  /// In pt, this message translates to:
  /// **'Ano fiscal ativo'**
  String get activeTaxYear;

  /// No description provided for @taxResidence.
  ///
  /// In pt, this message translates to:
  /// **'Residência fiscal'**
  String get taxResidence;

  /// No description provided for @unknownValue.
  ///
  /// In pt, this message translates to:
  /// **'Não indicado'**
  String get unknownValue;

  /// No description provided for @mainlandPortugal.
  ///
  /// In pt, this message translates to:
  /// **'Portugal continental'**
  String get mainlandPortugal;

  /// No description provided for @madeira.
  ///
  /// In pt, this message translates to:
  /// **'Madeira'**
  String get madeira;

  /// No description provided for @azores.
  ///
  /// In pt, this message translates to:
  /// **'Açores'**
  String get azores;

  /// No description provided for @civilStatusLabel.
  ///
  /// In pt, this message translates to:
  /// **'Estado civil'**
  String get civilStatusLabel;

  /// No description provided for @single.
  ///
  /// In pt, this message translates to:
  /// **'Solteiro/a'**
  String get single;

  /// No description provided for @married.
  ///
  /// In pt, this message translates to:
  /// **'Casado/a'**
  String get married;

  /// No description provided for @deFactoUnion.
  ///
  /// In pt, this message translates to:
  /// **'União de facto'**
  String get deFactoUnion;

  /// No description provided for @dependants.
  ///
  /// In pt, this message translates to:
  /// **'Dependentes'**
  String get dependants;

  /// No description provided for @employmentIncome.
  ///
  /// In pt, this message translates to:
  /// **'Rendimentos de trabalho dependente'**
  String get employmentIncome;

  /// No description provided for @selfEmploymentIncome.
  ///
  /// In pt, this message translates to:
  /// **'Rendimentos de trabalho independente'**
  String get selfEmploymentIncome;

  /// No description provided for @yes.
  ///
  /// In pt, this message translates to:
  /// **'Sim'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In pt, this message translates to:
  /// **'Não'**
  String get no;

  /// No description provided for @save.
  ///
  /// In pt, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @localDataUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir os dados guardados neste dispositivo.'**
  String get localDataUnavailable;

  /// No description provided for @income.
  ///
  /// In pt, this message translates to:
  /// **'Rendimentos'**
  String get income;

  /// No description provided for @expenses.
  ///
  /// In pt, this message translates to:
  /// **'Despesas'**
  String get expenses;

  /// No description provided for @addIncome.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar rendimento'**
  String get addIncome;

  /// No description provided for @addExpense.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar despesa'**
  String get addExpense;

  /// No description provided for @totalForYear.
  ///
  /// In pt, this message translates to:
  /// **'Total de {year}'**
  String totalForYear(int year);

  /// No description provided for @localIncomeNotice.
  ///
  /// In pt, this message translates to:
  /// **'Registos apenas locais. Não são importados nem apresentados como dados oficiais.'**
  String get localIncomeNotice;

  /// No description provided for @localExpenseNotice.
  ///
  /// In pt, this message translates to:
  /// **'Os registos locais são informação de apoio e não são tratados automaticamente como deduções de IRS.'**
  String get localExpenseNotice;

  /// No description provided for @noIncomeRegistered.
  ///
  /// In pt, this message translates to:
  /// **'Sem rendimentos registados neste ano'**
  String get noIncomeRegistered;

  /// No description provided for @noExpensesRegistered.
  ///
  /// In pt, this message translates to:
  /// **'Sem despesas registadas neste ano'**
  String get noExpensesRegistered;

  /// No description provided for @amountEuros.
  ///
  /// In pt, this message translates to:
  /// **'Valor em euros'**
  String get amountEuros;

  /// No description provided for @remove.
  ///
  /// In pt, this message translates to:
  /// **'Remover'**
  String get remove;

  /// No description provided for @sourceManual.
  ///
  /// In pt, this message translates to:
  /// **'Introduzido manualmente'**
  String get sourceManual;

  /// No description provided for @sourceImported.
  ///
  /// In pt, this message translates to:
  /// **'Importado'**
  String get sourceImported;

  /// No description provided for @sourceExternal.
  ///
  /// In pt, this message translates to:
  /// **'Fonte externa'**
  String get sourceExternal;

  /// No description provided for @sourceCalculated.
  ///
  /// In pt, this message translates to:
  /// **'Calculado'**
  String get sourceCalculated;

  /// No description provided for @statusConfirmed.
  ///
  /// In pt, this message translates to:
  /// **'Confirmado'**
  String get statusConfirmed;

  /// No description provided for @statusEstimated.
  ///
  /// In pt, this message translates to:
  /// **'Estimado'**
  String get statusEstimated;

  /// No description provided for @statusPossibleDuplicate.
  ///
  /// In pt, this message translates to:
  /// **'Possível duplicado'**
  String get statusPossibleDuplicate;

  /// No description provided for @privacyAndSecurity.
  ///
  /// In pt, this message translates to:
  /// **'Privacidade e segurança'**
  String get privacyAndSecurity;

  /// No description provided for @privacyIntro.
  ///
  /// In pt, this message translates to:
  /// **'A Taxy guarda as simulações e os registos locais neste dispositivo. As credenciais e-Fatura são enviadas por HTTPS apenas para api.taxy.pt durante a ligação e não regressam à interface.'**
  String get privacyIntro;

  /// No description provided for @privacyEfatura.
  ///
  /// In pt, this message translates to:
  /// **'O acesso ao e-Fatura é apenas de leitura. Desligar remove deste dispositivo a capacidade de sessão guardada.'**
  String get privacyEfatura;

  /// No description provided for @diagnostics.
  ///
  /// In pt, this message translates to:
  /// **'Diagnóstico'**
  String get diagnostics;

  /// No description provided for @copyDiagnostics.
  ///
  /// In pt, this message translates to:
  /// **'Copiar informações de diagnóstico'**
  String get copyDiagnostics;

  /// No description provided for @diagnosticsCopied.
  ///
  /// In pt, this message translates to:
  /// **'Informações de diagnóstico copiadas'**
  String get diagnosticsCopied;

  /// No description provided for @diagnosticsNotice.
  ///
  /// In pt, this message translates to:
  /// **'O diagnóstico contém apenas versão e ambiente — nunca NIF, credenciais, tokens ou dados de faturas.'**
  String get diagnosticsNotice;

  /// No description provided for @sendFeedback.
  ///
  /// In pt, this message translates to:
  /// **'Enviar feedback'**
  String get sendFeedback;

  /// No description provided for @feedbackCopied.
  ///
  /// In pt, this message translates to:
  /// **'Foi copiado um modelo seguro de feedback.'**
  String get feedbackCopied;

  /// No description provided for @appearance.
  ///
  /// In pt, this message translates to:
  /// **'Aparência'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In pt, this message translates to:
  /// **'Usar definição do dispositivo'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In pt, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In pt, this message translates to:
  /// **'Escuro'**
  String get themeDark;

  /// No description provided for @profileModuleDescription.
  ///
  /// In pt, this message translates to:
  /// **'Ano ativo e dados fiscais'**
  String get profileModuleDescription;

  /// No description provided for @incomeModuleDescription.
  ///
  /// In pt, this message translates to:
  /// **'Rendimentos locais com origem'**
  String get incomeModuleDescription;

  /// No description provided for @expensesModuleDescription.
  ///
  /// In pt, this message translates to:
  /// **'Despesas locais de apoio'**
  String get expensesModuleDescription;

  /// No description provided for @estimateBasis.
  ///
  /// In pt, this message translates to:
  /// **'O que esta estimativa considera'**
  String get estimateBasis;

  /// No description provided for @incomeConsidered.
  ///
  /// In pt, this message translates to:
  /// **'Rendimentos considerados'**
  String get incomeConsidered;

  /// No description provided for @deductionsConsidered.
  ///
  /// In pt, this message translates to:
  /// **'Deduções consideradas'**
  String get deductionsConsidered;

  /// No description provided for @withholdingConsidered.
  ///
  /// In pt, this message translates to:
  /// **'Retenções consideradas'**
  String get withholdingConsidered;

  /// No description provided for @userEnteredSource.
  ///
  /// In pt, this message translates to:
  /// **'Introduzido por ti'**
  String get userEnteredSource;

  /// No description provided for @estimateNotOfficial.
  ///
  /// In pt, this message translates to:
  /// **'Estimativa baseada na informação introduzida e nas regras suportadas pela Taxy. Não é uma liquidação oficial da AT.'**
  String get estimateNotOfficial;

  /// No description provided for @missingInformationImprove.
  ///
  /// In pt, this message translates to:
  /// **'Falta informação para melhorar esta estimativa.'**
  String get missingInformationImprove;

  /// No description provided for @category.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get category;

  /// No description provided for @categoryEmployment.
  ///
  /// In pt, this message translates to:
  /// **'Trabalho dependente'**
  String get categoryEmployment;

  /// No description provided for @categorySelfEmployment.
  ///
  /// In pt, this message translates to:
  /// **'Trabalho independente'**
  String get categorySelfEmployment;

  /// No description provided for @categoryPension.
  ///
  /// In pt, this message translates to:
  /// **'Pensão'**
  String get categoryPension;

  /// No description provided for @categoryOther.
  ///
  /// In pt, this message translates to:
  /// **'Outra'**
  String get categoryOther;

  /// No description provided for @categoryGeneral.
  ///
  /// In pt, this message translates to:
  /// **'Geral'**
  String get categoryGeneral;

  /// No description provided for @categoryHealth.
  ///
  /// In pt, this message translates to:
  /// **'Saúde'**
  String get categoryHealth;

  /// No description provided for @categoryEducation.
  ///
  /// In pt, this message translates to:
  /// **'Educação'**
  String get categoryEducation;

  /// No description provided for @categoryHousing.
  ///
  /// In pt, this message translates to:
  /// **'Habitação'**
  String get categoryHousing;

  /// No description provided for @categoryProfessional.
  ///
  /// In pt, this message translates to:
  /// **'Atividade profissional'**
  String get categoryProfessional;

  /// No description provided for @edit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @profileChecklist.
  ///
  /// In pt, this message translates to:
  /// **'Checklist fiscal'**
  String get profileChecklist;

  /// No description provided for @completedEssential.
  ///
  /// In pt, this message translates to:
  /// **'{completed} de {total} elementos essenciais preenchidos'**
  String completedEssential(int completed, int total);

  /// No description provided for @checkActiveYear.
  ///
  /// In pt, this message translates to:
  /// **'Ano fiscal ativo'**
  String get checkActiveYear;

  /// No description provided for @checkResidence.
  ///
  /// In pt, this message translates to:
  /// **'Residência fiscal'**
  String get checkResidence;

  /// No description provided for @checkCivilStatus.
  ///
  /// In pt, this message translates to:
  /// **'Estado civil'**
  String get checkCivilStatus;

  /// No description provided for @checkHousehold.
  ///
  /// In pt, this message translates to:
  /// **'Agregado'**
  String get checkHousehold;

  /// No description provided for @checkWorkContext.
  ///
  /// In pt, this message translates to:
  /// **'Situação profissional'**
  String get checkWorkContext;

  /// No description provided for @checkIncome.
  ///
  /// In pt, this message translates to:
  /// **'Rendimentos do ano ativo'**
  String get checkIncome;

  /// No description provided for @impactResidence.
  ///
  /// In pt, this message translates to:
  /// **'A residência determina as regras regionais suportadas aplicáveis.'**
  String get impactResidence;

  /// No description provided for @impactCivilStatus.
  ///
  /// In pt, this message translates to:
  /// **'O estado civil é necessário para escolher um modo de cálculo aplicável.'**
  String get impactCivilStatus;

  /// No description provided for @impactHousehold.
  ///
  /// In pt, this message translates to:
  /// **'O agregado pode afetar deduções e benefícios suportados.'**
  String get impactHousehold;

  /// No description provided for @impactWorkContext.
  ///
  /// In pt, this message translates to:
  /// **'A situação profissional permite saber se o modelo atual suporta os rendimentos.'**
  String get impactWorkContext;

  /// No description provided for @impactIncome.
  ///
  /// In pt, this message translates to:
  /// **'Os rendimentos e retenções são necessários para estimar o saldo final de IRS.'**
  String get impactIncome;

  /// No description provided for @scenarioComparison.
  ///
  /// In pt, this message translates to:
  /// **'Comparar cenários'**
  String get scenarioComparison;

  /// No description provided for @scenarioIntro.
  ///
  /// In pt, this message translates to:
  /// **'Testa alterações hipotéticas sem mudar a informação base.'**
  String get scenarioIntro;

  /// No description provided for @currentScenario.
  ///
  /// In pt, this message translates to:
  /// **'Cenário atual'**
  String get currentScenario;

  /// No description provided for @alternativeScenario.
  ///
  /// In pt, this message translates to:
  /// **'Cenário alternativo'**
  String get alternativeScenario;

  /// No description provided for @resultDifference.
  ///
  /// In pt, this message translates to:
  /// **'Diferença no resultado'**
  String get resultDifference;

  /// No description provided for @whatChanged.
  ///
  /// In pt, this message translates to:
  /// **'O que mudou'**
  String get whatChanged;

  /// No description provided for @noScenarioChanges.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não existem alterações hipotéticas.'**
  String get noScenarioChanges;

  /// No description provided for @scenarioOverrideNotice.
  ///
  /// In pt, this message translates to:
  /// **'Os valores alternativos são hipóteses do cenário, não dados confirmados do perfil.'**
  String get scenarioOverrideNotice;

  /// No description provided for @savedEstimates.
  ///
  /// In pt, this message translates to:
  /// **'Estimativas guardadas'**
  String get savedEstimates;

  /// No description provided for @saveEstimate.
  ///
  /// In pt, this message translates to:
  /// **'Guardar estimativa'**
  String get saveEstimate;

  /// No description provided for @estimateSaved.
  ///
  /// In pt, this message translates to:
  /// **'Estimativa guardada neste dispositivo.'**
  String get estimateSaved;

  /// No description provided for @savedEstimate.
  ///
  /// In pt, this message translates to:
  /// **'Estimativa guardada'**
  String get savedEstimate;

  /// No description provided for @noSavedEstimates.
  ///
  /// In pt, this message translates to:
  /// **'Sem estimativas guardadas'**
  String get noSavedEstimates;

  /// No description provided for @deleteSavedEstimate.
  ///
  /// In pt, this message translates to:
  /// **'Apagar estimativa guardada'**
  String get deleteSavedEstimate;

  /// No description provided for @duplicateAsScenario.
  ///
  /// In pt, this message translates to:
  /// **'Duplicar como cenário'**
  String get duplicateAsScenario;

  /// No description provided for @invoiceExplorer.
  ///
  /// In pt, this message translates to:
  /// **'Explorador de faturas'**
  String get invoiceExplorer;

  /// No description provided for @searchInvoices.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar emitente'**
  String get searchInvoices;

  /// No description provided for @documentTotal.
  ///
  /// In pt, this message translates to:
  /// **'Total dos documentos'**
  String get documentTotal;

  /// No description provided for @monthlySummary.
  ///
  /// In pt, this message translates to:
  /// **'Resumo mensal'**
  String get monthlySummary;

  /// No description provided for @averageDocument.
  ///
  /// In pt, this message translates to:
  /// **'Média por documento'**
  String get averageDocument;

  /// No description provided for @sortNewest.
  ///
  /// In pt, this message translates to:
  /// **'Mais recentes'**
  String get sortNewest;

  /// No description provided for @sortOldest.
  ///
  /// In pt, this message translates to:
  /// **'Mais antigas'**
  String get sortOldest;

  /// No description provided for @sortHighest.
  ///
  /// In pt, this message translates to:
  /// **'Maior valor'**
  String get sortHighest;

  /// No description provided for @sortLowest.
  ///
  /// In pt, this message translates to:
  /// **'Menor valor'**
  String get sortLowest;

  /// No description provided for @sortIssuer.
  ///
  /// In pt, this message translates to:
  /// **'Nome do emitente'**
  String get sortIssuer;

  /// No description provided for @filteredInvoiceCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Sem faturas correspondentes} =1{1 fatura correspondente} other{{count} faturas correspondentes}}'**
  String filteredInvoiceCount(int count);

  /// No description provided for @lastUpdatedThisSession.
  ///
  /// In pt, this message translates to:
  /// **'Última atualização nesta sessão: {time}'**
  String lastUpdatedThisSession(String time);

  /// No description provided for @offlineUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Esta área precisa de ligação. Verifica a rede e tenta novamente.'**
  String get offlineUnavailable;

  /// No description provided for @tryAgain.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get tryAgain;

  /// No description provided for @dateFilter.
  ///
  /// In pt, this message translates to:
  /// **'Intervalo de datas'**
  String get dateFilter;

  /// No description provided for @minimumAmount.
  ///
  /// In pt, this message translates to:
  /// **'Valor mínimo'**
  String get minimumAmount;

  /// No description provided for @maximumAmount.
  ///
  /// In pt, this message translates to:
  /// **'Valor máximo'**
  String get maximumAmount;

  /// No description provided for @privacySnapshots.
  ///
  /// In pt, this message translates to:
  /// **'As estimativas IRS guardadas ficam apenas neste dispositivo. Contêm inputs e resultados normalizados, nunca credenciais ou respostas e-Fatura em bruto.'**
  String get privacySnapshots;

  /// No description provided for @all.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get all;

  /// No description provided for @dashboardTitle.
  ///
  /// In pt, this message translates to:
  /// **'O teu IRS, num relance'**
  String get dashboardTitle;

  /// No description provided for @simulationUpdatedForYear.
  ///
  /// In pt, this message translates to:
  /// **'Simulação atualizada com as regras de {year}.'**
  String simulationUpdatedForYear(int year);

  /// No description provided for @resumeDraft.
  ///
  /// In pt, this message translates to:
  /// **'Retomar simulação em curso'**
  String get resumeDraft;

  /// No description provided for @viewCalculation.
  ///
  /// In pt, this message translates to:
  /// **'Ver cálculo'**
  String get viewCalculation;

  /// No description provided for @change.
  ///
  /// In pt, this message translates to:
  /// **'Alterar'**
  String get change;

  /// No description provided for @compare.
  ///
  /// In pt, this message translates to:
  /// **'Comparar'**
  String get compare;

  /// No description provided for @exploreTaxOpportunities.
  ///
  /// In pt, this message translates to:
  /// **'Explorar oportunidades fiscais'**
  String get exploreTaxOpportunities;

  /// No description provided for @readOnlyExperimental.
  ///
  /// In pt, this message translates to:
  /// **'Consulta experimental apenas de leitura'**
  String get readOnlyExperimental;

  /// No description provided for @yourSimulations.
  ///
  /// In pt, this message translates to:
  /// **'As tuas simulações'**
  String get yourSimulations;

  /// No description provided for @savedSimulationCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Nenhuma guardada neste dispositivo} =1{1 guardada neste dispositivo} other{{count} guardadas neste dispositivo}}'**
  String savedSimulationCount(int count);

  /// No description provided for @newSimulation.
  ///
  /// In pt, this message translates to:
  /// **'Nova'**
  String get newSimulation;

  /// No description provided for @refundAmount.
  ///
  /// In pt, this message translates to:
  /// **'Reembolso {amount}'**
  String refundAmount(String amount);

  /// No description provided for @taxDueAmount.
  ///
  /// In pt, this message translates to:
  /// **'A pagar {amount}'**
  String taxDueAmount(String amount);

  /// No description provided for @calculationUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Cálculo indisponível'**
  String get calculationUnavailable;

  /// No description provided for @options.
  ///
  /// In pt, this message translates to:
  /// **'Opções'**
  String get options;

  /// No description provided for @rename.
  ///
  /// In pt, this message translates to:
  /// **'Renomear'**
  String get rename;

  /// No description provided for @duplicate.
  ///
  /// In pt, this message translates to:
  /// **'Duplicar'**
  String get duplicate;

  /// No description provided for @changeData.
  ///
  /// In pt, this message translates to:
  /// **'Alterar dados'**
  String get changeData;

  /// No description provided for @delete.
  ///
  /// In pt, this message translates to:
  /// **'Apagar'**
  String get delete;

  /// No description provided for @renameSimulation.
  ///
  /// In pt, this message translates to:
  /// **'Renomear simulação'**
  String get renameSimulation;

  /// No description provided for @name.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get name;

  /// No description provided for @copySimulationName.
  ///
  /// In pt, this message translates to:
  /// **'{name} — cópia'**
  String copySimulationName(String name);

  /// No description provided for @deleteSimulationTitle.
  ///
  /// In pt, this message translates to:
  /// **'Apagar esta simulação?'**
  String get deleteSimulationTitle;

  /// No description provided for @deleteSimulationMessage.
  ///
  /// In pt, this message translates to:
  /// **'“{name}” será removida apenas deste dispositivo.'**
  String deleteSimulationMessage(String name);

  /// No description provided for @estimatedRefund.
  ///
  /// In pt, this message translates to:
  /// **'Reembolso estimado'**
  String get estimatedRefund;

  /// No description provided for @estimatedAdditionalTax.
  ///
  /// In pt, this message translates to:
  /// **'Imposto adicional estimado'**
  String get estimatedAdditionalTax;

  /// No description provided for @estimateUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Estimativa indisponível'**
  String get estimateUnavailable;

  /// No description provided for @openDetails.
  ///
  /// In pt, this message translates to:
  /// **'Abrir detalhe'**
  String get openDetails;

  /// No description provided for @transparencyFirst.
  ///
  /// In pt, this message translates to:
  /// **'Transparência primeiro'**
  String get transparencyFirst;

  /// No description provided for @calculationMethodIntro.
  ///
  /// In pt, this message translates to:
  /// **'O cálculo é determinístico e não usa inteligência artificial. Valores monetários são tratados em cêntimos inteiros, com arredondamento explícito.'**
  String get calculationMethodIntro;

  /// No description provided for @netCategoryIncome.
  ///
  /// In pt, this message translates to:
  /// **'Rendimento líquido da categoria'**
  String get netCategoryIncome;

  /// No description provided for @netCategoryIncomeExplanation.
  ///
  /// In pt, this message translates to:
  /// **'Ao rendimento bruto subtraímos a dedução específica aplicável ao trabalho dependente.'**
  String get netCategoryIncomeExplanation;

  /// No description provided for @minimumExistence.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo de existência'**
  String get minimumExistence;

  /// No description provided for @minimumExistenceExplanation.
  ///
  /// In pt, this message translates to:
  /// **'Quando aplicável, calculamos o abatimento previsto no artigo 70.º do Código do IRS.'**
  String get minimumExistenceExplanation;

  /// No description provided for @progressiveBrackets.
  ///
  /// In pt, this message translates to:
  /// **'Escalões progressivos'**
  String get progressiveBrackets;

  /// No description provided for @progressiveBracketsExplanation.
  ///
  /// In pt, this message translates to:
  /// **'Aplicamos as taxas gerais de {year} ao rendimento coletável.'**
  String progressiveBracketsExplanation(int year);

  /// No description provided for @deductionsAndWithholding.
  ///
  /// In pt, this message translates to:
  /// **'Deduções e retenções'**
  String get deductionsAndWithholding;

  /// No description provided for @deductionsAndWithholdingExplanation.
  ///
  /// In pt, this message translates to:
  /// **'Aplicamos limites por categoria e o limite conjunto. Por fim, descontamos o IRS já retido.'**
  String get deductionsAndWithholdingExplanation;

  /// No description provided for @validatedScope.
  ///
  /// In pt, this message translates to:
  /// **'Âmbito validado'**
  String get validatedScope;

  /// No description provided for @unsupportedScope.
  ///
  /// In pt, this message translates to:
  /// **'Não suportado / por verificar'**
  String get unsupportedScope;

  /// No description provided for @openValidationLab.
  ///
  /// In pt, this message translates to:
  /// **'Abrir laboratório de validação fiscal'**
  String get openValidationLab;

  /// No description provided for @validatedResidentScope.
  ///
  /// In pt, this message translates to:
  /// **'Residente durante todo o ano · {jurisdiction}.'**
  String validatedResidentScope(String jurisdiction);

  /// No description provided for @categoryAOnlyScope.
  ///
  /// In pt, this message translates to:
  /// **'Rendimentos exclusivamente da Categoria A.'**
  String get categoryAOnlyScope;

  /// No description provided for @standardHouseholdScope.
  ///
  /// In pt, this message translates to:
  /// **'Individual, família monoparental, casamento ou união de facto standard.'**
  String get standardHouseholdScope;

  /// No description provided for @couplesComparisonScope.
  ///
  /// In pt, this message translates to:
  /// **'Nos casais, calculamos separada e conjunta e mostramos a diferença.'**
  String get couplesComparisonScope;

  /// No description provided for @standardDependantsScope.
  ///
  /// In pt, this message translates to:
  /// **'Dependentes standard, sem guarda partilhada, residência alternada ou alocação especial.'**
  String get standardDependantsScope;

  /// No description provided for @standardEducationScope.
  ///
  /// In pt, this message translates to:
  /// **'Educação standard, sem estudante deslocado ou majorações territoriais.'**
  String get standardEducationScope;

  /// No description provided for @verifiedRulesScope.
  ///
  /// In pt, this message translates to:
  /// **'Regras {version}, verificadas em {date}.'**
  String verifiedRulesScope(String version, String date);

  /// No description provided for @regional2025Unsupported.
  ///
  /// In pt, this message translates to:
  /// **'Madeira e Açores em 2025.'**
  String get regional2025Unsupported;

  /// No description provided for @partialResidenceUnsupported.
  ///
  /// In pt, this message translates to:
  /// **'Residência parcial ou não residência.'**
  String get partialResidenceUnsupported;

  /// No description provided for @incomeTypesUnsupported.
  ///
  /// In pt, this message translates to:
  /// **'Liquidação IRS Jovem, Categoria B e pensões.'**
  String get incomeTypesUnsupported;

  /// No description provided for @foreignIncomeUnsupported.
  ///
  /// In pt, this message translates to:
  /// **'Rendimentos estrangeiros, de capitais, prediais e mais-valias.'**
  String get foreignIncomeUnsupported;

  /// No description provided for @specialSituationsUnsupported.
  ///
  /// In pt, this message translates to:
  /// **'Deficiência, estudante deslocado, guarda partilhada e outras situações especiais.'**
  String get specialSituationsUnsupported;

  /// No description provided for @guidedTaxTitle.
  ///
  /// In pt, this message translates to:
  /// **'A tua análise fiscal guiada'**
  String get guidedTaxTitle;

  /// No description provided for @guidedTaxIntro.
  ///
  /// In pt, this message translates to:
  /// **'Responde a uma pergunta simples de cada vez. A Taxy organiza as respostas no teu perfil fiscal.'**
  String get guidedTaxIntro;

  /// No description provided for @guidedTaxStart.
  ///
  /// In pt, this message translates to:
  /// **'Começar análise guiada'**
  String get guidedTaxStart;

  /// No description provided for @guidedTaxContinue.
  ///
  /// In pt, this message translates to:
  /// **'Continuar análise fiscal'**
  String get guidedTaxContinue;

  /// No description provided for @guidedTaxResume.
  ///
  /// In pt, this message translates to:
  /// **'Continuar de onde ficaste'**
  String get guidedTaxResume;

  /// No description provided for @guidedTaxYear.
  ///
  /// In pt, this message translates to:
  /// **'Ano fiscal {year}'**
  String guidedTaxYear(int year);

  /// No description provided for @guidedTaxProgress.
  ///
  /// In pt, this message translates to:
  /// **'{completed} de {total} áreas revistas'**
  String guidedTaxProgress(int completed, int total);

  /// No description provided for @guidedTaxWhy.
  ///
  /// In pt, this message translates to:
  /// **'Porque perguntamos isto'**
  String get guidedTaxWhy;

  /// No description provided for @guidedTaxBack.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get guidedTaxBack;

  /// No description provided for @guidedTaxNext.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get guidedTaxNext;

  /// No description provided for @guidedTaxReviewAnswers.
  ///
  /// In pt, this message translates to:
  /// **'Rever as tuas respostas'**
  String get guidedTaxReviewAnswers;

  /// No description provided for @guidedTaxEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get guidedTaxEdit;

  /// No description provided for @guidedTaxFinish.
  ///
  /// In pt, this message translates to:
  /// **'Ver estimativa'**
  String get guidedTaxFinish;

  /// No description provided for @guidedTaxEstimate.
  ///
  /// In pt, this message translates to:
  /// **'Estimativa de IRS'**
  String get guidedTaxEstimate;

  /// No description provided for @guidedTaxProvisionalEstimate.
  ///
  /// In pt, this message translates to:
  /// **'Estimativa provisória de IRS'**
  String get guidedTaxProvisionalEstimate;

  /// No description provided for @guidedTaxEstimateGood.
  ///
  /// In pt, this message translates to:
  /// **'Estimativa com boa qualidade'**
  String get guidedTaxEstimateGood;

  /// No description provided for @guidedTaxEstimateIncomplete.
  ///
  /// In pt, this message translates to:
  /// **'Ainda faltam alguns dados'**
  String get guidedTaxEstimateIncomplete;

  /// No description provided for @guidedTaxHowResult.
  ///
  /// In pt, this message translates to:
  /// **'Como chegámos a este valor'**
  String get guidedTaxHowResult;

  /// No description provided for @guidedTaxIncome.
  ///
  /// In pt, this message translates to:
  /// **'Rendimentos'**
  String get guidedTaxIncome;

  /// No description provided for @guidedTaxWithholding.
  ///
  /// In pt, this message translates to:
  /// **'Retenções'**
  String get guidedTaxWithholding;

  /// No description provided for @guidedTaxDeductions.
  ///
  /// In pt, this message translates to:
  /// **'Deduções consideradas'**
  String get guidedTaxDeductions;

  /// No description provided for @guidedTaxResult.
  ///
  /// In pt, this message translates to:
  /// **'Resultado estimado'**
  String get guidedTaxResult;

  /// No description provided for @guidedTaxNextAction.
  ///
  /// In pt, this message translates to:
  /// **'O que fazer a seguir'**
  String get guidedTaxNextAction;

  /// No description provided for @guidedTaxUnsupported.
  ///
  /// In pt, this message translates to:
  /// **'Registámos esta situação, mas o motor fiscal atual ainda não a consegue calcular com segurança.'**
  String get guidedTaxUnsupported;

  /// No description provided for @guidedTaxSaved.
  ///
  /// In pt, this message translates to:
  /// **'O teu progresso fica guardado neste dispositivo.'**
  String get guidedTaxSaved;

  /// No description provided for @guidedTaxMissingRequired.
  ///
  /// In pt, this message translates to:
  /// **'Necessário antes de calcular'**
  String get guidedTaxMissingRequired;

  /// No description provided for @guidedTaxMissingRecommended.
  ///
  /// In pt, this message translates to:
  /// **'Recomendado para melhorar a estimativa'**
  String get guidedTaxMissingRecommended;

  /// No description provided for @guidedTaxNoAnswer.
  ///
  /// In pt, this message translates to:
  /// **'Sem resposta'**
  String get guidedTaxNoAnswer;

  /// No description provided for @guidedTaxYes.
  ///
  /// In pt, this message translates to:
  /// **'Sim'**
  String get guidedTaxYes;

  /// No description provided for @guidedTaxNo.
  ///
  /// In pt, this message translates to:
  /// **'Não'**
  String get guidedTaxNo;

  /// No description provided for @guidedTaxInvalidNumber.
  ///
  /// In pt, this message translates to:
  /// **'Introduz um valor válido.'**
  String get guidedTaxInvalidNumber;

  /// No description provided for @guidedTaxHomeReady.
  ///
  /// In pt, this message translates to:
  /// **'A tua estimativa está pronta'**
  String get guidedTaxHomeReady;

  /// No description provided for @guidedTaxHomeAreas.
  ///
  /// In pt, this message translates to:
  /// **'Faltam rever {count} áreas'**
  String guidedTaxHomeAreas(int count);

  /// No description provided for @guidedTaxFoundEfatura.
  ///
  /// In pt, this message translates to:
  /// **'Encontrámos informação no e-Fatura.'**
  String get guidedTaxFoundEfatura;

  /// No description provided for @guidedTaxPendingEfatura.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{Existe 1 fatura por validar} other{Existem {count} faturas por validar}}'**
  String guidedTaxPendingEfatura(int count);

  /// No description provided for @aboutYou.
  ///
  /// In pt, this message translates to:
  /// **'Sobre ti'**
  String get aboutYou;

  /// No description provided for @family.
  ///
  /// In pt, this message translates to:
  /// **'Família'**
  String get family;

  /// No description provided for @workAndIncome.
  ///
  /// In pt, this message translates to:
  /// **'Trabalho e rendimentos'**
  String get workAndIncome;

  /// No description provided for @otherIncome.
  ///
  /// In pt, this message translates to:
  /// **'Outros rendimentos'**
  String get otherIncome;

  /// No description provided for @withholdingAndPayments.
  ///
  /// In pt, this message translates to:
  /// **'Retenções e pagamentos'**
  String get withholdingAndPayments;

  /// No description provided for @review.
  ///
  /// In pt, this message translates to:
  /// **'Revisão'**
  String get review;

  /// No description provided for @qResidentPortugal.
  ///
  /// In pt, this message translates to:
  /// **'Foste residente fiscal em Portugal durante todo o ano de {year}?'**
  String qResidentPortugal(int year);

  /// No description provided for @whyResidentPortugal.
  ///
  /// In pt, this message translates to:
  /// **'O motor atual da Taxy suporta residentes fiscais em Portugal durante todo o ano.'**
  String get whyResidentPortugal;

  /// No description provided for @qRegion.
  ///
  /// In pt, this message translates to:
  /// **'Onde tiveste residência fiscal?'**
  String get qRegion;

  /// No description provided for @whyRegion.
  ///
  /// In pt, this message translates to:
  /// **'Continente, Madeira e Açores podem aplicar regras fiscais diferentes.'**
  String get whyRegion;

  /// No description provided for @qAge.
  ///
  /// In pt, this message translates to:
  /// **'Que idade tinhas no final de {year}?'**
  String qAge(int year);

  /// No description provided for @whyAge.
  ///
  /// In pt, this message translates to:
  /// **'A idade pode influenciar algumas deduções e benefícios.'**
  String get whyAge;

  /// No description provided for @qCivilStatus.
  ///
  /// In pt, this message translates to:
  /// **'Qual era a tua situação familiar no final de {year}?'**
  String qCivilStatus(int year);

  /// No description provided for @whyCivilStatus.
  ///
  /// In pt, this message translates to:
  /// **'Os casais podem comparar tributação conjunta e separada.'**
  String get whyCivilStatus;

  /// No description provided for @qJointTaxation.
  ///
  /// In pt, this message translates to:
  /// **'Queres ver primeiro a tributação conjunta?'**
  String get qJointTaxation;

  /// No description provided for @whyJointTaxation.
  ///
  /// In pt, this message translates to:
  /// **'A Taxy pode comparar tributação conjunta e separada sem alterar a tua opção oficial.'**
  String get whyJointTaxation;

  /// No description provided for @qDependents.
  ///
  /// In pt, this message translates to:
  /// **'Quantos dependentes faziam parte do teu agregado?'**
  String get qDependents;

  /// No description provided for @whyDependents.
  ///
  /// In pt, this message translates to:
  /// **'Os dependentes podem influenciar as deduções do agregado.'**
  String get whyDependents;

  /// No description provided for @qEmployment.
  ///
  /// In pt, this message translates to:
  /// **'Trabalhaste por conta de outrem em {year}?'**
  String qEmployment(int year);

  /// No description provided for @whyEmployment.
  ///
  /// In pt, this message translates to:
  /// **'Assim só perguntamos pelos rendimentos que se aplicam ao teu caso.'**
  String get whyEmployment;

  /// No description provided for @qEmploymentGross.
  ///
  /// In pt, this message translates to:
  /// **'Qual foi o teu rendimento bruto total do trabalho?'**
  String get qEmploymentGross;

  /// No description provided for @whyEmploymentGross.
  ///
  /// In pt, this message translates to:
  /// **'Usa o valor anual antes de IRS e Segurança Social.'**
  String get whyEmploymentGross;

  /// No description provided for @qSelfEmployment.
  ///
  /// In pt, this message translates to:
  /// **'Também trabalhaste por conta própria?'**
  String get qSelfEmployment;

  /// No description provided for @whySelfEmployment.
  ///
  /// In pt, this message translates to:
  /// **'O trabalho independente fica identificado separadamente porque tem tratamento fiscal diferente.'**
  String get whySelfEmployment;

  /// No description provided for @qPension.
  ///
  /// In pt, this message translates to:
  /// **'Recebeste alguma pensão?'**
  String get qPension;

  /// No description provided for @whyPension.
  ///
  /// In pt, this message translates to:
  /// **'As pensões têm tratamento fiscal próprio.'**
  String get whyPension;

  /// No description provided for @qForeignIncome.
  ///
  /// In pt, this message translates to:
  /// **'Recebeste rendimentos fora de Portugal?'**
  String get qForeignIncome;

  /// No description provided for @whyForeignIncome.
  ///
  /// In pt, this message translates to:
  /// **'Identificamos rendimentos estrangeiros sem aproximar cálculos ainda não suportados.'**
  String get whyForeignIncome;

  /// No description provided for @qRentalIncome.
  ///
  /// In pt, this message translates to:
  /// **'Recebeste rendas de imóveis?'**
  String get qRentalIncome;

  /// No description provided for @whyRentalIncome.
  ///
  /// In pt, this message translates to:
  /// **'Os rendimentos prediais têm tratamento separado na declaração portuguesa.'**
  String get whyRentalIncome;

  /// No description provided for @qExpensesReviewed.
  ///
  /// In pt, this message translates to:
  /// **'Já reveste as tuas despesas e a informação do e-Fatura?'**
  String get qExpensesReviewed;

  /// No description provided for @whyExpensesReviewed.
  ///
  /// In pt, this message translates to:
  /// **'Despesas completas podem melhorar a estimativa. Totais oficiais indisponíveis nunca são tratados como zero.'**
  String get whyExpensesReviewed;

  /// No description provided for @qWithholding.
  ///
  /// In pt, this message translates to:
  /// **'Quanto te foi retido em IRS durante o ano?'**
  String get qWithholding;

  /// No description provided for @whyWithholding.
  ///
  /// In pt, this message translates to:
  /// **'As retenções são imposto já pago e permitem estimar o saldo final.'**
  String get whyWithholding;

  /// No description provided for @qSocialSecurity.
  ///
  /// In pt, this message translates to:
  /// **'Quanto pagaste em contribuições obrigatórias para a Segurança Social?'**
  String get qSocialSecurity;

  /// No description provided for @whySocialSecurity.
  ///
  /// In pt, this message translates to:
  /// **'As contribuições obrigatórias podem reduzir o rendimento tributável do trabalho.'**
  String get whySocialSecurity;

  /// No description provided for @qReview.
  ///
  /// In pt, this message translates to:
  /// **'Estas respostas estão prontas para calcular?'**
  String get qReview;

  /// No description provided for @whyReview.
  ///
  /// In pt, this message translates to:
  /// **'Podes voltar atrás e editar qualquer resposta. Respostas dependentes deixam de contar quando já não se aplicam.'**
  String get whyReview;

  /// No description provided for @guidedTaxNotCalculation.
  ///
  /// In pt, this message translates to:
  /// **'Esta situação ficou guardada, mas não mostramos estimativa porque o motor atual ainda não a suporta com segurança.'**
  String get guidedTaxNotCalculation;

  /// No description provided for @guidedTaxDocumentsFoundation.
  ///
  /// In pt, this message translates to:
  /// **'Documentos de apoio'**
  String get guidedTaxDocumentsFoundation;

  /// No description provided for @guidedTaxDocumentsHint.
  ///
  /// In pt, this message translates to:
  /// **'A captura de documentos fica preparada para futuras importações confirmadas; nenhum valor é aplicado sem a tua confirmação.'**
  String get guidedTaxDocumentsHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'PT':
            return AppLocalizationsPtPt();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
