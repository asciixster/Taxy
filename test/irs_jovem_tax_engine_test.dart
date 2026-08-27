import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/domain/models.dart';
import 'package:taxy_pt/domain/money.dart';
import 'package:taxy_pt/tax_engine/irs_jovem_tax_engine.dart';
import 'package:taxy_pt/tax_engine/tax_rules.dart';

void main() {
  late TaxRuleSet rules;

  setUpAll(() async {
    rules = await TaxRuleRepository((path) => File(path).readAsString())
        .load(2025, 'continent');
  });

  final fixedCases =
      <
        ({
          String name,
          int gross,
          int socialSecurity,
          int regimeYear,
          int exempt,
          int taxable,
          int rateIncome,
          int grossTax,
          int normalTax,
        })
      >[
        (
          name: 'primeiro ano salário baixo',
          gross: 2000000,
          socialSecurity: 220000,
          regimeYear: 1,
          exempt: 2000000,
          taxable: 0,
          rateIncome: 2000000,
          grossTax: 0,
          // 20 000,00 - 4 462,15 = 15 537,85 € de rendimento coletável;
          // a aplicação progressiva fixa resulta em 2 389,73 €.
          normalTax: 238973,
        ),
        (
          name: 'primeiro ano salário alto',
          gross: 6000000,
          socialSecurity: 660000,
          regimeYear: 1,
          exempt: 2873750,
          taxable: 2466250,
          rateIncome: 5340000,
          grossTax: 726107,
          normalTax: 1572189,
        ),
        (
          name: 'segundo ano',
          gross: 3000000,
          socialSecurity: 330000,
          regimeYear: 2,
          exempt: 2250000,
          taxable: 303785,
          rateIncome: 2553785,
          grossTax: 59559,
          normalTax: 500690,
        ),
        (
          name: 'quinto ano',
          gross: 3000000,
          socialSecurity: 330000,
          regimeYear: 5,
          exempt: 1500000,
          taxable: 1053785,
          rateIncome: 2553785,
          grossTax: 206603,
          normalTax: 500690,
        ),
        (
          name: 'oitavo ano',
          gross: 3000000,
          socialSecurity: 330000,
          regimeYear: 8,
          exempt: 750000,
          taxable: 1803785,
          rateIncome: 2553785,
          grossTax: 353646,
          normalTax: 500690,
        ),
      ];

  for (final fixture in fixedCases) {
    test('referência manual fixa: ${fixture.name}', () {
      final comparison = IrsJovemTaxEngine(rules).compare(
        _simulation(
          gross: fixture.gross,
          socialSecurity: fixture.socialSecurity,
          regimeYear: fixture.regimeYear,
        ),
      );
      expect(comparison.eligibility.status, IrsJovemEligibility.eligible);
      expect(comparison.normal.grossTax.cents, fixture.normalTax);
      expect(comparison.adjustment!.exemptIncome.cents, fixture.exempt);
      expect(comparison.withIrsJovem!.taxableIncome.cents, fixture.taxable);
      expect(
        comparison.adjustment!.rateDeterminingIncome.cents,
        fixture.rateIncome,
      );
      expect(comparison.withIrsJovem!.grossTax.cents, fixture.grossTax);
      expect(
        comparison.estimatedBenefit.cents,
        fixture.normalTax - fixture.grossTax,
      );
    });
  }

  test('55 IAS limita o rendimento isento ao cêntimo', () {
    for (final delta in [-1, 0, 1]) {
      final gross = 2873750 + delta;
      final comparison = IrsJovemTaxEngine(rules).compare(
        _simulation(gross: gross, socialSecurity: 316113, regimeYear: 1),
      );
      expect(
        comparison.adjustment!.exemptIncome.cents,
        gross < 2873750 ? gross : 2873750,
      );
    }
  });

  test('retenção altera saldo mas não imposto ou benefício', () {
    final low = IrsJovemTaxEngine(rules).compare(
      _simulation(
        gross: 3000000,
        socialSecurity: 330000,
        regimeYear: 5,
        withholding: 100000,
      ),
    );
    final high = IrsJovemTaxEngine(rules).compare(
      _simulation(
        gross: 3000000,
        socialSecurity: 330000,
        regimeYear: 5,
        withholding: 500000,
      ),
    );
    expect(low.withIrsJovem!.taxDue, high.withIrsJovem!.taxDue);
    expect(low.estimatedBenefit, high.estimatedBenefit);
    expect(
      high.withIrsJovem!.balance.cents - low.withIrsJovem!.balance.cents,
      400000,
    );
  });

  test('saúde, educação e PPR continuam deduções à coleta', () {
    final comparison = IrsJovemTaxEngine(rules).compare(
      _simulation(
        gross: 3000000,
        socialSecurity: 330000,
        regimeYear: 5,
        deductions: const DeductionInput(
          health: Money.fromCents(100000),
          education: Money.fromCents(100000),
          ppr: Money.fromCents(200000),
        ),
      ),
    );
    expect(comparison.withIrsJovem!.taxCredits.cents, 85000);
    expect(comparison.withIrsJovem!.taxDue.cents, 121603);
    expect(comparison.normal.taxDue.cents, 415690);
  });

  test('informação incompleta mantém liquidação normal disponível', () {
    final simulation =
        _simulation(
          gross: 3000000,
          socialSecurity: 330000,
          regimeYear: 5,
        ).copyWith(
          primaryIrsJovem: const IrsJovemAnswers(
            requested: true,
            taxSituationRegularized: true,
          ),
        );
    final comparison = IrsJovemTaxEngine(rules).compare(simulation);
    expect(comparison.normal.available, isTrue);
    expect(comparison.withIrsJovem, isNull);
    expect(
      comparison.eligibility.status,
      IrsJovemEligibility.needsMoreInformation,
    );
  });

  test('dependente menor de três anos mantém o crédito fixo', () {
    final comparison = IrsJovemTaxEngine(rules).compare(
      _simulation(
        gross: 3000000,
        socialSecurity: 330000,
        regimeYear: 5,
        dependentAges: const [2],
      ),
    );
    expect(comparison.withIrsJovem!.taxCredits.cents, 72600);
    expect(comparison.withIrsJovem!.taxDue.cents, 134003);
  });
}

TaxSimulation _simulation({
  required int gross,
  required int socialSecurity,
  required int regimeYear,
  int withholding = 0,
  DeductionInput deductions = const DeductionInput(),
  List<int> dependentAges = const [],
}) {
  final currentYear = 2025;
  final firstYear = currentYear - regimeYear + 1;
  final history = [
    for (var year = firstYear; year <= currentYear; year++)
      IrsJovemIncomeYear(
        year: year,
        hadCategoryAIncome: true,
        hadCategoryBIncome: false,
        wasDependent: false,
        residentInPortugal: true,
      ),
  ];
  final now = DateTime.utc(currentYear);
  return TaxSimulation(
    id: 'jovem-$regimeYear-$gross',
    name: 'IRS Jovem fixture',
    createdAt: now,
    updatedAt: now,
    profile: TaxpayerProfile(
      taxYear: 2025,
      age: 30,
      civilStatus: CivilStatus.single,
      dependentAges: dependentAges,
      fullYearResident: true,
      region: TaxRegion.continent,
      filingMode: FilingMode.separate,
      isSingleParentHousehold: dependentAges.isNotEmpty,
    ),
    income: EmploymentIncome(
      entryMode: IncomeEntryMode.annual,
      gross: Money.fromCents(gross),
      withholding: Money.fromCents(withholding),
      socialSecurity: Money.fromCents(socialSecurity),
    ),
    deductions: deductions,
    primaryIrsJovem: IrsJovemAnswers(
      requested: true,
      wasDependentAtYearEnd: false,
      taxSituationRegularized: true,
      historyConfirmedComplete: true,
      incomeHistory: history,
    ),
    dependents: [
      for (var i = 0; i < dependentAges.length; i++)
        Dependent(id: 'dependent-$i', ageAtYearEnd: dependentAges[i]),
    ],
  );
}
