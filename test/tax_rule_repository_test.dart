import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/domain/money.dart';
import 'package:taxy_pt/tax_engine/tax_engine.dart';
import 'package:taxy_pt/tax_engine/tax_rules.dart';

void main() {
  late Map<String, TaxRuleSet> sets;

  setUpAll(() async {
    final repository = TaxRuleRepository((path) => File(path).readAsString());
    sets = {
      '2025-continent': await repository.load(2025, 'continent'),
      '2026-continent': await repository.load(2026, 'continent'),
      '2026-madeira': await repository.load(2026, 'madeira'),
      '2026-azores': await repository.load(2026, 'azores'),
    };
  });

  for (final key in const [
    '2025-continent',
    '2026-continent',
    '2026-madeira',
    '2026-azores',
  ]) {
    for (var boundaryIndex = 0; boundaryIndex < 8; boundaryIndex++) {
      for (final offset in const [-1, 0, 1]) {
        test('$key escalão ${boundaryIndex + 1} offset $offset cêntimo', () {
          final rules = sets[key]!;
          final engine = TaxEngine(rules);
          final boundary = rules.brackets[boundaryIndex].upperCents!;
          final taxable = boundary + offset;
          expect(
            engine.grossTaxForTaxableIncome(Money.fromCents(taxable)).cents,
            _expectedTax(rules, taxable),
          );
        });
      }
    }
  }

  test('repository resolves version and jurisdiction explicitly', () {
    expect(sets['2025-continent']!.rulesVersion, '2025.3.1');
    expect(sets['2026-continent']!.jurisdiction, 'CONTINENT');
    expect(sets['2026-madeira']!.jurisdiction, 'MADEIRA');
    expect(sets['2026-azores']!.jurisdiction, 'AZORES');
  });

  test('Madeira and Azores are lower than continent at all boundaries', () {
    final continent = TaxEngine(sets['2026-continent']!);
    for (final region in ['2026-madeira', '2026-azores']) {
      final regional = TaxEngine(sets[region]!);
      for (final bracket in sets['2026-continent']!.brackets.take(8)) {
        final taxable = Money.fromCents(bracket.upperCents!);
        expect(
          regional.grossTaxForTaxableIncome(taxable).cents,
          lessThan(continent.grossTaxForTaxableIncome(taxable).cents),
        );
      }
    }
  });

  test('2025 descriptor uses official IAS and specific deduction', () {
    final rules = sets['2025-continent']!;
    expect(rules.iasCents, 52250);
    expect(rules.employmentSpecificDeductionCents, 446215);
    expect(rules.minimumExistenceReferenceCents, 1218000);
    expect(rules.d('rentFloorCapCents'), 70000);
    expect(rules.d('rentTransitionLowCapCents'), 100000);
  });

  test('2026 rent caps reflect transitional rule and 900 euro floor', () {
    final rules = sets['2026-continent']!;
    expect(rules.d('rentFloorCapCents'), 90000);
    expect(rules.d('rentTransitionBaseCapCents'), 75000);
    expect(rules.d('rentTransitionLowCapCents'), 105000);
  });

  test('limite de rendas é isolado e calculado por ano', () {
    final engine2025 = TaxEngine(sets['2025-continent']!);
    final engine2026 = TaxEngine(sets['2026-continent']!);
    expect(
      engine2025
          .rentCreditCapForTaxableIncome(const Money.fromCents(4000000))
          .cents,
      70000,
    );
    expect(
      engine2026
          .rentCreditCapForTaxableIncome(const Money.fromCents(4000000))
          .cents,
      90000,
    );
    expect(
      engine2026
          .rentCreditCapForTaxableIncome(const Money.fromCents(834200))
          .cents,
      105000,
    );
  });

  test('tabelas regionais 2026 coincidem com os valores oficiais fixos', () {
    expect(sets['2026-madeira']!.brackets.map((b) => b.marginalRatePpm), const [
      87500,
      109900,
      148400,
      168700,
      217700,
      244300,
      301700,
      312200,
      336000,
    ]);
    expect(sets['2026-madeira']!.brackets.map((b) => b.averageRatePpm), const [
      87500,
      95050,
      110760,
      123940,
      144060,
      175910,
      185300,
      243990,
      null,
    ]);
    expect(sets['2026-azores']!.brackets.map((b) => b.averageRatePpm), const [
      87500,
      95050,
      110760,
      123940,
      144050,
      175910,
      185300,
      243990,
      null,
    ]);
  });

  test('tabela nacional 2025 coincide com os valores oficiais fixos', () {
    final rules = sets['2025-continent']!;
    expect(rules.brackets.map((b) => b.upperCents), const [
      805900,
      1216000,
      1723300,
      2230600,
      2840000,
      4162900,
      4498700,
      8369600,
      null,
    ]);
    expect(rules.brackets.map((b) => b.marginalRatePpm), const [
      125000,
      160000,
      215000,
      244000,
      314000,
      349000,
      431000,
      446000,
      480000,
    ]);
  });

  test('2025 is self-contained and never loads the 2026 base asset', () async {
    final loadedPaths = <String>[];
    final repository = TaxRuleRepository((path) async {
      loadedPaths.add(path);
      return File(path).readAsString();
    });
    final rules2025 = await repository.load(2025, 'continent');
    expect(rules2025.taxYear, 2025);
    expect(loadedPaths, contains('assets/tax_rules/2025/base.json'));
    expect(loadedPaths, isNot(contains('assets/tax_rules/2026.json')));
  });

  test('alterar a base 2026 em memória não contamina 2025', () async {
    final repository = TaxRuleRepository((path) async {
      if (path == 'assets/tax_rules/2026.json') {
        return File(path)
            .readAsStringSync()
            .replaceFirst('"iasCents": 53713', '"iasCents": 99999');
      }
      return File(path).readAsString();
    });
    expect((await repository.load(2025, 'continent')).iasCents, 52250);
    expect((await repository.load(2026, 'continent')).iasCents, 99999);
  });

  test('Madeira e Açores 2025 não usam fallback do Continente', () async {
    final repository = TaxRuleRepository((path) => File(path).readAsString());
    await expectLater(
      repository.load(2025, 'madeira'),
      throwsA(isA<FileSystemException>()),
    );
    await expectLater(
      repository.load(2025, 'azores'),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('descritor com ano ou jurisdição divergente é recusado', () async {
    final repository = TaxRuleRepository((path) async {
      if (path.endsWith('/2025/continent.json')) {
        return File('assets/tax_rules/2026/continent.json').readAsString();
      }
      return File(path).readAsString();
    });
    await expectLater(
      repository.load(2025, 'continent'),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'descritor não verificado ou com schema incompatível é recusado',
    () async {
      for (final mutation in [
        (String value) => value.replaceFirst(
          '"status": "VERIFIED"',
          '"status": "NEEDS_VERIFICATION"',
        ),
        (String value) =>
            value.replaceFirst('"schemaVersion": 3', '"schemaVersion": 999'),
      ]) {
        final repository = TaxRuleRepository((path) async {
          final value = await File(path).readAsString();
          return path.endsWith('/2026/continent.json')
              ? mutation(value)
              : value;
        });
        await expectLater(
          repository.load(2026, 'continent'),
          throwsA(isA<FormatException>()),
        );
      }
    },
  );

  test('base fiscal de outro ano é recusada sem fallback', () async {
    final repository = TaxRuleRepository((path) async {
      final value = await File(path).readAsString();
      if (path == 'assets/tax_rules/2025/base.json') {
        return value.replaceFirst('"taxYear": 2025', '"taxYear": 2026');
      }
      return value;
    });
    await expectLater(
      repository.load(2025, 'continent'),
      throwsA(isA<FormatException>()),
    );
  });

  test('ficheiro fiscal inexistente produz erro explícito', () async {
    final repository = TaxRuleRepository((path) => File(path).readAsString());
    await expectLater(
      repository.load(2027, 'continent'),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('scope executável inclui os agregados standard suportados', () {
    expect(
      sets['2026-continent']!.supportedScope.householdTypes,
      containsAll(const {
        'SINGLE_NO_DEPENDENTS',
        'SINGLE_PARENT_STANDARD',
        'COUPLE_STANDARD',
        'COUPLE_WITH_DEPENDENTS_STANDARD',
      }),
    );
  });
}

int _expectedTax(TaxRuleSet rules, int taxable) {
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
  throw StateError('Tabela incompleta');
}
