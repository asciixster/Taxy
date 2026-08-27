import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/domain/models.dart';
import 'package:taxy_pt/domain/money.dart';
import 'package:taxy_pt/tax_engine/tax_engine.dart';
import 'package:taxy_pt/tax_engine/tax_rules.dart';

void main() {
  late TaxRuleSet rules;
  late TaxEngine engine;

  setUpAll(() {
    rules = TaxRuleSet.fromJsonString(
      File('assets/tax_rules/2026.json').readAsStringSync(),
    );
    engine = TaxEngine(rules);
  });

  group('regras e dinheiro exato', () {
    test('carrega regras base 2026.4.0 e data de validação', () {
      expect(rules.taxYear, 2026);
      expect(rules.rulesVersion, '2026.4.0-base');
      expect(rules.verifiedAt, DateTime(2026, 8, 27));
      expect(rules.brackets, hasLength(9));
    });

    test('novos parâmetros têm metadados auditáveis', () {
      for (final key in [
        'generalSingleParentRatePpm',
        'generalSingleParentCapCents',
        'invoiceVat15RatePpm',
        'invoiceVat30RatePpm',
        'invoiceVat35RatePpm',
        'invoiceVat100RatePpm',
        'invoiceVatCapCents',
      ]) {
        expect(rules.ruleMetadata[key]?.source, isNotEmpty, reason: key);
        expect(rules.ruleMetadata[key]?.version, isNotEmpty, reason: key);
      }
    });

    test('interpreta euros portugueses sem floating point', () {
      expect(Money.parseEuros('1 234,56').cents, 123456);
      expect(Money.parseEuros('1.234,56').cents, 123456);
      expect(Money.fromCents(123456).format(), '1.234,56 €');
    });

    test('arredonda metade para cima ao cêntimo', () {
      expect(const Money.fromCents(1).timesPpm(500000).cents, 1);
      expect(const Money.fromCents(3).timesPpm(500000).cents, 2);
    });

    test('rejeita schema fiscal antigo', () {
      final source = File('assets/tax_rules/2026.json').readAsStringSync();
      expect(
        () => TaxRuleSet.fromJsonString(
          source.replaceFirst('"schemaVersion": 2', '"schemaVersion": 1'),
        ),
        throwsFormatException,
      );
    });
  });

  group('golden — fronteiras dos escalões', () {
    test('zero produz coleta zero', () {
      expect(engine.grossTaxForTaxableIncome(Money.zero), Money.zero);
    });

    for (var index = 0; index < 8; index++) {
      for (final delta in const [-1, 0, 1]) {
        test('escalão ${index + 1}: ${_deltaLabel(delta)}', () {
          final taxable = rules.brackets[index].upperCents! + delta;
          expect(
            engine.grossTaxForTaxableIncome(Money.fromCents(taxable)).cents,
            _expectedGrossTax(rules, taxable),
          );
        });
      }
    }

    test('rendimento elevado usa o último escalão', () {
      const taxable = 50000000;
      expect(
        engine.grossTaxForTaxableIncome(const Money.fromCents(taxable)).cents,
        _expectedGrossTax(rules, taxable),
      );
    });
  });

  group('golden — mínimo de existência', () {
    final cases = <String, int Function()>{
      'zero': () => 0,
      'um cêntimo abaixo da referência': () =>
          rules.minimumExistenceReferenceCents - 1,
      'na referência': () => rules.minimumExistenceReferenceCents,
      'um cêntimo acima da referência': () =>
          rules.minimumExistenceReferenceCents + 1,
      'um cêntimo abaixo de L': () => _lValue(rules) - 1,
      'em L': () => _lValue(rules),
      'um cêntimo acima de L': () => _lValue(rules) + 1,
      'no limite final': () => _minimumExistenceCutoff(rules),
      'um cêntimo acima do limite final': () =>
          _minimumExistenceCutoff(rules) + 1,
    };
    for (final entry in cases.entries) {
      test(entry.key, () {
        final gross = entry.value();
        final result = engine.calculate(_simulation(gross: gross));
        expect(result.available, isTrue);
        expect(
          result.minimumExistenceAllowance.cents,
          _expectedMinimumExistence(
            rules,
            gross,
            result.specificDeduction.cents,
          ),
        );
      });
    }

    test('contribuições superiores substituem a dedução fixa', () {
      final result = engine.calculate(
        _simulation(gross: 5000000, socialSecurity: 600000),
      );
      expect(result.specificDeduction.cents, 600000);
      expect(result.taxableIncome.cents, 4400000);
    });

    test('dedução específica não excede rendimento', () {
      final result = engine.calculate(_simulation(gross: 10000));
      expect(result.specificDeduction.cents, 10000);
      expect(result.taxableIncome, Money.zero);
    });
  });

  group('golden — deduções isoladas', () {
    test('despesas gerais standard: 35% e cap 250', () {
      final result = engine.calculate(
        _simulation(gross: 3000000, general: 100000),
      );
      expect(_credit(result, 'Despesas gerais').cents, 25000);
    });

    test('monoparental: 45% e cap 335', () {
      final result = engine.calculate(
        _simulation(gross: 3000000, dependentAges: const [10], general: 100000),
      );
      expect(_credit(result, 'Despesas gerais').cents, 33500);
    });

    for (final item in const [
      ('Saúde', 'health', 1000000, 100000),
      ('Educação standard', 'education', 400000, 80000),
      ('Lares', 'careHomes', 200000, 40375),
      ('PPR', 'ppr', 200000, 40000),
    ]) {
      test('${item.$1} respeita taxa e limite', () {
        final result = engine.calculate(
          _simulation(
            gross: 3000000,
            health: item.$2 == 'health' ? item.$3 : 0,
            education: item.$2 == 'education' ? item.$3 : 0,
            careHomes: item.$2 == 'careHomes' ? item.$3 : 0,
            ppr: item.$2 == 'ppr' ? item.$3 : 0,
          ),
        );
        expect(_credit(result, item.$1).cents, item.$4);
      });
    }

    test('rendas aplicam taxa e cap 2026', () {
      final result = engine.calculate(
        _simulation(gross: 5000000, rent: 1000000),
      );
      expect(_credit(result, 'Rendas').cents, 90000);
    });

    for (final item in const [
      ('IVA — taxa 15%', 'vat15', 10000, 1500),
      ('IVA — taxa 30%', 'vat30', 10000, 3000),
      ('IVA — taxa 35%', 'vat35', 10000, 3500),
      ('IVA — taxa 100%', 'vat100', 10000, 10000),
    ]) {
      test(item.$1, () {
        final result = engine.calculate(
          _simulation(
            gross: 3000000,
            vat15: item.$2 == 'vat15' ? item.$3 : 0,
            vat30: item.$2 == 'vat30' ? item.$3 : 0,
            vat35: item.$2 == 'vat35' ? item.$3 : 0,
            vat100: item.$2 == 'vat100' ? item.$3 : 0,
          ),
        );
        expect(_credit(result, item.$1).cents, item.$4);
      });
    }

    test('IVA partilha limite global de 250 euros', () {
      final result = engine.calculate(
        _simulation(
          gross: 3000000,
          vat15: 100000,
          vat30: 100000,
          vat35: 100000,
          vat100: 100000,
        ),
      );
      final applied = result.creditBreakdown
          .where(
            (line) =>
                line.label.startsWith('IVA') ||
                line.label == 'Limite global do IVA',
          )
          .fold(Money.zero, (sum, line) => sum + line.amount);
      expect(applied.cents, 25000);
      expect(result.warnings.single, contains('dedução conjunta de IVA'));
    });

    test('PPR 35–50 anos tem cap 350', () {
      final result = engine.calculate(
        _simulation(gross: 3000000, age: 40, ppr: 200000),
      );
      expect(_credit(result, 'PPR').cents, 35000);
    });

    test('PPR acima de 50 anos tem cap 300', () {
      final result = engine.calculate(
        _simulation(gross: 3000000, age: 60, ppr: 200000),
      );
      expect(_credit(result, 'PPR').cents, 30000);
    });

    test('educação exclui casos especiais', () {
      final result = engine.calculate(
        _simulation(gross: 3000000, education: 10000),
      );
      expect(result.assumptions.join(' '), contains('estudante deslocado'));
      expect(result.assumptions.join(' '), contains('majorações territoriais'));
    });
  });

  group('dependentes determinísticos', () {
    test('[10, 2] e [2, 10] são idênticos', () {
      final a = engine.calculate(
        _simulation(gross: 3000000, dependentAges: const [10, 2]),
      );
      final b = engine.calculate(
        _simulation(gross: 3000000, dependentAges: const [2, 10]),
      );
      expect(a.taxCredits, b.taxCredits);
      expect(a.taxDue, b.taxDue);
    });

    test('três dependentes são invariantes a permutação', () {
      final a = engine.calculate(
        _simulation(gross: 5000000, dependentAges: const [12, 5, 2]),
      );
      final b = engine.calculate(
        _simulation(gross: 5000000, dependentAges: const [2, 12, 5]),
      );
      expect(a.taxCredits, b.taxCredits);
    });

    test('quatro dependentes são invariantes a ordem inversa', () {
      final a = engine.calculate(
        _simulation(gross: 7000000, dependentAges: const [16, 8, 4, 1]),
      );
      final b = engine.calculate(
        _simulation(gross: 7000000, dependentAges: const [1, 4, 8, 16]),
      );
      expect(a.taxCredits, b.taxCredits);
    });

    test('dependente único até três anos recebe 726 euros', () {
      final result = engine.calculate(
        _simulation(gross: 3000000, dependentAges: const [2]),
      );
      expect(_credit(result, 'Dependentes').cents, 72600);
    });

    test('segundo dependente até seis recebe majoração 300', () {
      final result = engine.calculate(
        _simulation(gross: 5000000, dependentAges: const [10, 5]),
      );
      expect(_credit(result, 'Dependentes').cents, 150000);
    });
  });

  group('golden — limite global', () {
    for (final taxable in const [
      834200,
      834201,
      2000000,
      5000000,
      7999999,
      8000000,
    ]) {
      test('coletável ${taxable / 100}', () {
        final cap = engine.overallCreditCapForTaxableIncome(
          Money.fromCents(taxable),
        );
        expect(cap?.cents, _expectedOverallCap(rules, taxable, 0));
      });
    }

    test('três dependentes aumentam limite em 15%', () {
      const taxable = 5000000;
      final cap = engine.overallCreditCapForTaxableIncome(
        const Money.fromCents(taxable),
        dependents: 3,
      );
      expect(cap?.cents, _expectedOverallCap(rules, taxable, 3));
    });

    test('combinação é reduzida ao limite global', () {
      final result = engine.calculate(
        _simulationForTaxable(
          5000000,
          rules,
          health: 1000000,
          education: 1000000,
          rent: 1000000,
          careHomes: 1000000,
          ppr: 200000,
        ),
      );
      expect(result.warnings.join(' '), contains('limite global'));
      expect(
        result.creditBreakdown.map((e) => e.label),
        contains('Limite global das deduções'),
      );
    });
  });

  group('golden — solidariedade', () {
    for (final item in const [
      (7999999, 0),
      (8000000, 0),
      (8000001, 0),
      (24999999, 425000),
      (25000000, 425000),
      (25000001, 425000),
      (25000020, 425001),
    ]) {
      test('${item.$1} cêntimos coletáveis', () {
        final result = engine.calculate(_simulationForTaxable(item.$1, rules));
        expect(result.solidarityTax.cents, item.$2);
      });
    }
  });

  group('regressão e serialização', () {
    test('retenção superior produz reembolso exato', () {
      final result = engine.calculate(
        _simulation(
          gross: 3000000,
          socialSecurity: 330000,
          withholding: 600000,
        ),
      );
      expect(result.balance.cents, 118935);
    });

    test('serialização preserva quatro IVA', () {
      final restored = TaxSimulation.decode(
        _simulation(
          gross: 3000123,
          vat15: 111,
          vat30: 222,
          vat35: 333,
          vat100: 444,
        ).encode(),
      );
      expect(restored.deductions.invoiceVat15.cents, 111);
      expect(restored.deductions.invoiceVat30.cents, 222);
      expect(restored.deductions.invoiceVat35.cents, 333);
      expect(restored.deductions.invoiceVat100.cents, 444);
    });

    test('JSON não contém outras deduções', () {
      final json = jsonDecode(_simulation(gross: 3000000).encode()) as Map;
      expect(
        json['deductions'] as Map,
        isNot(contains('otherEligibleTaxCreditCents')),
      );
    });

    test('migra IVA antigo apenas para 15%', () {
      final input = DeductionInput.fromJson({'eligibleInvoiceVatCents': 1234});
      expect(input.invoiceVat15.cents, 1234);
      expect(input.invoiceVat30, Money.zero);
      expect(input.invoiceVat35, Money.zero);
      expect(input.invoiceVat100, Money.zero);
    });

    test('serialização preserva histórico objetivo IRS Jovem', () {
      final source = _simulation(gross: 3000000).copyWith(
        primaryIrsJovem: const IrsJovemAnswers(
          requested: true,
          taxSituationRegularized: true,
          historyConfirmedComplete: true,
          incomeHistory: [
            IrsJovemIncomeYear(
              year: 2026,
              hadCategoryAIncome: true,
              hadCategoryBIncome: false,
              wasDependent: false,
              residentInPortugal: true,
              usedIncompatibleRegime: false,
            ),
          ],
        ),
      );
      final restored = TaxSimulation.decode(source.encode());
      expect(restored.primaryIrsJovem.historyConfirmedComplete, isTrue);
      expect(restored.primaryIrsJovem.incomeHistory.single.year, 2026);
      expect(
        restored.primaryIrsJovem.incomeHistory.single.hadCategoryAIncome,
        isTrue,
      );
    });
  });
}

String _deltaLabel(int delta) => switch (delta) {
  -1 => '0,01 € abaixo',
  0 => 'limite exato',
  _ => '0,01 € acima',
};

int _expectedGrossTax(TaxRuleSet rules, int taxable) {
  if (taxable <= 0) return 0;
  for (var i = 0; i < rules.brackets.length; i++) {
    final bracket = rules.brackets[i];
    if (bracket.upperCents == null || taxable <= bracket.upperCents!) {
      if (i == 0) {
        return Money.mulDiv(taxable, bracket.marginalRatePpm, 1000000);
      }
      final lower = rules.brackets[i - 1].upperCents!;
      final base = Money.mulDiv(
        lower,
        rules.brackets[i - 1].averageRatePpm!,
        1000000,
      );
      return base +
          Money.mulDiv(taxable - lower, bracket.marginalRatePpm, 1000000);
    }
  }
  throw StateError('Tabela inválida');
}

int _lValue(TaxRuleSet rules) {
  final general = rules.me('generalExpenseLimitCents');
  final firstRate = rules.brackets.first.marginalRatePpm;
  final divisor = rules.me('lDivisorTenths');
  return rules.minimumExistenceReferenceCents -
      Money.mulDiv(general, 10000000, firstRate * divisor) +
      Money.mulDiv(rules.brackets.first.upperCents!, 10, divisor);
}

int _minimumExistenceCutoff(TaxRuleSet rules) => Money.mulDiv(
  rules.iasCents,
  rules.me('cutoffIasMultiplierTenths') * rules.me('months'),
  10,
);

int _expectedMinimumExistence(TaxRuleSet rules, int gross, int specific) {
  if (gross > _minimumExistenceCutoff(rules)) return 0;
  final reference = rules.minimumExistenceReferenceCents;
  final generalOverRate = Money.mulDiv(
    rules.me('generalExpenseLimitCents'),
    1000000,
    rules.brackets.first.marginalRatePpm,
  );
  final l = _lValue(rules);
  int allowance;
  if (gross <= reference) {
    allowance = reference - specific - generalOverRate;
  } else if (gross <= l) {
    allowance =
        reference -
        Money.mulDiv(
          gross - reference,
          rules.me('phaseTwoMultiplierPpm'),
          1000000,
        ) -
        specific -
        generalOverRate;
  } else {
    allowance =
        l -
        rules.brackets.first.upperCents! -
        Money.mulDiv(gross - l, rules.me('phaseThreeMultiplierPpm'), 1000000) -
        specific;
  }
  return allowance.clamp(0, (gross - specific).clamp(0, gross));
}

int? _expectedOverallCap(TaxRuleSet rules, int taxable, int dependents) {
  final first = rules.brackets.first.upperCents!;
  if (taxable <= first) return null;
  final upper = rules.d('overallUpperIncomeCents');
  int cap;
  if (taxable >= upper) {
    cap = rules.d('overallHighIncomeCapCents');
  } else {
    final high = rules.d('overallHighIncomeCapCents');
    cap =
        high +
        Money.mulDiv(
          rules.d('overallLowIncomeCapCents') - high,
          upper - taxable,
          upper - first,
        );
  }
  if (dependents >= 3) {
    cap += Money.mulDiv(
      cap,
      rules.d('largeFamilyIncreasePpmPerDependent') * dependents,
      1000000,
    );
  }
  return cap;
}

Money _credit(TaxResult result, String label) =>
    result.creditBreakdown.singleWhere((line) => line.label == label).amount;

TaxSimulation _simulationForTaxable(
  int taxable,
  TaxRuleSet rules, {
  List<int> dependentAges = const [],
  int health = 0,
  int education = 0,
  int rent = 0,
  int careHomes = 0,
  int ppr = 0,
}) => _simulation(
  gross: taxable + rules.employmentSpecificDeductionCents,
  dependentAges: dependentAges,
  health: health,
  education: education,
  rent: rent,
  careHomes: careHomes,
  ppr: ppr,
);

TaxSimulation _simulation({
  required int gross,
  int withholding = 0,
  int socialSecurity = 0,
  int general = 0,
  int health = 0,
  int education = 0,
  int rent = 0,
  int careHomes = 0,
  int vat15 = 0,
  int vat30 = 0,
  int vat35 = 0,
  int vat100 = 0,
  int ppr = 0,
  int age = 30,
  List<int> dependentAges = const [],
}) => TaxSimulation(
  id: 'fixture',
  name: 'Fixture',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  profile: TaxpayerProfile(
    taxYear: 2026,
    age: age,
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
  deductions: DeductionInput(
    general: Money.fromCents(general),
    health: Money.fromCents(health),
    education: Money.fromCents(education),
    rent: Money.fromCents(rent),
    careHomes: Money.fromCents(careHomes),
    invoiceVat15: Money.fromCents(vat15),
    invoiceVat30: Money.fromCents(vat30),
    invoiceVat35: Money.fromCents(vat35),
    invoiceVat100: Money.fromCents(vat100),
    ppr: Money.fromCents(ppr),
  ),
);
