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
    expect(sets['2025-continent']!.rulesVersion, '2025.3.0');
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
