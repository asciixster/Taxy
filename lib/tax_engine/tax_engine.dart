import '../domain/models.dart';
import '../domain/money.dart';
import 'tax_rules.dart';

final class TaxEngine {
  const TaxEngine(this.rules);
  final TaxRuleSet rules;

  /// Exposto para auditoria e testes de fronteira dos escalões.
  Money grossTaxForTaxableIncome(Money taxableIncome) => _generalTax(taxableIncome);

  TaxResult calculate(TaxSimulation simulation) {
    final warnings = <String>[];
    final assumptions = <String>[
      'Apenas rendimentos de trabalho dependente (Categoria A).',
      'Residente fiscal em Portugal durante todo o ano.',
      'Regras do Continente para ${rules.taxYear}, versão ${rules.rulesVersion}.',
      'Despesas introduzidas são elegíveis, documentadas e não reembolsadas.',
      'Não inclui IRS Jovem, deficiência, pensões de alimentos ou rendimentos não indicados.',
    ];
    final profile = simulation.profile;
    final input = simulation.income;

    if (profile.taxYear != rules.taxYear) {
      return _unavailable(simulation, 'As regras de ${profile.taxYear} ainda não estão validadas.');
    }
    if (!profile.fullYearResident) {
      return _unavailable(simulation, 'Residência parcial exige regras adicionais (NEEDS_VERIFICATION).');
    }
    if (profile.region != TaxRegion.continent) {
      return _unavailable(simulation, 'Madeira e Açores aguardam tabelas regionais validadas (NEEDS_VERIFICATION).');
    }
    if (profile.filingMode == FilingMode.joint) {
      return _unavailable(simulation, 'Tributação conjunta está preparada no modelo, mas ainda não validada.');
    }
    if (input.gross.cents < 0 || input.withholding.cents < 0 || input.socialSecurity.cents < 0) {
      return _unavailable(simulation, 'Os valores monetários não podem ser negativos.');
    }

    final specific = moneyMax(
      Money.fromCents(rules.employmentSpecificDeductionCents),
      input.socialSecurity,
    ).min(input.gross);
    final minimumAllowance = _minimumExistenceAllowance(input.gross, specific);
    final taxable = (input.gross - specific - minimumAllowance).max(Money.zero);
    final grossTax = _generalTax(taxable);
    final solidarity = _solidarityTax(taxable);

    final credits = _credits(simulation, taxable, grossTax, warnings);
    final regularTax = (grossTax - credits).max(Money.zero);
    final taxDue = regularTax + solidarity;
    final balance = input.withholding - taxDue;

    return TaxResult(
      available: true,
      grossIncome: input.gross,
      specificDeduction: specific,
      minimumExistenceAllowance: minimumAllowance,
      taxableIncome: taxable,
      grossTax: grossTax,
      taxCredits: credits,
      solidarityTax: solidarity,
      taxDue: taxDue,
      withholding: input.withholding,
      balance: balance,
      warnings: warnings,
      assumptions: assumptions,
      breakdown: [
        TaxBreakdown('Rendimento bruto', input.gross,
          'Tudo o que indicou ter recebido antes de impostos e contribuições.'),
        TaxBreakdown('Dedução específica', -specific,
          'Dedução própria do trabalho dependente. Considerámos o maior valor entre 4.587,09 € e as contribuições obrigatórias indicadas.'),
        if (minimumAllowance.cents > 0)
          TaxBreakdown('Mínimo de existência', -minimumAllowance,
            'Abatimento que protege rendimentos mais baixos, calculado segundo o artigo 70.º do Código do IRS.'),
        TaxBreakdown('Rendimento coletável', taxable,
          'Valor ao qual aplicámos os escalões progressivos de IRS.'),
        TaxBreakdown('Imposto antes de deduções', grossTax,
          'Resultado da aplicação progressiva das taxas gerais de 2026.'),
        TaxBreakdown('Deduções à coleta', -credits,
          'Benefícios por dependentes e despesas elegíveis, respeitando limites individuais e o limite conjunto.'),
        if (solidarity.cents > 0)
          TaxBreakdown('Adicional de solidariedade', solidarity,
            'Adicional aplicável à parte do rendimento coletável superior a 80.000 €.'),
        TaxBreakdown('Retenções na fonte', -input.withholding,
          'IRS que já foi descontado ao longo do ano e é comparado com o imposto devido.'),
      ],
    );
  }

  Money _minimumExistenceAllowance(Money gross, Money specific) {
    final reference = rules.minimumExistenceReferenceCents;
    final generalLimit = rules.me('generalExpenseLimitCents');
    final firstRate = rules.brackets.first.marginalRatePpm;
    final firstLimit = rules.brackets.first.upperCents!;
    final divisorTenths = rules.me('lDivisorTenths');

    final generalOverRate = Money.mulDiv(generalLimit, 1000000, firstRate);
    final lValue = reference -
        Money.mulDiv(generalLimit, 10000000, firstRate * divisorTenths) +
        Money.mulDiv(firstLimit, 10, divisorTenths);
    final cutoff = Money.mulDiv(
      rules.iasCents,
      rules.me('cutoffIasMultiplierTenths') * rules.me('months'),
      10,
    );
    if (gross.cents > cutoff) return Money.zero;

    int allowance;
    if (gross.cents <= reference) {
      allowance = reference - specific.cents - generalOverRate;
    } else if (gross.cents <= lValue) {
      allowance = reference -
          Money.mulDiv(gross.cents - reference, rules.me('phaseTwoMultiplierPpm'), 1000000) -
          specific.cents - generalOverRate;
    } else {
      allowance = lValue - firstLimit -
          Money.mulDiv(gross.cents - lValue, rules.me('phaseThreeMultiplierPpm'), 1000000) -
          specific.cents;
    }
    final maximum = (gross - specific).max(Money.zero).cents;
    return Money.fromCents(allowance.clamp(0, maximum));
  }

  Money _generalTax(Money taxable) {
    if (taxable.cents <= 0) return Money.zero;
    for (var i = 0; i < rules.brackets.length; i++) {
      final bracket = rules.brackets[i];
      if (bracket.upperCents == null || taxable.cents <= bracket.upperCents!) {
        if (i == 0) return taxable.timesPpm(bracket.marginalRatePpm);
        final lower = rules.brackets[i - 1].upperCents!;
        final lowerTax = Money.fromCents(lower)
            .timesPpm(rules.brackets[i - 1].averageRatePpm!);
        final excessTax = Money.fromCents(taxable.cents - lower)
            .timesPpm(bracket.marginalRatePpm);
        return lowerTax + excessTax;
      }
    }
    throw StateError('Tabela de escalões incompleta');
  }

  Money _solidarityTax(Money taxable) {
    final first = rules.s('firstThresholdCents');
    final second = rules.s('secondThresholdCents');
    if (taxable.cents <= first) return Money.zero;
    final firstSlice = Money.fromCents((taxable.cents.clamp(first, second)) - first)
        .timesPpm(rules.s('firstRatePpm'));
    final secondSlice = taxable.cents > second
        ? Money.fromCents(taxable.cents - second).timesPpm(rules.s('secondRatePpm'))
        : Money.zero;
    return firstSlice + secondSlice;
  }

  Money _credits(TaxSimulation simulation, Money taxable, Money grossTax,
      List<String> warnings) {
    final p = simulation.profile;
    final d = simulation.deductions;
    var dependentCredit = Money.zero;
    for (var i = 0; i < p.dependentAges.length; i++) {
      final age = p.dependentAges[i];
      var cents = rules.d('dependentBaseCents');
      if (i > 0 && age <= 6) {
        cents += rules.d('secondAndLaterUnderSixExtraCents');
      } else if (age <= 3) {
        cents += rules.d('dependentUnderThreeExtraCents');
      }
      dependentCredit += Money.fromCents(cents);
    }

    final general = _limited(d.general, rules.d('generalRatePpm'),
        rules.d('generalCapPerTaxpayerCents'), 'despesas gerais', warnings);
    final health = _limited(d.health, rules.d('healthRatePpm'),
        rules.d('healthCapCents'), 'saúde', warnings);
    final education = _limited(d.education, rules.d('educationRatePpm'),
        rules.d('educationCapCents'), 'educação', warnings);
    final care = _limited(d.careHomes, rules.d('careHomeRatePpm'),
        rules.d('careHomeCapCents'), 'lares', warnings);
    final vat = _limited(d.eligibleInvoiceVat, rules.d('invoiceVatRatePpm'),
        rules.d('invoiceVatCapCents'), 'IVA de faturas elegíveis', warnings);
    final rent = _limited(d.rent, rules.d('rentRatePpm'),
        _rentCap(taxable), 'rendas', warnings);
    final pprCap = p.age < 35
        ? rules.d('pprUnder35CapCents')
        : (p.age <= 50 ? rules.d('ppr35To50CapCents') : rules.d('pprOver50CapCents'));
    final ppr = _limited(d.ppr, rules.d('pprRatePpm'), pprCap, 'PPR', warnings);

    final limitedGroupRaw = health + education + care + vat + rent + ppr +
        d.otherEligibleTaxCredit;
    final overallCap = _overallCreditCap(taxable, p.dependents);
    final limitedGroup = overallCap == null ? limitedGroupRaw : limitedGroupRaw.min(overallCap);
    if (overallCap != null && limitedGroupRaw.cents > overallCap.cents) {
      warnings.add('O conjunto de deduções sujeito ao limite global foi reduzido de '
          '${limitedGroupRaw.format()} para ${overallCap.format()}.');
    }
    return (dependentCredit + general + limitedGroup).min(grossTax);
  }

  Money _limited(Money expense, int rate, int cap, String label,
      List<String> warnings) {
    final calculated = expense.timesPpm(rate);
    if (calculated.cents > cap) {
      warnings.add('Em $label, a dedução calculada de ${calculated.format()} '
          'foi limitada a ${Money.fromCents(cap).format()}.');
    }
    return calculated.min(Money.fromCents(cap));
  }

  int _rentCap(Money taxable) {
    final first = rules.brackets.first.upperCents!;
    final upper = rules.d('rentTransitionUpperIncomeCents');
    final lowCap = rules.d('rentTransitionLowCapCents');
    final transitionBase = rules.d('rentTransitionBaseCapCents');
    int transitional;
    if (taxable.cents <= first) {
      transitional = lowCap;
    } else if (taxable.cents <= upper) {
      transitional = transitionBase + Money.mulDiv(
        lowCap - transitionBase,
        upper - taxable.cents,
        upper - first,
      );
    } else {
      transitional = transitionBase;
    }
    return intMax(transitional, rules.d('rent2026FloorCapCents'));
  }

  Money? _overallCreditCap(Money taxable, int dependents) {
    final first = rules.brackets.first.upperCents!;
    if (taxable.cents <= first) return null;
    final upper = rules.d('overallUpperIncomeCents');
    final highCap = rules.d('overallHighIncomeCapCents');
    int cap;
    if (taxable.cents >= upper) {
      cap = highCap;
    } else {
      final lowCap = rules.d('overallLowIncomeCapCents');
      cap = highCap + Money.mulDiv(lowCap - highCap, upper - taxable.cents, upper - first);
    }
    if (dependents >= 3) {
      cap += Money.mulDiv(cap, rules.d('largeFamilyIncreasePpmPerDependent') * dependents, 1000000);
    }
    return Money.fromCents(cap);
  }

  TaxResult _unavailable(TaxSimulation simulation, String warning) => TaxResult(
    available: false,
    grossIncome: simulation.income.gross,
    specificDeduction: Money.zero,
    minimumExistenceAllowance: Money.zero,
    taxableIncome: Money.zero,
    grossTax: Money.zero,
    taxCredits: Money.zero,
    solidarityTax: Money.zero,
    taxDue: Money.zero,
    withholding: simulation.income.withholding,
    balance: Money.zero,
    breakdown: const [],
    warnings: [warning],
    assumptions: const ['O cálculo foi bloqueado para evitar apresentar um valor não validado.'],
  );
}
