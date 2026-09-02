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
  String get previewClearAnswer => 'A clear answer,';

  @override
  String get previewTransparentAccounts => 'transparent calculations.';

  @override
  String get explainedLabel => 'Explained';

  @override
  String get irsModuleDescription =>
      'Simulate, compare and understand your assessment.';

  @override
  String get whatEstimateMeans => 'What this means';

  @override
  String get refundEstimateMeaning =>
      'You had more IRS withheld during the year than the estimated tax in this simulation.';

  @override
  String get taxDueEstimateMeaning =>
      'The amount withheld during the year is below the estimated tax.';

  @override
  String get draftRestoreError =>
      'We couldn\'t restore the draft. Your saved data was not changed.';

  @override
  String get draftSaveError =>
      'We couldn\'t save progress on this device. You can continue, but check storage before closing the app.';

  @override
  String get partialResidenceError =>
      'Not supported yet: part-year tax residence.';

  @override
  String get regionalYearError =>
      'Not supported yet: Madeira and the Azores for 2025 still need verification.';

  @override
  String get incomeScopeError =>
      'Not supported yet: we can only calculate when all income is from employment.';

  @override
  String get specialSituationError =>
      'Not supported yet: this case needs further validation and will not be approximated.';

  @override
  String get historyAError =>
      'Not enough information: the complete annual history for taxpayer A is missing.';

  @override
  String get historyBError =>
      'Not enough information: the complete annual history for taxpayer B is missing.';

  @override
  String get singleParentScopeError =>
      'Not supported yet: with dependants, only the standard single-parent household is validated.';

  @override
  String get positiveIncomeError =>
      'Invalid data: enter income greater than zero.';

  @override
  String get secondaryIncomeError =>
      'Invalid data: the second taxpayer\'s income cannot be negative.';

  @override
  String get moneyValuesError =>
      'Invalid data: review the monetary amounts before calculating.';

  @override
  String get calculationSafetyError =>
      'We couldn\'t complete the calculation safely. Your draft is still saved; try again.';

  @override
  String upToAdditional(String amount) {
    return 'up to +$amount';
  }

  @override
  String enteredExpenseMargin(String amount) {
    return 'Room in entered expenses: $amount';
  }

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
  String get sourceCalculated => 'Calculated';

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
  String wizardStepTitle(String step) {
    String _temp0 = intl.Intl.selectLogic(step, {
      'taxYear': 'Which year do you want to simulate?',
      'residency': 'Were you tax resident in Portugal for the full year?',
      'region': 'Where is your tax residence?',
      'civilStatus': 'What is your marital status?',
      'incomeTypes': 'What types of income did you receive?',
      'specialSituations': 'Does any special tax situation apply?',
      'irsJovemInterest': 'Would you like to check IRS Jovem?',
      'irsJovemHistory': 'Confirm your annual work history',
      'age': 'How old are you?',
      'secondaryAge': 'How old is the second taxpayer?',
      'filingMode': 'Which option would you like to see first?',
      'dependents': 'Do you have children or other dependants?',
      'dependentAges': 'How old are the dependants?',
      'singleParent': 'Is this a single-parent household?',
      'incomeMode': 'How would you like to enter income?',
      'grossAnnual': 'What was your annual gross income?',
      'grossMonthly': 'What was your monthly gross income?',
      'withholding': 'How much IRS was withheld?',
      'socialSecurity':
          'How much did you pay in Social Security contributions?',
      'secondaryGross': 'Annual gross income of the second taxpayer',
      'secondaryWithholding': 'Annual withholding of the second taxpayer',
      'secondarySocialSecurity':
          'Social Security contributions of the second taxpayer',
      'general': 'General household expenses',
      'health': 'How much did you spend on healthcare?',
      'education': 'And on education and training?',
      'rent': 'Did you pay rent for your permanent home?',
      'careHomes': 'Did you have nursing-home expenses?',
      'invoiceVat15': 'VAT eligible for a 15% deduction',
      'invoiceVat30': 'VAT eligible for a 30% deduction',
      'invoiceVat35': 'VAT eligible for a 35% deduction',
      'invoiceVat100': 'VAT eligible for a 100% deduction',
      'ppr': 'How much did you invest in a PPR?',
      'secondaryDeductions': 'Expenses of the second taxpayer',
      'review': 'Everything is ready to calculate',
      'other': 'Simulation step',
    });
    return '$_temp0';
  }

  @override
  String wizardStepHelper(String step) {
    String _temp0 = intl.Intl.selectLogic(step, {
      'taxYear': 'Tax rules change every year.',
      'residency': 'Part-year residence follows different rules.',
      'region':
          'Mainland Portugal, Madeira and the Azores may use different tables.',
      'civilStatus': 'Married couples and de facto partners can compare joint and separate filing.',
      'incomeTypes': 'If an income type is not supported yet, we will say so rather than ignore it.',
      'specialSituations': 'Shared custody, disability, part-year residence and other regimes need specific treatment.',
      'irsJovemInterest': 'If you are not eligible, we continue with the standard IRS calculation.',
      'irsJovemHistory': 'Each year is described objectively; years as a dependant or without Category A/B income do not use the benefit.',
      'age': 'Age may affect benefits such as the PPR deduction.',
      'secondaryAge':
          'Both taxpayers are calculated individually and together.',
      'filingMode': 'Taxy will always calculate joint and separate filing for comparison.',
      'dependents': 'Enter how many belong to your household.',
      'dependentAges': 'Age on 31 December may increase the deduction.',
      'singleParent': 'Confirm only a standard single-parent household. Alternating residence or shared responsibilities are not yet supported.',
      'incomeMode': 'You can use an annual total or a monthly amount.',
      'grossAnnual': 'Use amounts before IRS and Social Security.',
      'grossMonthly': 'Use amounts before IRS and Social Security.',
      'withholding': 'This is the annual total shown on payslips or the employer statement.',
      'socialSecurity': 'Enter only mandatory employee contributions.',
      'secondaryGross': 'Enter only Category A income for this taxpayer.',
      'secondaryWithholding': 'Total IRS already withheld.',
      'secondarySocialSecurity': 'Mandatory annual contributions.',
      'general': 'Eligible e-Fatura purchases and services, excluding health, education and rent.',
      'health': 'Enter eligible expenses that were not reimbursed.',
      'education': 'Include standard education only. Displaced students and regional uplifts are not supported.',
      'rent': 'Enter the annual rent total reported to AT.',
      'careHomes': 'This may include eligible home support and institutions.',
      'invoiceVat15':
          'Enter VAT, not the total expense, for eligible standard sectors.',
      'invoiceVat30':
          'Enter VAT from eligible sports education, clubs and gyms.',
      'invoiceVat35': 'Enter only VAT from eligible veterinary medicines.',
      'invoiceVat100': 'Enter VAT from eligible public transport and periodical subscriptions.',
      'ppr': 'The benefit depends on age and the legal holding conditions.',
      'secondaryDeductions': 'Enter expenses assigned to the second taxpayer; personal expenses are not divided automatically.',
      'review': 'Review the main values before saving the simulation.',
      'other': 'Review the details for this step.',
    });
    return '$_temp0';
  }

  @override
  String wizardSection(String section) {
    String _temp0 = intl.Intl.selectLogic(section, {
      'eligibility': 'Scope',
      'profile': 'Profile',
      'income': 'Income',
      'deductions': 'Expenses',
      'review': 'Review',
      'other': 'Simulation',
    });
    return '$_temp0';
  }

  @override
  String get calculateEstimate => 'Calculate estimate';

  @override
  String get continueAction => 'Continue';

  @override
  String wizardText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'year2025Helper': 'Return filed in 2026',
      'currentYear': 'Current year',
      'singleStatus': 'Not married or in a de facto union',
      'individualAssessment': 'Individual assessment',
      'marriedStatus': 'Married',
      'deFactoStatus': 'De facto union',
      'compareJointSeparate': 'Compares joint and separate filing',
      'fullYearResident': 'Resident for the full year',
      'unsupportedCannotContinue':
          'Not supported — you will not be able to continue',
      'calculationAvailable': 'Calculation available',
      'available2026': 'Available for 2026',
      'categoryAAvailable': 'Category A · available',
      'notAvailableYet': 'Not available yet',
      'standardCase': 'Standard case',
      'yesUnsure': 'Yes / I am not sure',
      'calculationBlockedSafety': 'The calculation will stop for safety',
      'checkIrsJovemA': 'Check IRS Jovem for taxpayer A',
      'checkIrsJovemB': 'Check IRS Jovem for taxpayer B',
      'eligibilityByHistory':
          'Eligibility will be determined from the annual history.',
      'historyFormat': 'One line per year: year,A|B|AB|N,dependant,resident,incompatible regime',
      'historyA': 'History for taxpayer A',
      'historyB': 'History for taxpayer B',
      'historyCompleteA': 'History A is complete',
      'historyCompleteB': 'History B is complete',
      'taxRegularA': 'Tax situation A is regularised',
      'taxRegularB': 'Tax situation B is regularised',
      'separate': 'Separate',
      'separateFirst': 'Shows both assessments first',
      'joint': 'Joint',
      'maritalQuotient': 'Applies marital quotient 2',
      'standardSingleParent': 'Standard single-parent household',
      'noUnsure': 'No / I am not sure',
      'annualTotal': 'Annual total',
      'oneAnnualValue': 'One value for the year',
      'monthlyTimesMonths': 'Monthly × months',
      'appCalculatesAnnual': 'The app calculates the annual total',
      'annualIncome': 'Annual income',
      'monthlyIncome': 'Monthly income',
      'paymentCount': 'Number of payments',
      'annualWithholding': 'Annual IRS withholding',
      'annualContributions': 'Annual contributions',
      'secondaryAnnualIncome': 'Annual income of taxpayer B',
      'secondaryAnnualWithholding': 'Annual withholding of taxpayer B',
      'secondaryAnnualContributions': 'Annual contributions of taxpayer B',
      'generalExpensesTotal': 'Total general expenses',
      'healthTotal': 'Total healthcare expenses',
      'eligibleEducation': 'Eligible standard education',
      'educationExclusions': 'Excludes displaced students and regional uplifts',
      'annualRent': 'Annual rent',
      'annualCharges': 'Annual charges',
      'vat15': 'VAT eligible at the 15% rate',
      'vat30': 'VAT eligible at the 30% rate',
      'vat35': 'VAT eligible at the 35% rate',
      'vat100': 'VAT eligible at the 100% rate',
      'annualPpr': 'Annual PPR investments',
      'secondaryGeneral': 'General expenses · taxpayer B',
      'secondaryHealth': 'Healthcare · taxpayer B',
      'secondaryEducation': 'Standard education · taxpayer B',
      'secondaryRent': 'Rent · taxpayer B',
      'secondaryCareHomes': 'Nursing homes · taxpayer B',
      'secondaryPpr': 'PPR · taxpayer B',
      'other': '—',
    });
    return '$_temp0';
  }

  @override
  String dependentNumber(int number) {
    return 'Dependant $number';
  }

  @override
  String get yearsSuffix => 'years';

  @override
  String monthCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String incomeTypeName(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'employment': 'Employment income',
      'selfEmployment': 'Self-employment income',
      'pensions': 'Pensions',
      'property': 'Rental income',
      'capital': 'Interest or dividends',
      'securities': 'Shares or ETFs',
      'crypto': 'Cryptoassets',
      'foreign': 'Foreign income',
      'other': 'Other income',
    });
    return '$_temp0';
  }

  @override
  String legacyUiText(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'estimateTitle': 'Your estimate',
      'normalIrs': 'Standard IRS',
      'estimatedTaxBenefit': 'Estimated tax benefit',
      'whyEligible': 'Why am I eligible?',
      'whyEligiblePlural': 'Why are we eligible?',
      'eligibilityDefault': 'Eligibility was determined from the annual history, age, residence and tax situation provided.',
      'separateWithoutJovem': 'Separate filing without IRS Jovem',
      'jointWithoutJovem': 'Joint filing without IRS Jovem',
      'separateWithJovem': 'Separate filing with IRS Jovem',
      'jointWithJovem': 'Joint filing with IRS Jovem',
      'estimatedBestBenefit': 'Estimated tax benefit under the best option',
      'taxpayerA': 'Taxpayer A',
      'taxpayerB': 'Taxpayer B',
      'estimateDisclaimer': 'Based on the data entered, this is the estimated tax difference; it does not guarantee a benefit.',
      'taxComparison': 'Filing comparison',
      'separateTaxation': 'Separate filing',
      'jointTaxation': 'Joint filing',
      'difference': 'Difference',
      'estimatedBestOption': 'Estimated best option',
      'noEstimatedDifference': 'No estimated difference',
      'equalTax':
          'In this simulation, both options have the same estimated tax.',
      'jointLower':
          'In this simulation, joint filing has the lower estimated tax.',
      'separateLower':
          'In this simulation, separate filing has the lower estimated tax.',
      'officialDisclaimer': 'Simulation based on the data entered and configured tax rules; it does not replace AT’s official assessment.',
      'categoryA': 'Category A',
      'individualTaxpayer': 'Individual taxpayer',
      'rules': 'Rules',
      'jovemApplied': 'IRS Jovem applied',
      'jovemNotApplied': 'IRS Jovem not applied',
      'taxableIncome': 'Taxable income',
      'retainedYear': 'Withheld during the year',
      'compareScenario': 'Compare scenario',
      'viewOpportunities': 'View opportunities',
      'detailedCalculation': 'View detailed calculation',
      'detailedCalculationSubtitle': 'Values and explanations line by line',
      'limitsWarning': 'Check the limits',
      'calculationUnavailable': 'Calculation unavailable',
      'simulationAssumptions': 'Simulation assumptions',
      'ppr': 'PPR',
      'health': 'Healthcare',
      'education': 'Education',
      'rent': 'Rent',
      'generalExpenses': 'General expenses',
      'annualApplied': 'Amount invested during the year',
      'eligibleExpenses': 'Eligible expenses',
      'eligibleRents': 'Eligible rent',
      'nifInvoice': 'Invoice includes a NIF',
      'saveNewSimulation': 'Save as a new simulation',
      'pprDisclaimer': 'A PPR tax advantage is subject to eligibility and holding conditions. This comparison does not assess product costs, risk or returns.',
      'scenarioSaved': 'Scenario saved on this device.',
      'opportunities': 'Opportunities',
      'whereMargin': 'Where might there be room to improve?',
      'opportunitiesIntro': 'We simulate each category independently up to its limit. We do not assume expenses that you did not enter.',
      'noExtraOpportunities': 'No additional opportunities in this simulation',
      'limitsReached': 'The limits may already have been reached, or there may not be enough tax to deduct.',
      'important': 'Important',
      'upToDisclaimer':
          '“Up to” is not a refund promise: it depends on the full simulation.',
      'dontSpend': 'Do not spend solely to obtain a tax deduction.',
      'realExpensesOnly': 'Enter only real, eligible and documented expenses.',
      'fiscalScope': 'Tax scope',
      'yearAndRegion': 'Year and region',
      'household': 'Household',
      'pendingReview': 'To be checked',
      'notRequested': 'Not requested',
      'profileHousehold': 'Profile and household',
      'dependants': 'Dependants',
      'none': 'None',
      'incomeWithholding': 'Income and withholding',
      'incomeA': 'Income A',
      'withholdingA': 'Withholding A',
      'socialA': 'Social Security A',
      'incomeB': 'Income B',
      'withholdingB': 'Withholding B',
      'socialB': 'Social Security B',
      'deductionsEntered': 'Deductions entered',
      'totalA': 'Taxpayer A total',
      'totalB': 'Taxpayer B total',
      'standardEducationOnly': 'Standard scenario only',
      'edit': 'Edit',
      'other': '—',
    });
    return '$_temp0';
  }
}
