import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/domain/models.dart';
import 'package:taxy_pt/domain/money.dart';
import 'package:taxy_pt/question_engine/question_engine.dart';
import 'package:taxy_pt/tax_engine/tax_engine.dart';
import 'package:taxy_pt/tax_engine/tax_rules.dart';

void main() {
  late TaxRuleSet rules;
  late TaxEngine engine;

  setUpAll(() {
    rules = TaxRuleSet.fromJsonString(File('assets/tax_rules/2026.json').readAsStringSync());
    engine = TaxEngine(rules);
  });

  group('regras e aritmética monetária', () {
    test('carrega o conjunto 2026 verificado', () {
      expect(rules.taxYear, 2026);
      expect(rules.brackets, hasLength(9));
      expect(rules.employmentSpecificDeductionCents, 458709);
    });

    test('interpreta vírgula e mantém cêntimos exatos', () {
      expect(Money.parseEuros('1 234,56').cents, 123456);
      expect(Money.fromCents(123456).format(), '1.234,56 €');
      expect(Money.parseEuros('1.234,56'), Money.fromCents(123456));
    });

    test('arredonda taxas a metade para cima', () {
      expect(const Money.fromCents(1).timesPpm(500000).cents, 1);
      expect(const Money.fromCents(3).timesPpm(500000).cents, 2);
    });
  });

  group('fronteiras dos escalões 2026', () {
    final cases = <(String, int, int)>[
      ('zero', 0, 0),
      ('limite do primeiro escalão', 834200, 104275),
      ('um euro após o primeiro escalão', 834300, 104291),
      ('limite do segundo escalão', 1258700, 170922),
      ('um euro após o segundo escalão', 1258800, 170940),
      ('limite do oitavo escalão', 8663400, 3019728),
      ('um euro no último escalão', 8663500, 3019763),
    ];
    for (final item in cases) {
      test(item.$1, () {
        expect(engine.grossTaxForTaxableIncome(Money.fromCents(item.$2)).cents, item.$3);
      });
    }
  });

  group('cenários fiscais completos', () {
    test('rendimento zero produz imposto zero', () {
      final result = engine.calculate(_simulation(gross: 0));
      expect(result.taxDue, Money.zero);
      expect(result.balance, Money.zero);
    });

    test('salário mínimo anual fica protegido pelo mínimo de existência', () {
      final result = engine.calculate(_simulation(
        gross: 1288000, socialSecurity: 141680, general: 100000,
      ));
      expect(result.taxDue.cents, 0);
      expect(result.minimumExistenceAllowance.cents, greaterThan(0));
    });

    test('usa a dedução específica legal quando superior às contribuições', () {
      final result = engine.calculate(_simulation(gross: 3000000, socialSecurity: 330000));
      expect(result.specificDeduction.cents, 458709);
      expect(result.taxableIncome.cents, 2541291);
      expect(result.taxDue.cents, 481065);
    });

    test('usa contribuições obrigatórias quando superiores à dedução fixa', () {
      final result = engine.calculate(_simulation(gross: 5000000, socialSecurity: 600000));
      expect(result.specificDeduction.cents, 600000);
      expect(result.taxableIncome.cents, 4400000);
    });

    test('retenções transformam imposto devido em reembolso', () {
      final result = engine.calculate(_simulation(
        gross: 3000000, socialSecurity: 330000, withholding: 600000,
      ));
      expect(result.balance.cents, 118935);
      expect(result.isRefund, isTrue);
    });

    test('despesas gerais respeitam o limite de 250 euros', () {
      final result = engine.calculate(_simulation(
        gross: 3000000, socialSecurity: 330000, general: 100000,
      ));
      expect(result.taxCredits.cents, 25000);
      expect(result.taxDue.cents, 456065);
      expect(result.warnings, isNotEmpty);
    });

    test('saúde respeita o limite de 1000 euros', () {
      final result = engine.calculate(_simulation(
        gross: 3000000, socialSecurity: 330000, health: 1000000,
      ));
      expect(result.taxCredits.cents, 100000);
      expect(result.taxDue.cents, 381065);
    });

    test('PPR abaixo dos 35 anos dá no máximo 400 euros', () {
      final result = engine.calculate(_simulation(
        gross: 3000000, socialSecurity: 330000, age: 30, ppr: 200000,
      ));
      expect(result.taxCredits.cents, 40000);
      expect(result.taxDue.cents, 441065);
    });

    test('PPR dos 35 aos 50 anos dá no máximo 350 euros', () {
      final result = engine.calculate(_simulation(
        gross: 3000000, socialSecurity: 330000, age: 40, ppr: 200000,
      ));
      expect(result.taxCredits.cents, 35000);
    });

    test('PPR acima dos 50 anos dá no máximo 300 euros', () {
      final result = engine.calculate(_simulation(
        gross: 3000000, socialSecurity: 330000, age: 60, ppr: 200000,
      ));
      expect(result.taxCredits.cents, 30000);
    });

    test('dependente com mais de três anos deduz 600 euros', () {
      final result = engine.calculate(_simulation(
        gross: 3000000, socialSecurity: 330000, dependentAges: [10],
      ));
      expect(result.taxCredits.cents, 60000);
    });

    test('primeiro dependente até três anos recebe majoração de 126 euros', () {
      final result = engine.calculate(_simulation(
        gross: 3000000, socialSecurity: 330000, dependentAges: [2],
      ));
      expect(result.taxCredits.cents, 72600);
    });

    test('segundo dependente até seis anos recebe majoração de 300 euros', () {
      final result = engine.calculate(_simulation(
        gross: 3000000, socialSecurity: 330000, dependentAges: [10, 5],
      ));
      expect(result.taxCredits.cents, 150000);
    });

    test('adicional de solidariedade começa acima de 80 mil euros', () {
      final result = engine.calculate(_simulation(gross: 10000000, socialSecurity: 330000));
      expect(result.taxableIncome.cents, 9541291);
      expect(result.solidarityTax.cents, 38532);
    });

    test('bloqueia Madeira sem inventar taxas', () {
      final result = engine.calculate(_simulation(gross: 3000000, region: TaxRegion.madeira));
      expect(result.available, isFalse);
      expect(result.warnings.single, contains('NEEDS_VERIFICATION'));
    });

    test('bloqueia tributação conjunta ainda não validada', () {
      final result = engine.calculate(_simulation(gross: 3000000, filingMode: FilingMode.joint));
      expect(result.available, isFalse);
    });

    test('bloqueia residência parcial', () {
      final result = engine.calculate(_simulation(gross: 3000000, fullYearResident: false));
      expect(result.available, isFalse);
    });

    test('serialização preserva todos os cêntimos', () {
      final original = _simulation(gross: 3000123, withholding: 45678, health: 12345);
      final restored = TaxSimulation.decode(original.encode());
      expect(restored.income.gross.cents, 3000123);
      expect(restored.income.withholding.cents, 45678);
      expect(restored.deductions.health.cents, 12345);
    });
  });

  group('motor de perguntas', () {
    test('salta idades dos dependentes quando não há dependentes', () {
      final ids = const QuestionEngine().steps(TaxDraft()).map((e) => e.id);
      expect(ids, isNot(contains('dependentAges')));
    });

    test('inclui idades quando existem dependentes', () {
      final draft = TaxDraft()..dependentAges = [3];
      final ids = const QuestionEngine().steps(draft).map((e) => e.id);
      expect(ids, contains('dependentAges'));
    });

    test('pergunta modo de tributação apenas a casados ou unidos de facto', () {
      final single = TaxDraft();
      final married = TaxDraft()..civilStatus = CivilStatus.married;
      expect(const QuestionEngine().steps(single).map((e) => e.id), isNot(contains('filingMode')));
      expect(const QuestionEngine().steps(married).map((e) => e.id), contains('filingMode'));
    });
  });
}

TaxSimulation _simulation({
  required int gross,
  int withholding = 0,
  int socialSecurity = 0,
  int general = 0,
  int health = 0,
  int education = 0,
  int rent = 0,
  int careHomes = 0,
  int invoiceVat = 0,
  int ppr = 0,
  int age = 30,
  List<int> dependentAges = const [],
  TaxRegion region = TaxRegion.continent,
  FilingMode filingMode = FilingMode.separate,
  bool fullYearResident = true,
}) => TaxSimulation(
  id: 'fixture',
  name: 'Fixture',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  profile: TaxpayerProfile(
    taxYear: 2026,
    age: age,
    civilStatus: filingMode == FilingMode.joint ? CivilStatus.married : CivilStatus.single,
    dependentAges: dependentAges,
    fullYearResident: fullYearResident,
    region: region,
    filingMode: filingMode,
  ),
  income: EmploymentIncome(
    entryMode: IncomeEntryMode.annual,
    gross: Money.fromCents(gross),
    withholding: Money.fromCents(withholding),
    socialSecurity: Money.fromCents(socialSecurity),
  ),
  deductions: DeductionInput(
    general: Money.fromCents(general),
    health: Money.fromCents(health),
    education: Money.fromCents(education),
    rent: Money.fromCents(rent),
    careHomes: Money.fromCents(careHomes),
    eligibleInvoiceVat: Money.fromCents(invoiceVat),
    ppr: Money.fromCents(ppr),
  ),
);
