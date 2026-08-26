import '../domain/models.dart';
import '../domain/money.dart';
import 'tax_rules.dart';
import 'supported_scope.dart';

final class TaxEngine {
  const TaxEngine(this.rules);
  final TaxRuleSet rules;

  /// Exposto para auditoria e testes de fronteira dos escalões.
  Money grossTaxForTaxableIncome(Money taxableIncome) =>
      _generalTaxDetail(taxableIncome).tax;

  /// Exposto para auditoria das fronteiras do limite global de deduções.
  Money? overallCreditCapForTaxableIncome(
    Money taxableIncome, {
    int dependents = 0,
  }) => _overallCreditCap(taxableIncome, dependents);

  TaxResult calculate(TaxSimulation simulation) {
    final warnings = <String>[];
    final assumptions = <String>[
      'Apenas rendimentos de trabalho dependente (Categoria A).',
      'Residente fiscal em Portugal durante todo o ano.',
      'Regras do Continente para ${rules.taxYear}, versão ${rules.rulesVersion}.',
      'Despesas introduzidas são elegíveis, documentadas e não reembolsadas.',
      'Educação limitada ao regime standard; estudante deslocado e majorações territoriais estão excluídos.',
      'Não inclui IRS Jovem, deficiência, pensões de alimentos ou rendimentos não indicados.',
    ];
    final input = simulation.income;
    final scopeIssues = SupportedScopeValidator(rules.taxYear)
        .validate(simulation);
    if (scopeIssues.isNotEmpty) {
      return _unavailable(
        simulation,
        scopeIssues.map((issue) => issue.message).toList(growable: false),
      );
    }

    final specific = moneyMax(
      Money.fromCents(rules.employmentSpecificDeductionCents),
      input.socialSecurity,
    ).min(input.gross);
    final minimumAllowance = _minimumExistenceAllowance(input.gross, specific);
    final taxable = (input.gross - specific - minimumAllowance).max(Money.zero);
    final bracket = _generalTaxDetail(taxable);
    final grossTax = bracket.tax;
    final solidarity = _solidarityTax(taxable);

    final credits = _credits(simulation, taxable, grossTax, warnings);
    final regularTax = (grossTax - credits.total).max(Money.zero);
    final taxDue = regularTax + solidarity;
    final balance = input.withholding - taxDue;

    return TaxResult(
      available: true,
      grossIncome: input.gross,
      specificDeduction: specific,
      minimumExistenceAllowance: minimumAllowance,
      taxableIncome: taxable,
      grossTax: grossTax,
      taxCredits: credits.total,
      solidarityTax: solidarity,
      taxDue: taxDue,
      withholding: input.withholding,
      balance: balance,
      warnings: warnings,
      assumptions: assumptions,
      creditBreakdown: credits.breakdown,
      bracketBaseTax: bracket.baseTax,
      bracketExcess: bracket.excess,
      marginalRatePpm: bracket.ratePpm,
      overallDeductionsCap: credits.overallCap,
      breakdown: [
        TaxBreakdown(
          'Rendimento bruto',
          input.gross,
          'Tudo o que indicou ter recebido antes de impostos e contribuições.',
        ),
        TaxBreakdown(
          'Dedução específica',
          -specific,
          'Dedução própria do trabalho dependente. Considerámos o maior valor entre ${Money.fromCents(rules.employmentSpecificDeductionCents).format()} e as contribuições obrigatórias indicadas.',
        ),
        if (minimumAllowance.cents > 0)
          TaxBreakdown(
            'Mínimo de existência',
            -minimumAllowance,
            'Abatimento que protege rendimentos mais baixos, calculado segundo o artigo 70.º do Código do IRS.',
          ),
        TaxBreakdown(
          'Rendimento coletável',
          taxable,
          'Valor ao qual aplicámos os escalões progressivos de IRS.',
        ),
        TaxBreakdown(
          'Imposto antes de deduções',
          grossTax,
          'Resultado da aplicação progressiva das taxas gerais de 2026.',
        ),
        TaxBreakdown(
          'Deduções à coleta',
          -credits.total,
          'Benefícios por dependentes e despesas elegíveis, respeitando limites individuais e o limite conjunto.',
        ),
        if (solidarity.cents > 0)
          TaxBreakdown(
            'Adicional de solidariedade',
            solidarity,
            'Adicional aplicável à parte do rendimento coletável superior a 80.000 €.',
          ),
        TaxBreakdown(
          'Retenções na fonte',
          -input.withholding,
          'IRS que já foi descontado ao longo do ano e é comparado com o imposto devido.',
        ),
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
    final lValue =
        reference -
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
      allowance =
          reference -
          Money.mulDiv(
            gross.cents - reference,
            rules.me('phaseTwoMultiplierPpm'),
            1000000,
          ) -
          specific.cents -
          generalOverRate;
    } else {
      allowance =
          lValue -
          firstLimit -
          Money.mulDiv(
            gross.cents - lValue,
            rules.me('phaseThreeMultiplierPpm'),
            1000000,
          ) -
          specific.cents;
    }
    final maximum = (gross - specific).max(Money.zero).cents;
    return Money.fromCents(allowance.clamp(0, maximum));
  }

  ({Money tax, Money baseTax, Money excess, int ratePpm}) _generalTaxDetail(
    Money taxable,
  ) {
    if (taxable.cents <= 0) {
      return (
        tax: Money.zero,
        baseTax: Money.zero,
        excess: Money.zero,
        ratePpm: 0,
      );
    }
    for (var i = 0; i < rules.brackets.length; i++) {
      final bracket = rules.brackets[i];
      if (bracket.upperCents == null || taxable.cents <= bracket.upperCents!) {
        if (i == 0) {
          return (
            tax: taxable.timesPpm(bracket.marginalRatePpm),
            baseTax: Money.zero,
            excess: taxable,
            ratePpm: bracket.marginalRatePpm,
          );
        }
        final lower = rules.brackets[i - 1].upperCents!;
        final lowerTax = Money.fromCents(lower)
            .timesPpm(rules.brackets[i - 1].averageRatePpm!);
        final excess = Money.fromCents(taxable.cents - lower);
        final excessTax = excess.timesPpm(bracket.marginalRatePpm);
        return (
          tax: lowerTax + excessTax,
          baseTax: lowerTax,
          excess: excess,
          ratePpm: bracket.marginalRatePpm,
        );
      }
    }
    throw StateError('Tabela de escalões incompleta');
  }

  Money _solidarityTax(Money taxable) {
    final first = rules.s('firstThresholdCents');
    final second = rules.s('secondThresholdCents');
    if (taxable.cents <= first) return Money.zero;
    final firstSlice = Money.fromCents(
      (taxable.cents.clamp(first, second)) - first,
    ).timesPpm(rules.s('firstRatePpm'));
    final secondSlice = taxable.cents > second
        ? Money.fromCents(taxable.cents - second)
              .timesPpm(rules.s('secondRatePpm'))
        : Money.zero;
    return firstSlice + secondSlice;
  }

  ({Money total, List<TaxBreakdown> breakdown, Money? overallCap}) _credits(
    TaxSimulation simulation,
    Money taxable,
    Money grossTax,
    List<String> warnings,
  ) {
    final p = simulation.profile;
    final d = simulation.deductions;
    var dependentCredit = Money.zero;
    // A lista é canonicalizada do mais velho para o mais novo. Assim a
    // majoração do segundo dependente e seguintes nunca depende da ordem de UI.
    final ages = [...p.dependentAges]..sort((a, b) => b.compareTo(a));
    for (var i = 0; i < ages.length; i++) {
      final age = ages[i];
      var cents = rules.d('dependentBaseCents');
      if (i > 0 && age <= 6) {
        cents += rules.d('secondAndLaterUnderSixExtraCents');
      } else if (age <= 3) {
        cents += rules.d('dependentUnderThreeExtraCents');
      }
      dependentCredit += Money.fromCents(cents);
    }

    final generalRate = p.isSingleParentHousehold
        ? rules.d('generalSingleParentRatePpm')
        : rules.d('generalRatePpm');
    final generalCap = p.isSingleParentHousehold
        ? rules.d('generalSingleParentCapCents')
        : rules.d('generalCapPerTaxpayerCents');
    final general = _limited(
      d.general,
      generalRate,
      generalCap,
      'despesas gerais',
      warnings,
    );
    final health = _limited(
      d.health,
      rules.d('healthRatePpm'),
      rules.d('healthCapCents'),
      'saúde',
      warnings,
    );
    final education = _limited(
      d.education,
      rules.d('educationRatePpm'),
      rules.d('educationCapCents'),
      'educação',
      warnings,
    );
    final care = _limited(
      d.careHomes,
      rules.d('careHomeRatePpm'),
      rules.d('careHomeCapCents'),
      'lares',
      warnings,
    );
    final vat15 = d.invoiceVat15.timesPpm(rules.d('invoiceVat15RatePpm'));
    final vat30 = d.invoiceVat30.timesPpm(rules.d('invoiceVat30RatePpm'));
    final vat35 = d.invoiceVat35.timesPpm(rules.d('invoiceVat35RatePpm'));
    final vat100 = d.invoiceVat100.timesPpm(rules.d('invoiceVat100RatePpm'));
    final vatRaw = vat15 + vat30 + vat35 + vat100;
    final vatCap = Money.fromCents(rules.d('invoiceVatCapCents'));
    final vat = vatRaw.min(vatCap);
    if (vatRaw.cents > vatCap.cents) {
      warnings.add(
        'A dedução conjunta de IVA foi limitada de '
        '${vatRaw.format()} para ${vatCap.format()}.',
      );
    }
    final rent = _limited(
      d.rent,
      rules.d('rentRatePpm'),
      _rentCap(taxable),
      'rendas',
      warnings,
    );
    final pprCap = p.age < 35
        ? rules.d('pprUnder35CapCents')
        : (p.age <= 50
              ? rules.d('ppr35To50CapCents')
              : rules.d('pprOver50CapCents'));
    final ppr = _limited(d.ppr, rules.d('pprRatePpm'), pprCap, 'PPR', warnings);

    final limitedGroupRaw = health + education + care + vat + rent + ppr;
    final overallCap = _overallCreditCap(taxable, p.dependents);
    final limitedGroup = overallCap == null
        ? limitedGroupRaw
        : limitedGroupRaw.min(overallCap);
    if (overallCap != null && limitedGroupRaw.cents > overallCap.cents) {
      warnings.add(
        'O conjunto de deduções sujeito ao limite global foi reduzido de '
        '${limitedGroupRaw.format()} para ${overallCap.format()}.',
      );
    }
    final total = (dependentCredit + general + limitedGroup).min(grossTax);
    final breakdown = <TaxBreakdown>[
      TaxBreakdown(
        'Dependentes',
        dependentCredit,
        'Dedução fixa e majorações etárias aplicáveis.',
      ),
      TaxBreakdown(
        'Despesas gerais',
        general,
        p.isSingleParentHousehold
            ? 'Regime declarado de família monoparental.'
            : 'Regime standard do sujeito passivo.',
      ),
      TaxBreakdown(
        'Saúde',
        health,
        '15% das despesas elegíveis, dentro do limite.',
      ),
      TaxBreakdown(
        'Educação standard',
        education,
        'Apenas despesas standard; exclui estudante deslocado e majorações territoriais.',
      ),
      TaxBreakdown('Lares', care, 'Encargos elegíveis com lares.'),
      TaxBreakdown('Rendas', rent, 'Rendas elegíveis de habitação permanente.'),
      TaxBreakdown('PPR', ppr, 'Benefício fiscal do PPR conforme a idade.'),
      TaxBreakdown('IVA — taxa 15%', vat15, 'Setores do artigo 78.º-F, n.º 1.'),
      TaxBreakdown(
        'IVA — taxa 30%',
        vat30,
        'Atividades desportivas elegíveis.',
      ),
      TaxBreakdown(
        'IVA — taxa 35%',
        vat35,
        'Medicamentos de uso veterinário elegíveis.',
      ),
      TaxBreakdown(
        'IVA — taxa 100%',
        vat100,
        'Transportes públicos e assinaturas de periódicos elegíveis.',
      ),
      if (vatRaw.cents > vat.cents)
        TaxBreakdown(
          'Limite global do IVA',
          -(vatRaw - vat),
          'A soma das quatro categorias está sujeita ao limite global.',
        ),
      if (limitedGroupRaw.cents > limitedGroup.cents)
        TaxBreakdown(
          'Limite global das deduções',
          -(limitedGroupRaw - limitedGroup),
          'Redução aplicada ao conjunto de deduções legalmente limitado.',
        ),
      if ((dependentCredit + general + limitedGroup).cents > total.cents)
        TaxBreakdown(
          'Limite pela coleta',
          -(dependentCredit + general + limitedGroup - total),
          'As deduções não podem exceder a coleta disponível.',
        ),
    ];
    return (total: total, breakdown: breakdown, overallCap: overallCap);
  }

  Money _limited(
    Money expense,
    int rate,
    int cap,
    String label,
    List<String> warnings,
  ) {
    final calculated = expense.timesPpm(rate);
    if (calculated.cents > cap) {
      warnings.add(
        'Em $label, a dedução calculada de ${calculated.format()} '
        'foi limitada a ${Money.fromCents(cap).format()}.',
      );
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
      transitional =
          transitionBase +
          Money.mulDiv(
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
      cap =
          highCap +
          Money.mulDiv(lowCap - highCap, upper - taxable.cents, upper - first);
    }
    if (dependents >= 3) {
      cap += Money.mulDiv(
        cap,
        rules.d('largeFamilyIncreasePpmPerDependent') * dependents,
        1000000,
      );
    }
    return Money.fromCents(cap);
  }

  TaxResult _unavailable(
    TaxSimulation simulation,
    List<String> warnings,
  ) => TaxResult(
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
    warnings: warnings,
    assumptions: const [
      'O cálculo foi bloqueado para evitar apresentar um valor não validado.',
    ],
    creditBreakdown: const [],
    bracketBaseTax: Money.zero,
    bracketExcess: Money.zero,
    marginalRatePpm: 0,
    overallDeductionsCap: null,
  );
}
