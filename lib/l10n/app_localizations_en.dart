// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'taxy.pt';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageDescription => 'Choose the app language.';

  @override
  String get languageAutomatic => 'Automatic';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSystemHint =>
      'Follows your phone language. Other languages use Portuguese.';

  @override
  String get back => 'Back';

  @override
  String get experimental => 'Experimental';

  @override
  String get efaturaTitle => 'e-Fatura';

  @override
  String get efaturaHeroTitle => 'Your expenses, available to view';

  @override
  String get efaturaCredentialNotice =>
      'Your credentials are used only to consult e-Fatura.';

  @override
  String get connectPortalTitle => 'Connect to e-Fatura';

  @override
  String get nif => 'NIF';

  @override
  String get password => 'Password';

  @override
  String get connectEfatura => 'Connect to e-Fatura';

  @override
  String get disconnectEfatura => 'Disconnect e-Fatura';

  @override
  String get disconnectTitle => 'Disconnect e-Fatura?';

  @override
  String get disconnectExplanation =>
      'This removes the credentials saved on this device.';

  @override
  String get cancel => 'Cancel';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get selectDeviceCertificate => 'Select device certificate';

  @override
  String get selectAtPublicKey => 'Select the AT public key';

  @override
  String get refresh => 'Refresh';

  @override
  String get retry => 'Try again';

  @override
  String get overviewTitle => 'e-Fatura overview';

  @override
  String get provisionalTaxBenefit => 'Provisional tax benefit';

  @override
  String get invoicesToValidate => 'Invoices awaiting information';

  @override
  String get invoicesToAssociate => 'Invoices to associate with income';

  @override
  String get expensesByCategory => 'Expenses by category';

  @override
  String get sectors => 'Categories';

  @override
  String get pendingInvoicesTitle => 'Pending invoices';

  @override
  String get sectorInvoicesTitle => 'Invoices in this category';

  @override
  String get viewPendingInvoices => 'View invoices to validate';

  @override
  String get noInvoicesToValidate => 'No pending invoices';

  @override
  String get noInvoicesInCategory => 'No invoices in this category';

  @override
  String get noActivityInCategory => 'No activity in this category';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get partialEfaturaData =>
      'Some e-Fatura values are unavailable. Loaded invoices remain accessible.';

  @override
  String get benefitUnavailable => 'Benefit unavailable';

  @override
  String get readOnlyNoValidation =>
      'Taxy shows this count for information only. Invoice validation remains available in the official e-Fatura app.';

  @override
  String get irsPredictionDataTitle => 'Data for your IRS estimate';

  @override
  String get officialProvisionalBenefit => 'Provisional benefit reported by AT';

  @override
  String get listedExpenses => 'Listed expenses';

  @override
  String get listedVat => 'VAT on listed expenses';

  @override
  String get irsPredictionDisclaimer =>
      'This data helps prepare the estimate. On its own, it is not your final IRS refund or tax due.';

  @override
  String get issuerUnavailable => 'Issuer unavailable';

  @override
  String invoiceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invoices',
      one: '1 invoice',
      zero: 'No invoices',
    );
    return '$_temp0';
  }

  @override
  String get authErrorTitle => 'We couldn\'t authenticate';

  @override
  String get authErrorMessage =>
      'We couldn\'t authenticate with Portal das Finanças.';

  @override
  String get authorizationErrorTitle => 'Access not authorized';

  @override
  String get authorizationErrorMessage =>
      'Portal das Finanças did not authorize this request.';

  @override
  String get networkErrorTitle => 'Connection error';

  @override
  String get networkErrorMessage => 'We couldn\'t establish a connection.';

  @override
  String get serviceErrorTitle => 'Service unavailable';

  @override
  String get serviceErrorMessage => 'e-Fatura is currently unavailable.';

  @override
  String get parsingErrorTitle => 'Unexpected response';

  @override
  String get parsingErrorMessage =>
      'We received an unexpected response from e-Fatura.';

  @override
  String get sessionExpiredTitle => 'Session expired';

  @override
  String get sessionExpiredMessage => 'Reconnect to e-Fatura to continue.';

  @override
  String get notConfiguredTitle => 'Connection not set up yet';

  @override
  String get genericErrorTitle => 'We couldn\'t refresh';

  @override
  String get genericErrorMessage => 'We couldn\'t connect to e-Fatura.';

  @override
  String get connecting => 'Connecting to e-Fatura…';

  @override
  String get updating => 'Refreshing…';

  @override
  String get connected => 'Connected';

  @override
  String get welcomeTagline => 'IRS, explained for people';

  @override
  String get welcomeTitle => 'Understand your IRS.\nDecide with confidence.';

  @override
  String get welcomeBody =>
      'A simple conversation turns your details into a clear estimate — without forms or tax jargon.';

  @override
  String get startSimulation => 'Start simulation';

  @override
  String get resumeSimulation => 'Resume simulation';

  @override
  String get howWeCalculate => 'See how we calculate';

  @override
  String get dataOnDevice => 'Data stays on this device';

  @override
  String rulesVerified(int year) {
    return '$year rules verified';
  }

  @override
  String get simulators => 'Calculators';

  @override
  String get available => 'Available';

  @override
  String get efaturaModuleDescription => 'Read-only access · internal feature';

  @override
  String get futureSimulators => 'More calculators · Coming soon';

  @override
  String futureSimulatorsSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count future calculators in preparation',
      one: '1 future calculator in preparation',
    );
    return '$_temp0';
  }

  @override
  String get privateLabel => 'Private';

  @override
  String get efaturaSemantics => 'Experimental e-Fatura, view only';

  @override
  String get sectorCarRepairs => 'Car repairs';

  @override
  String get sectorMotorcycleRepairs => 'Motorcycle repairs';

  @override
  String get sectorHospitality => 'Hospitality and restaurants';

  @override
  String get sectorHairdressing => 'Hairdressing';

  @override
  String get sectorHealth => 'Health';

  @override
  String get sectorEducation => 'Education';

  @override
  String get sectorHousing => 'Housing';

  @override
  String get sectorNursingHomes => 'Nursing homes';

  @override
  String get sectorVeterinary => 'Veterinary care';

  @override
  String get sectorPublicTransport => 'Public transport';

  @override
  String get sectorGyms => 'Gyms';

  @override
  String get sectorNewspapers => 'Newspapers and magazines';

  @override
  String get sectorDomesticServices => 'Domestic services';

  @override
  String get sectorOther => 'Other expenses';

  @override
  String get invalidNif => 'Enter a 9-digit NIF.';

  @override
  String get passwordRequired => 'Enter your password.';

  @override
  String get rulesLoadError =>
      'We couldn\'t load the tax rules securely. Close and reopen the app.';

  @override
  String get savedDataLoadError =>
      'We couldn\'t open the data saved on this device.';

  @override
  String get simulationsLoadError =>
      'We couldn\'t open the simulations saved on this device.';

  @override
  String get simulationRulesLoadError =>
      'We couldn\'t load the rules for this simulation securely.';
}
