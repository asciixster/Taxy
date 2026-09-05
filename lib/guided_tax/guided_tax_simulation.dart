import '../domain/models.dart';
import '../domain/money.dart';
import 'tax_interview_models.dart';

TaxSimulation? simulationFromInterview(
  TaxInterview interview, {
  required DateTime now,
}) {
  Object? value(String id) => interview.answers[id]?.value;
  if (value('employmentIncome') != true ||
      value('selfEmploymentIncome') == true ||
      value('pensionIncome') == true ||
      value('foreignIncome') == true ||
      value('rentalIncome') == true ||
      value('civilStatus') != 'single') {
    return null;
  }
  final gross = value('employmentGrossCents');
  final withholding = value('withholdingCents');
  final socialSecurity = value('socialSecurityCents');
  final age = value('age');
  if (gross is! int ||
      withholding is! int ||
      socialSecurity is! int ||
      age is! int) {
    return null;
  }
  final dependents = value('dependentCount') is int
      ? value('dependentCount') as int
      : 0;
  final region = switch (value('region')) {
    'madeira' => TaxRegion.madeira,
    'azores' => TaxRegion.azores,
    _ => TaxRegion.continent,
  };
  return TaxSimulation(
    id: 'guided-${interview.taxYear}',
    name: 'Guided ${interview.taxYear}',
    createdAt: now,
    updatedAt: now,
    profile: TaxpayerProfile(
      taxYear: interview.taxYear,
      age: age,
      civilStatus: CivilStatus.single,
      dependentAges: List.filled(dependents, 10),
      fullYearResident: value('residentPortugal') == true,
      region: region,
      filingMode: FilingMode.separate,
      isSingleParentHousehold: dependents > 0,
    ),
    income: EmploymentIncome(
      entryMode: IncomeEntryMode.annual,
      gross: Money.fromCents(gross),
      withholding: Money.fromCents(withholding),
      socialSecurity: Money.fromCents(socialSecurity),
    ),
    deductions: const DeductionInput(),
    dependents: List.generate(
      dependents,
      (index) => Dependent(id: 'guided-$index', ageAtYearEnd: 10),
    ),
  );
}
