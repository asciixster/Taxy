import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/domain/models.dart';
import 'package:taxy_pt/domain/money.dart';
import 'package:taxy_pt/tax_engine/tax_engine.dart';
import 'package:taxy_pt/tax_engine/tax_rules.dart';

void main() {
  late TaxEngine engine;

  setUpAll(() {
    engine = TaxEngine(
      TaxRuleSet.fromJsonString(
        File('assets/tax_rules/2026.json').readAsStringSync(),
      ),
    );
  });

  test('scope standard é suportado', () {
    expect(engine.calculate(_simulation()).available, isTrue);
  });

  for (final item in const [
    (CivilStatus.married, 'Casados'),
    (CivilStatus.deFacto, 'Unidos de facto'),
  ]) {
    test('${item.$2} falha mesmo em tributação separada', () {
      final result = engine.calculate(_simulation(civilStatus: item.$1));
      expect(result.available, isFalse);
      expect(result.warnings.join(' '), contains('NEEDS_VERIFICATION'));
    });
  }

  test('tributação conjunta falha', () {
    expect(
      engine.calculate(_simulation(filingMode: FilingMode.joint)).available,
      isFalse,
    );
  });

  test('residência parcial falha', () {
    expect(
      engine.calculate(_simulation(fullYearResident: false)).available,
      isFalse,
    );
  });

  for (final region in [TaxRegion.madeira, TaxRegion.azores]) {
    test('${region.name} falha antes de calcular', () {
      final result = engine.calculate(_simulation(region: region));
      expect(result.available, isFalse);
      expect(result.taxDue, Money.zero);
    });
  }

  test('single com dependentes sem confirmação monoparental falha', () {
    final result = engine.calculate(
      _simulation(dependentAges: const [8], singleParent: false),
    );
    expect(result.available, isFalse);
    expect(result.warnings.single, contains('monoparental'));
  });

  test('flag monoparental sem dependentes falha', () {
    expect(
      engine.calculate(_simulation(singleParent: true)).available,
      isFalse,
    );
  });

  final flags = <(String, TaxSituationFlags)>[
    ('IRS Jovem', const TaxSituationFlags(irsJovem: true)),
    ('Categoria B', const TaxSituationFlags(categoryB: true)),
    ('pensões', const TaxSituationFlags(pensions: true)),
    ('rendimentos estrangeiros', const TaxSituationFlags(foreignIncome: true)),
    ('rendimentos de capitais', const TaxSituationFlags(capitalIncome: true)),
    ('rendimentos prediais', const TaxSituationFlags(propertyIncome: true)),
    ('mais-valias', const TaxSituationFlags(capitalGains: true)),
    ('deficiência', const TaxSituationFlags(disability: true)),
    ('estudante deslocado', const TaxSituationFlags(displacedStudent: true)),
    ('guarda partilhada', const TaxSituationFlags(sharedCustody: true)),
    (
      'outra situação especial',
      const TaxSituationFlags(otherSpecialSituation: true),
    ),
  ];
  for (final item in flags) {
    test('${item.$1} falha fechado', () {
      final result = engine.calculate(_simulation(situations: item.$2));
      expect(result.available, isFalse);
      expect(result.balance, Money.zero);
      expect(result.breakdown, isEmpty);
      expect(result.assumptions.single, contains('bloqueado'));
    });
  }

  test('valor monetário negativo falha fechado', () {
    final result = engine.calculate(_simulation(gross: -1));
    expect(result.available, isFalse);
    expect(result.warnings.join(' '), contains('negativos'));
  });
}

TaxSimulation _simulation({
  int gross = 3000000,
  CivilStatus civilStatus = CivilStatus.single,
  FilingMode filingMode = FilingMode.separate,
  bool fullYearResident = true,
  TaxRegion region = TaxRegion.continent,
  List<int> dependentAges = const [],
  bool singleParent = false,
  TaxSituationFlags situations = const TaxSituationFlags(),
}) => TaxSimulation(
  id: 'scope',
  name: 'Scope',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  profile: TaxpayerProfile(
    taxYear: 2026,
    age: 30,
    civilStatus: civilStatus,
    dependentAges: dependentAges,
    fullYearResident: fullYearResident,
    region: region,
    filingMode: filingMode,
    isSingleParentHousehold: singleParent,
  ),
  income: EmploymentIncome(
    entryMode: IncomeEntryMode.annual,
    gross: Money.fromCents(gross),
    withholding: Money.zero,
    socialSecurity: const Money.fromCents(330000),
  ),
  deductions: const DeductionInput(),
  situations: situations,
);
