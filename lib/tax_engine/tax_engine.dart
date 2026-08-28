import '../domain/models.dart';
import '../domain/money.dart';
import 'tax_rules.dart';
import 'supported_scope.dart';

/// Typed result of the deductions phase. Values are kept separate from the
/// human-readable [TaxBreakdown] rows so validation never depends on labels.
final class TaxCreditCalculation {
  const TaxCreditCalculation({
    required this.total,
    required this.potentialTotal,
    required this.breakdown,
    required this.overallCap,
    required this.dependent,
    required this.general,
    required this.health,
    required this.education,
    required this.careHome,
    required this.rent,
    required this.invoiceVat,
    required this.ppr,
  });

  final Money total;

  /// Soma antes do limite global e do limite pela coleta disponível.
  final Money potentialTotal;
  final List<TaxBreakdown> breakdown;
  final Money? overallCap;
  final Money dependent;
  final Money general;
  final Money health;
  final Money education;
  final Money careHome;
  final Money rent;
  final Money invoiceVat;
  final Money ppr;
}

final class TaxEngine {
  const TaxEngine(this.rules);
  final TaxRuleSet rules;

  /// Exposto para auditoria e testes de fronteira dos escalões.
  Money grossTaxForTaxableIncome(Money taxableIncome) =>
      _generalTaxDetail(taxableIncome).tax;

  ({Money tax, Money baseTax, Money excess, int ratePpm}) generalTaxDetailFor(
    Money taxableIncome,
  ) => _generalTaxDetail(taxableIncome);

  Money specificDeductionFor(EmploymentIncome income) => moneyMax(
    Money.fromCents(rules.employmentSpecificDeductionCents),
    income.socialSecurity,
  ).min(income.gross);

  Money minimumExistenceAllowanceFor(
    EmploymentIncome income,
    Money specificDeduction,
  ) => _minimumExistenceAllowance(income.gross, specificDeduction);

  Money solidarityTaxForTaxableIncome(Money taxableIncome) =>
      _solidarityTax(taxableIncome);

  TaxCreditCalculation creditsForSimulation(
    TaxSimulation simulation,
    Money taxableIncome,
    Money grossTax,
    List<String> warnings, {
    Money? pprCreditOverride,
  }) => _credits(
    simulation,
    taxableIncome,
    grossTax,
    warnings,
    pprCreditOverride: pprCreditOverride,
  );

  /// Exposto para auditoria das fronteiras do limite global de deduções.
  Money? overallCreditCapForTaxableIncome(
    Money taxableIncome, {
    int dependents = 0,
  }) => _overallCreditCap(taxableIncome, dependents);

  /// Exposto para validação independente da transição dos limites de rendas.
  Money rentCreditCapForTaxableIncome(Money taxableIncome) =>
      Money.fromCents(_rentCap(taxableIncome));

  TaxResult calculate(TaxSimulation simulation, {bool validateScope = true}) {
    final warnings = <String>[];
    final assumptions = <String>[
      'Apenas rendimentos de trabalho dependente (Categoria A).',
      'Residente fiscal em Portugal durante todo o ano.',
      'Regras ${rules.jurisdiction} para ${rules.taxYear}, versão ${rules.rulesVersion}.',
      'Despesas introduzidas são elegíveis, documentadas e não reembolsadas.',
      'Educação limitada ao regime standard; estudante deslocado e majorações territoriais estão excluídos.',
      'Não inclui IRS Jovem, deficiência, pensões de alimentos ou rendimentos não indicados.',
    ];
    final input = simulation.income;
    final scopeIssues = validateScope
        ? SupportedScopeValidator(rules).validate(simulation)
        : const <ScopeValidationIssue>[];
    final expectedJurisdiction = simulation.profile.region.name.toUpperCase();
    if (scopeIssues.isNotEmpty ||
        (validateScope && rules.jurisdiction != expectedJurisdiction)) {
      return _unavailable(simulation, [
        ...scopeIssues.map((issue) => issue.message),
        if (rules.jurisdiction != expectedJurisdiction)
          'As regras carregadas (${rules.jurisdiction}) não correspondem à região $expectedJurisdiction.',
      ]);
    }

    final specific = specificDeductionFor(input);
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
      trace: TaxCalculationTrace(
        grossIncome: input.gross,
        specificDeduction: specific,
        minimumExistenceAllowance: minimumAllowance,
        taxableIncome: taxable,
        maritalQuotient: 1,
        rateDeterminingIncome: taxable,
        rateDeterminingQuotient: taxable,
        bracketBaseTax: bracket.baseTax,
        bracketExcess: bracket.excess,
        marginalRatePpm: bracket.ratePpm,
        taxBeforeExemption: grossTax,
        exemptIncome: Money.zero,
        taxAllocatedToExemptIncome: Money.zero,
        grossTaxAfterExemption: grossTax,
        dependentCredits: credits.dependent,
        generalExpenseCredit: credits.general,
        healthCredit: credits.health,
        educationCredit: credits.education,
        careHomeCredit: credits.careHome,
        rentCredit: credits.rent,
        invoiceVatCredit: credits.invoiceVat,
        pprCredit: credits.ppr,
        overallDeductionsCap: credits.overallCap,
        potentialTaxCredits: credits.potentialTotal,
        effectiveTaxCredits: credits.total,
        totalTaxCredits: credits.total,
        solidarityTax: solidarity,
        finalTaxDue: taxDue,
        withholding: input.withholding,
        balance: balance,
      ),
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
          'Resultado da aplicação progressiva das taxas gerais de ${rules.taxYear}.',
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
        // A AT continua a apresentar a taxa do primeiro escalão quando o
        // rendimento coletável é zero. A taxa é auditável, embora a coleta
        // permaneça necessariamente em zero.
        ratePpm: rules.brackets.first.marginalRatePpm,
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

  TaxCreditCalculation _credits(
    TaxSimulation simulation,
    Money taxable,
    Money grossTax,
    List<String> warnings, {
    Money? pprCreditOverride,
  }) {
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
    final ppr =
        pprCreditOverride ??
        _limited(d.ppr, rules.d('pprRatePpm'), pprCap, 'PPR', warnings);

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
    return TaxCreditCalculation(
      total: total,
      potentialTotal: dependentCredit + general + limitedGroupRaw,
      breakdown: breakdown,
      overallCap: overallCap,
      dependent: dependentCredit,
      general: general,
      health: health,
      education: education,
      careHome: care,
      rent: rent,
      invoiceVat: vat,
      ppr: ppr,
    );
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
    return intMax(transitional, rules.d('rentFloorCapCents'));
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
    trace: TaxCalculationTrace(
      grossIncome: simulation.income.gross,
      specificDeduction: Money.zero,
      minimumExistenceAllowance: Money.zero,
      taxableIncome: Money.zero,
      maritalQuotient: 1,
      rateDeterminingIncome: Money.zero,
      rateDeterminingQuotient: Money.zero,
      bracketBaseTax: Money.zero,
      bracketExcess: Money.zero,
      marginalRatePpm: 0,
      taxBeforeExemption: Money.zero,
      exemptIncome: Money.zero,
      taxAllocatedToExemptIncome: Money.zero,
      grossTaxAfterExemption: Money.zero,
      dependentCredits: Money.zero,
      generalExpenseCredit: Money.zero,
      healthCredit: Money.zero,
      educationCredit: Money.zero,
      careHomeCredit: Money.zero,
      rentCredit: Money.zero,
      invoiceVatCredit: Money.zero,
      pprCredit: Money.zero,
      overallDeductionsCap: null,
      potentialTaxCredits: Money.zero,
      effectiveTaxCredits: Money.zero,
      totalTaxCredits: Money.zero,
      solidarityTax: Money.zero,
      finalTaxDue: Money.zero,
      withholding: simulation.income.withholding,
      balance: Money.zero,
    ),
  );
}
