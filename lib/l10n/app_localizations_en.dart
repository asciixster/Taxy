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
      'This ends the session saved on this device.';

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
  String get operationUnavailableTitle => 'Request unavailable';

  @override
  String get operationUnavailableMessage =>
      'This request is not available yet.';

  @override
  String get rateLimitedTitle => 'Too many requests';

  @override
  String get rateLimitedMessage => 'Wait a moment before trying again.';

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

  @override
  String get internalBetaBuild => 'Internal beta build';

  @override
  String get appVersion => 'Version';

  @override
  String get gitRevision => 'Revision';

  @override
  String get environment => 'Environment';

  @override
  String get apiHost => 'API host';

  @override
  String get fiscalProfile => 'Tax profile';

  @override
  String get profileComplete => 'Profile complete';

  @override
  String get profileIncomplete => 'Profile incomplete';

  @override
  String get profilePurpose =>
      'These details keep the active tax year and your simulations consistent. Unknown values stay unavailable.';

  @override
  String get activeTaxYear => 'Active tax year';

  @override
  String get taxResidence => 'Tax residence';

  @override
  String get unknownValue => 'Not provided';

  @override
  String get mainlandPortugal => 'Mainland Portugal';

  @override
  String get madeira => 'Madeira';

  @override
  String get azores => 'Azores';

  @override
  String get civilStatusLabel => 'Civil status';

  @override
  String get single => 'Single';

  @override
  String get married => 'Married';

  @override
  String get deFactoUnion => 'De facto partnership';

  @override
  String get dependants => 'Dependants';

  @override
  String get employmentIncome => 'Employment income';

  @override
  String get selfEmploymentIncome => 'Self-employment income';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get save => 'Save';

  @override
  String get localDataUnavailable =>
      'We couldn\'t open the data saved on this device.';

  @override
  String get income => 'Income';

  @override
  String get expenses => 'Expenses';

  @override
  String get addIncome => 'Add income';

  @override
  String get addExpense => 'Add expense';

  @override
  String totalForYear(int year) {
    return 'Total for $year';
  }

  @override
  String get localIncomeNotice =>
      'Local entries only. They are not imported or reported as official data.';

  @override
  String get localExpenseNotice =>
      'Local entries are supporting information and are not automatically treated as IRS deductions.';

  @override
  String get noIncomeRegistered => 'No income recorded for this year';

  @override
  String get noExpensesRegistered => 'No expenses recorded for this year';

  @override
  String get amountEuros => 'Amount in euros';

  @override
  String get remove => 'Remove';

  @override
  String get sourceManual => 'Entered manually';

  @override
  String get sourceImported => 'Imported';

  @override
  String get sourceExternal => 'External source';

  @override
  String get sourceCalculated => 'Calculated by Taxy';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusEstimated => 'Estimated';

  @override
  String get statusPossibleDuplicate => 'Possible duplicate';

  @override
  String get privacyAndSecurity => 'Privacy and security';

  @override
  String get privacyIntro =>
      'Taxy keeps simulations and local entries on this device. e-Fatura credentials are sent over HTTPS to api.taxy.pt only when connecting and are not returned to the interface.';

  @override
  String get privacyEfatura =>
      'e-Fatura access is read-only. Disconnecting removes the saved session capability from this device.';

  @override
  String get diagnostics => 'Diagnostics';

  @override
  String get copyDiagnostics => 'Copy diagnostic information';

  @override
  String get diagnosticsCopied => 'Diagnostic information copied';

  @override
  String get diagnosticsNotice =>
      'Diagnostics contain build and environment details only — never NIF, credentials, tokens or invoice data.';

  @override
  String get sendFeedback => 'Send feedback';

  @override
  String get feedbackCopied => 'A safe feedback template was copied.';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'Use device setting';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get profileModuleDescription => 'Active year and tax details';

  @override
  String get incomeModuleDescription => 'Local income entries with source';

  @override
  String get expensesModuleDescription => 'Local supporting expenses';

  @override
  String get estimateBasis => 'What this estimate uses';

  @override
  String get incomeConsidered => 'Income considered';

  @override
  String get deductionsConsidered => 'Deductions considered';

  @override
  String get withholdingConsidered => 'Withholding considered';

  @override
  String get userEnteredSource => 'Entered by you';

  @override
  String get estimateNotOfficial =>
      'Estimated from the information entered and the supported Taxy rules. It is not an official AT assessment.';

  @override
  String get missingInformationImprove =>
      'More information is needed to improve this estimate.';

  @override
  String get category => 'Category';

  @override
  String get categoryEmployment => 'Employment';

  @override
  String get categorySelfEmployment => 'Self-employment';

  @override
  String get categoryPension => 'Pension';

  @override
  String get categoryOther => 'Other';

  @override
  String get categoryGeneral => 'General';

  @override
  String get categoryHealth => 'Health';

  @override
  String get categoryEducation => 'Education';

  @override
  String get categoryHousing => 'Housing';

  @override
  String get categoryProfessional => 'Professional activity';

  @override
  String get edit => 'Edit';

  @override
  String get profileChecklist => 'Fiscal checklist';

  @override
  String completedEssential(int completed, int total) {
    return '$completed of $total essential items completed';
  }

  @override
  String get checkActiveYear => 'Active tax year';

  @override
  String get checkResidence => 'Tax residence';

  @override
  String get checkCivilStatus => 'Civil status';

  @override
  String get checkHousehold => 'Household';

  @override
  String get checkWorkContext => 'Work situation';

  @override
  String get checkIncome => 'Income for the active year';

  @override
  String get impactResidence =>
      'Residence determines which supported regional rules apply.';

  @override
  String get impactCivilStatus =>
      'Civil status is needed to choose an applicable calculation mode.';

  @override
  String get impactHousehold =>
      'Household information can affect supported deductions and tax credits.';

  @override
  String get impactWorkContext =>
      'Work context identifies whether the current model supports your income.';

  @override
  String get impactIncome =>
      'Income and withholding are needed to estimate the final IRS balance.';

  @override
  String get scenarioComparison => 'Compare scenarios';

  @override
  String get scenarioIntro =>
      'Test hypothetical changes without changing your base information.';

  @override
  String get currentScenario => 'Current scenario';

  @override
  String get alternativeScenario => 'Alternative scenario';

  @override
  String get resultDifference => 'Result difference';

  @override
  String get whatChanged => 'What changed';

  @override
  String get noScenarioChanges => 'No hypothetical changes yet.';

  @override
  String get scenarioOverrideNotice =>
      'Alternative values are scenario overrides, not confirmed profile data.';

  @override
  String get savedEstimates => 'Saved estimates';

  @override
  String get saveEstimate => 'Save estimate';

  @override
  String get estimateSaved => 'Estimate saved on this device.';

  @override
  String get savedEstimate => 'Saved estimate';

  @override
  String get noSavedEstimates => 'No saved estimates';

  @override
  String get deleteSavedEstimate => 'Delete saved estimate';

  @override
  String get duplicateAsScenario => 'Duplicate as scenario';

  @override
  String get invoiceExplorer => 'Invoice explorer';

  @override
  String get searchInvoices => 'Search issuer';

  @override
  String get documentTotal => 'Document total';

  @override
  String get monthlySummary => 'Monthly summary';

  @override
  String get averageDocument => 'Average document';

  @override
  String get sortNewest => 'Newest first';

  @override
  String get sortOldest => 'Oldest first';

  @override
  String get sortHighest => 'Highest value';

  @override
  String get sortLowest => 'Lowest value';

  @override
  String get sortIssuer => 'Issuer name';

  @override
  String filteredInvoiceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matching invoices',
      one: '1 matching invoice',
      zero: 'No matching invoices',
    );
    return '$_temp0';
  }

  @override
  String lastUpdatedThisSession(String time) {
    return 'Last updated this session: $time';
  }

  @override
  String get offlineUnavailable =>
      'This area needs a connection. Check your network and try again.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get dateFilter => 'Date range';

  @override
  String get minimumAmount => 'Minimum amount';

  @override
  String get maximumAmount => 'Maximum amount';

  @override
  String get privacySnapshots =>
      'Saved IRS estimates remain only on this device. They contain normalized calculation inputs and results, never credentials or raw e-Fatura responses.';

  @override
  String get all => 'All';

  @override
  String get dashboardTitle => 'Your IRS at a glance';

  @override
  String simulationUpdatedForYear(int year) {
    return 'Updated using the $year tax rules.';
  }

  @override
  String get resumeDraft => 'Resume current simulation';

  @override
  String get viewCalculation => 'View calculation';

  @override
  String get change => 'Change';

  @override
  String get compare => 'Compare';

  @override
  String get exploreTaxOpportunities => 'Explore tax opportunities';

  @override
  String get readOnlyExperimental => 'Experimental read-only access';

  @override
  String get yourSimulations => 'Your simulations';

  @override
  String savedSimulationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saved on this device',
      one: '1 saved on this device',
      zero: 'None saved on this device',
    );
    return '$_temp0';
  }

  @override
  String get newSimulation => 'New';

  @override
  String refundAmount(String amount) {
    return 'Refund $amount';
  }

  @override
  String taxDueAmount(String amount) {
    return 'To pay $amount';
  }

  @override
  String get calculationUnavailable => 'Calculation unavailable';

  @override
  String get options => 'Options';

  @override
  String get rename => 'Rename';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get changeData => 'Change details';

  @override
  String get delete => 'Delete';

  @override
  String get renameSimulation => 'Rename simulation';

  @override
  String get name => 'Name';

  @override
  String copySimulationName(String name) {
    return '$name — copy';
  }

  @override
  String get deleteSimulationTitle => 'Delete this simulation?';

  @override
  String deleteSimulationMessage(String name) {
    return '“$name” will be removed from this device only.';
  }

  @override
  String get estimatedRefund => 'Estimated refund';

  @override
  String get estimatedAdditionalTax => 'Estimated additional tax';

  @override
  String get estimateUnavailable => 'Estimate unavailable';

  @override
  String get openDetails => 'Open details';

  @override
  String get transparencyFirst => 'Transparency first';

  @override
  String get calculationMethodIntro =>
      'The calculation is deterministic and does not use artificial intelligence. Monetary values use integer cents with explicit rounding.';

  @override
  String get netCategoryIncome => 'Net category income';

  @override
  String get netCategoryIncomeExplanation =>
      'We subtract the specific employment-income deduction from gross income.';

  @override
  String get minimumExistence => 'Minimum subsistence amount';

  @override
  String get minimumExistenceExplanation =>
      'Where applicable, we calculate the reduction established by article 70 of the Portuguese IRS Code.';

  @override
  String get progressiveBrackets => 'Progressive tax brackets';

  @override
  String progressiveBracketsExplanation(int year) {
    return 'We apply the $year general rates to taxable income.';
  }

  @override
  String get deductionsAndWithholding => 'Deductions and withholding';

  @override
  String get deductionsAndWithholdingExplanation =>
      'We apply category limits and the combined limit, then subtract IRS already withheld.';

  @override
  String get validatedScope => 'Validated scope';

  @override
  String get unsupportedScope => 'Not supported / needs verification';

  @override
  String get openValidationLab => 'Open tax validation lab';

  @override
  String validatedResidentScope(String jurisdiction) {
    return 'Resident for the full year · $jurisdiction.';
  }

  @override
  String get categoryAOnlyScope => 'Category A employment income only.';

  @override
  String get standardHouseholdScope =>
      'Individuals, single-parent families, married couples and standard de facto unions.';

  @override
  String get couplesComparisonScope =>
      'For couples, we calculate separate and joint filing and show the difference.';

  @override
  String get standardDependantsScope =>
      'Standard dependants, without shared custody, alternating residence or special allocation.';

  @override
  String get standardEducationScope =>
      'Standard education expenses, without displaced students or regional uplifts.';

  @override
  String verifiedRulesScope(String version, String date) {
    return 'Rules $version, verified on $date.';
  }

  @override
  String get regional2025Unsupported => 'Madeira and the Azores in 2025.';

  @override
  String get partialResidenceUnsupported =>
      'Part-year residence or non-residence.';

  @override
  String get incomeTypesUnsupported =>
      'IRS Jovem assessment, Category B income and pensions.';

  @override
  String get foreignIncomeUnsupported =>
      'Foreign, investment, property and capital-gains income.';

  @override
  String get specialSituationsUnsupported =>
      'Disability, displaced students, shared custody and other special situations.';

  @override
  String get guidedTaxTitle => 'Your guided tax review';

  @override
  String get guidedTaxIntro =>
      'Answer one simple question at a time. Taxy turns your answers into an organised tax profile.';

  @override
  String get guidedTaxStart => 'Start guided review';

  @override
  String get guidedTaxContinue => 'Continue your tax review';

  @override
  String get guidedTaxResume => 'Resume where you left off';

  @override
  String guidedTaxYear(int year) {
    return 'Tax year $year';
  }

  @override
  String guidedTaxProgress(int completed, int total) {
    return '$completed of $total areas reviewed';
  }

  @override
  String get guidedTaxWhy => 'Why we ask this';

  @override
  String get guidedTaxBack => 'Back';

  @override
  String get guidedTaxNext => 'Continue';

  @override
  String get guidedTaxReviewAnswers => 'Review your answers';

  @override
  String get guidedTaxEdit => 'Edit';

  @override
  String get guidedTaxFinish => 'See estimate';

  @override
  String get guidedTaxEstimate => 'IRS estimate';

  @override
  String get guidedTaxProvisionalEstimate => 'Provisional IRS estimate';

  @override
  String get guidedTaxEstimateGood => 'Good-quality estimate';

  @override
  String get guidedTaxEstimateIncomplete => 'Some information is still missing';

  @override
  String get guidedTaxHowResult => 'How we arrived at this result';

  @override
  String get guidedTaxIncome => 'Income';

  @override
  String get guidedTaxWithholding => 'Tax withheld';

  @override
  String get guidedTaxDeductions => 'Deductions considered';

  @override
  String get guidedTaxResult => 'Estimated result';

  @override
  String get guidedTaxNextAction => 'What to do next';

  @override
  String get guidedTaxUnsupported =>
      'We recorded this situation, but the current tax engine cannot calculate it safely yet.';

  @override
  String get guidedTaxSaved => 'Your progress is saved on this device.';

  @override
  String get guidedTaxMissingRequired => 'Required before we can estimate';

  @override
  String get guidedTaxMissingRecommended =>
      'Recommended to improve the estimate';

  @override
  String get guidedTaxNoAnswer => 'Not answered';

  @override
  String get guidedTaxYes => 'Yes';

  @override
  String get guidedTaxNo => 'No';

  @override
  String get guidedTaxInvalidNumber => 'Enter a valid value.';

  @override
  String get guidedTaxHomeReady => 'Your estimate is ready';

  @override
  String guidedTaxHomeAreas(int count) {
    return '$count areas still need review';
  }

  @override
  String get guidedTaxFoundEfatura => 'We found information in e-Fatura.';

  @override
  String guidedTaxPendingEfatura(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invoices need validation',
      one: '1 invoice needs validation',
    );
    return '$_temp0';
  }

  @override
  String get aboutYou => 'About you';

  @override
  String get family => 'Family';

  @override
  String get workAndIncome => 'Work and income';

  @override
  String get otherIncome => 'Other income';

  @override
  String get withholdingAndPayments => 'Withholding and payments';

  @override
  String get review => 'Review';

  @override
  String qResidentPortugal(int year) {
    return 'Were you a Portuguese tax resident throughout $year?';
  }

  @override
  String get whyResidentPortugal =>
      'The current Taxy engine supports full-year Portuguese tax residents.';

  @override
  String get qRegion => 'Where was your tax residence?';

  @override
  String get whyRegion =>
      'Mainland Portugal, Madeira and the Azores may use different tax rules.';

  @override
  String qAge(int year) {
    return 'How old were you at the end of $year?';
  }

  @override
  String get whyAge => 'Age can affect some deductions and benefits.';

  @override
  String qCivilStatus(int year) {
    return 'What was your family situation at the end of $year?';
  }

  @override
  String get whyCivilStatus =>
      'Couples can compare joint and separate taxation.';

  @override
  String get qJointTaxation => 'Would you like to see joint taxation first?';

  @override
  String get whyJointTaxation =>
      'Taxy can compare joint and separate taxation without changing your official choice.';

  @override
  String get qDependents => 'How many dependants were in your household?';

  @override
  String get whyDependents => 'Dependants can affect household deductions.';

  @override
  String qEmployment(int year) {
    return 'Did you work for an employer in $year?';
  }

  @override
  String get whyEmployment =>
      'This helps us ask only for the income information that applies to you.';

  @override
  String get qEmploymentGross => 'What was your total gross employment income?';

  @override
  String get whyEmploymentGross =>
      'Use the annual amount before IRS and Social Security deductions.';

  @override
  String get qSelfEmployment => 'Did you also work for yourself?';

  @override
  String get whySelfEmployment =>
      'Self-employment is recorded separately because its tax treatment differs.';

  @override
  String get qPension => 'Did you receive a pension?';

  @override
  String get whyPension => 'Pensions have their own tax treatment.';

  @override
  String get qForeignIncome => 'Did you receive income from outside Portugal?';

  @override
  String get whyForeignIncome =>
      'We identify foreign income but do not approximate unsupported calculations.';

  @override
  String get qRentalIncome => 'Did you receive rental income?';

  @override
  String get whyRentalIncome =>
      'Rental income needs separate treatment in the Portuguese return.';

  @override
  String get qExpensesReviewed =>
      'Have you reviewed your expenses and e-Fatura information?';

  @override
  String get whyExpensesReviewed =>
      'Complete expense information can improve the estimate. Unavailable official totals are never treated as zero.';

  @override
  String get qWithholding => 'How much IRS was withheld during the year?';

  @override
  String get whyWithholding =>
      'Withholding is tax already paid and is needed to estimate the final balance.';

  @override
  String get qSocialSecurity =>
      'How much did you pay in mandatory Social Security contributions?';

  @override
  String get whySocialSecurity =>
      'Mandatory contributions can affect taxable employment income.';

  @override
  String get qReview => 'Are these answers ready for calculation?';

  @override
  String get whyReview =>
      'You can go back and edit any answer. Dependent answers are removed when they no longer apply.';

  @override
  String get guidedTaxNotCalculation =>
      'This situation is saved, but no estimate is shown because the current engine does not support it safely.';

  @override
  String get guidedTaxDocumentsFoundation => 'Supporting documents';

  @override
  String get guidedTaxDocumentsHint =>
      'Document capture is prepared for future confirmed imports; no value is applied without your confirmation.';

  @override
  String get guidedTaxPrefilled =>
      'We already found this information. You can review it.';

  @override
  String get fiscalCompanionTitle => 'Your fiscal companion';

  @override
  String get fiscalCompanionIncomplete => 'Some information is still missing';

  @override
  String get fiscalCompanionReady => 'Your estimate is ready to review';

  @override
  String get fiscalCompanionProvisional => 'Your estimate is provisional';

  @override
  String get fiscalCompanionNoAction => 'Everything is up to date for now.';

  @override
  String get fiscalCompanionContinue => 'Continue your analysis';

  @override
  String get fiscalCompanionReviewEfatura => 'Review your pending invoices';

  @override
  String fiscalCompanionMissingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count areas need attention',
      one: '1 area needs attention',
    );
    return '$_temp0';
  }

  @override
  String get dataConflictTitle => 'We found different information';

  @override
  String get dataConflictBody =>
      'Choose which information we should use. Nothing is changed silently.';

  @override
  String get dataConflictResolve => 'Choose information';

  @override
  String dataConflictUseOption(String source, String value) {
    return 'Use $source: $value';
  }

  @override
  String get sourceUser => 'Entered by you';

  @override
  String get sourceEfatura => 'e-Fatura';

  @override
  String get updatedToday => 'Updated today';

  @override
  String get resetTaxYear => 'Reset this tax year';

  @override
  String resetTaxYearTitle(int year) {
    return 'Reset $year?';
  }

  @override
  String get resetTaxYearBody =>
      'This removes interview answers and manual income and expenses for this year. Your e-Fatura connection is not removed.';

  @override
  String get resetTaxYearConfirm => 'Reset year';

  @override
  String get estimateUpdated => 'The estimate was updated.';

  @override
  String get guidedDocumentsTitle => 'Document evidence';

  @override
  String get guidedDocumentsIntro =>
      'Confirm values from documents that the current estimate can use.';

  @override
  String get guidedDocumentsPrivacy =>
      'Captured files are encrypted temporarily on this device and deleted after confirmation or cancellation. Only confirmed values remain.';

  @override
  String get guidedDocumentsEntryHint =>
      'Review confirmed income, withholding and contribution values';

  @override
  String get guidedDocumentEmployment => 'Employment income statement';

  @override
  String get guidedDocumentWithholding => 'IRS withholding proof';

  @override
  String get guidedDocumentSocialSecurity =>
      'Social Security contributions proof';

  @override
  String get guidedDocumentsConfirmValue =>
      'Check the document and enter the annual total you want to confirm.';

  @override
  String get guidedDocumentsNotConfirmed => 'No value confirmed';

  @override
  String guidedDocumentsConfirmedAmount(String amount) {
    return 'Confirmed: $amount';
  }

  @override
  String guidedDocumentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count confirmed',
      one: '1 confirmed',
    );
    return '$_temp0';
  }

  @override
  String get complexIncomeTitle => 'Identified situations needing review';

  @override
  String get complexIncomeHint =>
      'These situations are recorded but are not included in the estimate until the tax engine supports them safely.';

  @override
  String get complexIncomeSelfEmployment => 'Self-employment income';

  @override
  String get complexIncomePension => 'Pension income';

  @override
  String get complexIncomeForeign => 'Income received outside Portugal';

  @override
  String get complexIncomeRental => 'Rental income';

  @override
  String get taxReviewTitle => 'Tax review';

  @override
  String get taxReviewReady => 'Ready to review';

  @override
  String get taxReviewNeedsReview => 'Needs your review';

  @override
  String get taxReviewIncomplete => 'Information is missing';

  @override
  String get taxReviewUnsupported => 'Includes situations not yet supported';

  @override
  String taxReviewRefund(String amount) {
    return '$amount estimated refund';
  }

  @override
  String taxReviewPayable(String amount) {
    return '$amount estimated to pay';
  }

  @override
  String get taxReviewEstimateHidden => 'Estimate not available yet';

  @override
  String get taxReviewEstimateDisclaimer =>
      'Based on the information available and the situations Taxy currently supports. This is not an official result.';

  @override
  String get taxReviewConflictsTitle => 'Information to confirm';

  @override
  String get taxReviewConflictSemantics =>
      'Information conflict. Choose the correct value or review it later.';

  @override
  String get taxReviewLater => 'Review later';

  @override
  String get taxReviewMissingTitle => 'Information is missing';

  @override
  String get taxReviewRequired => 'Required before we can calculate';

  @override
  String get taxReviewRecommended => 'Recommended to improve the estimate';

  @override
  String get taxReviewOptional => 'Optional';

  @override
  String get taxReviewSituationsTitle => 'Situations identified';

  @override
  String get taxReviewUnsupportedBody =>
      'We found information that is not yet included in the current estimate.';

  @override
  String get taxReviewNotIncluded => 'Not included in the current estimate';

  @override
  String get taxReviewBreakdownSubtitle =>
      'Values produced by Taxy\'s IRS engine';

  @override
  String get taxReviewIncludedTitle => 'What is included in this estimate';

  @override
  String get taxReviewSourceDocument => 'Confirmed document';

  @override
  String get taxReviewSocialSecurity => 'Social Security contributions';

  @override
  String get taxReviewInformation => 'Tax information';

  @override
  String get taxReviewIncomeConsidered => 'Income considered';

  @override
  String get taxReviewDeductionsConsidered => 'Deductions considered';

  @override
  String get taxReviewEstimatedTax => 'Estimated tax';

  @override
  String get taxReviewWithholdingConsidered => 'Tax withheld considered';

  @override
  String get taxReviewActionConflict => 'Resolve the difference in information';

  @override
  String get taxReviewActionMissing => 'Complete required information';

  @override
  String get taxReviewActionUnsupported => 'Review information not included';

  @override
  String get taxReviewActionEstimate => 'Review estimate';

  @override
  String get documentTakePhoto => 'Take a photo';

  @override
  String get documentChooseFile => 'Choose file';

  @override
  String get documentManualEntry => 'Enter values manually';

  @override
  String get documentProcessing => 'Reading the document…';

  @override
  String get documentCapturePrivacyLocal =>
      'The document is processed on this device. Only values you explicitly confirm are kept.';

  @override
  String get documentCaptureLimits =>
      'PDF, JPG or PNG · up to 10 MB and 10 pages';

  @override
  String get documentReadFailure => 'We couldn\'t read this document safely.';

  @override
  String get documentTryAgain => 'Try again';

  @override
  String get documentDelete => 'Delete document';

  @override
  String get documentDeleteTitle => 'Delete this document?';

  @override
  String get documentDeleteBody =>
      'The temporary document and unconfirmed values will be removed.';

  @override
  String get documentFoundValues => 'We found these values';

  @override
  String get documentReviewIntro =>
      'Check the document and select only the values you want to confirm.';

  @override
  String get documentConfirmValues => 'Confirm values';

  @override
  String get documentConfirmExplanation =>
      'Only the values you confirm will be used by Taxy.';

  @override
  String get documentPartialHint =>
      'You can confirm some values and leave the others out.';

  @override
  String get documentPreview => 'Document preview';

  @override
  String get documentPreviewUnavailable => 'Preview is unavailable.';

  @override
  String get documentType => 'Document type';

  @override
  String get documentTypeEmployment => 'Employment income statement';

  @override
  String get documentTypeWithholding => 'IRS withholding proof';

  @override
  String get documentTypeSocialSecurity =>
      'Social Security contributions proof';

  @override
  String get documentTypeCombined => 'Employment annual statement';

  @override
  String get documentTypeUnknown => 'Unknown document';

  @override
  String get documentTypeUnsupported =>
      'This document type is not yet included in Taxy\'s estimate.';

  @override
  String get documentConfidenceHigh => 'High extraction confidence';

  @override
  String get documentConfidenceMedium => 'Check this extracted value';

  @override
  String get documentConfidenceLow => 'Low confidence — review required';

  @override
  String get documentValueEmployment => 'Employment income';

  @override
  String get documentValueWithholding => 'IRS withholding';

  @override
  String get documentValueSocialSecurity => 'Social Security contributions';

  @override
  String get documentValueTaxYear => 'Tax year';

  @override
  String documentYearMismatch(int year) {
    return 'This document appears to be from $year. It cannot be applied to the active tax year.';
  }

  @override
  String get documentCaptureUnavailable =>
      'Document capture is available on Android. You can still enter values manually.';

  @override
  String get documentTooLarge => 'This file is larger than the 10 MB limit.';

  @override
  String get documentTooManyPages => 'This PDF has more than 10 pages.';

  @override
  String get documentUnsupportedFile => 'Choose a valid PDF, JPG or PNG file.';

  @override
  String get documentSavedAndDeleted =>
      'Values confirmed. The temporary document was deleted.';

  @override
  String get documentOriginalNotStored =>
      'The original document is not kept after confirmation.';

  @override
  String get irsHistoryTitle => 'Previous IRS return';

  @override
  String get irsHistoryCardSubtitle =>
      'Use confirmed information from your 2024 IRS return to answer fewer questions';

  @override
  String get irsHistoryIntro =>
      'We found information in your previous IRS return';

  @override
  String get irsHistoryPrivacy =>
      'The return is read in memory only. The PDF, XML and declaration identifiers are not stored.';

  @override
  String get irsHistorySelectIdentity => 'Select Taxy identity';

  @override
  String get irsHistorySelectPublicCertificate =>
      'Select AT public certificate';

  @override
  String get irsHistoryFind2024 => 'Find 2024 IRS return';

  @override
  String get irsHistoryContinueManual => 'Continue without previous IRS';

  @override
  String get irsHistoryFound => 'Information found';

  @override
  String irsHistoryYearNotice(int sourceYear, int targetYear) {
    return 'This information is from $sourceYear. It is only used for $targetYear if you confirm it.';
  }

  @override
  String get irsHistoryConfirmSelected => 'Confirm selection';

  @override
  String get irsHistoryIgnore => 'Ignore for now';

  @override
  String get irsHistoryReviewValue => 'Confirm or change';

  @override
  String get irsHistoryCategoryA => 'Employment income';

  @override
  String get irsHistoryCategoryB => 'Self-employment';

  @override
  String get irsHistoryCategoryBRegime => 'Self-employment regime';

  @override
  String get irsHistoryActivityCode => 'Activity code';

  @override
  String get irsHistoryTaxableProfit => 'Historical taxable profit';

  @override
  String get irsHistoryWithholding => 'Historical withholding';

  @override
  String get irsHistoryPresentIn2024 => 'Present in the 2024 IRS return';

  @override
  String get irsHistoryOrganizedAccounting => 'Organized accounting';

  @override
  String get irsHistoryNone =>
      'No previous return is available. You can continue manually.';

  @override
  String get irsHistoryUnknownTemplate =>
      'This return uses a format Taxy cannot recognize safely yet. Nothing was imported.';

  @override
  String get irsHistoryAuthenticationError =>
      'We could not sign in to Portal das Finanças. Check your details and try again.';

  @override
  String get irsHistoryFallback =>
      'We could not check your previous IRS return. The manual interview remains available.';
}
