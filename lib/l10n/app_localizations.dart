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
  /// **'Isto remove as credenciais guardadas neste dispositivo.'**
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
  /// **'Faturas por validar'**
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
  /// **'Faturas por validar'**
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
  /// **'Sem faturas por validar'**
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

  /// No description provided for @benefitUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Benefício não disponível'**
  String get benefitUnavailable;

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
