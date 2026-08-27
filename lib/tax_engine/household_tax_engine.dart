import '../domain/models.dart';
import '../domain/money.dart';
import 'supported_scope.dart';
import 'tax_engine.dart';
import 'tax_rules.dart';

final class HouseholdTaxComparison {
  const HouseholdTaxComparison({
    required this.available,
    required this.separate,
    required this.joint,
    required this.recommendedMode,
    required this.difference,
    required this.warnings,
  });

  final bool available;
  final TaxResult? separate;
  final TaxResult? joint;
  final FilingMode? recommendedMode;
  final Money difference;
  final List<String> warnings;
}

/// Liquidação standard de casados/unidos de facto com dois titulares.
/// Exclui expressamente guarda partilhada, rendimentos não-A e situações
/// especiais. A separada usa despesas próprias + 50% das dos dependentes.
final class HouseholdTaxEngine {
  const HouseholdTaxEngine(this.rules);

  final TaxRuleSet rules;

  HouseholdTaxComparison compare(TaxSimulation simulation) {
    final issues = SupportedScopeValidator(rules).validate(simulation);
    final isCouple = simulation.profile.civilStatus != CivilStatus.single;
    final jurisdictionMatches =
        rules.jurisdiction == simulation.profile.region.name.toUpperCase();
    if (issues.isNotEmpty ||
        !jurisdictionMatches ||
        !isCouple ||
        simulation.secondaryTaxpayer == null) {
      return HouseholdTaxComparison(
        available: false,
        separate: null,
        joint: null,
        recommendedMode: null,
        difference: Money.zero,
        warnings: [
          if (!isCouple)
            'A comparação conjugal exige casamento ou união de facto.',
          ...issues.map((issue) => issue.message),
          if (!jurisdictionMatches)
            'As regras carregadas não correspondem à região selecionada.',
        ],
      );
    }

    final secondary = simulation.secondaryTaxpayer!;
    final dependents = simulation.dependents.isEmpty
        ? List.generate(
            simulation.profile.dependentAges.length,
            (index) => Dependent(
              id: 'legacy-$index',
              ageAtYearEnd: simulation.profile.dependentAges[index],
            ),
          )
        : simulation.dependents;
    final ages = dependents.map((value) => value.ageAtYearEnd).toList();
    final totalGross = simulation.income.gross + secondary.income.gross;
    final householdCutoff = Money.mulDiv(
      rules.iasCents,
      rules.me('cutoffIasMultiplierTenths') * rules.me('months') * 2,
      10,
    );
    final allowMinimumExistence = totalGross.cents <= householdCutoff;

    final halfDependent = _scale(
      simulation.dependentDeductions,
      rules.h('separateDependentExpenseSharePpm'),
      1000000,
    );
    final deductionsA = _add(simulation.deductions, halfDependent);
    final deductionsB = _add(secondary.deductions, halfDependent);
    final separateRules = _separateRules();
    final resultA = _individual(
      simulation,
      age: simulation.profile.age,
      income: simulation.income,
      deductions: deductionsA,
      dependentAges: ages,
      calculationRules: separateRules,
      allowMinimumExistence: allowMinimumExistence,
      label: 'Titular A',
    );
    final resultB = _individual(
      simulation,
      age: secondary.age,
      income: secondary.income,
      deductions: deductionsB,
      dependentAges: ages,
      calculationRules: separateRules,
      allowMinimumExistence: allowMinimumExistence,
      label: 'Titular B',
    );
    final separate = _sumResults(resultA, resultB, FilingMode.separate);

    final jointDeductions = _add(
      _add(simulation.deductions, secondary.deductions),
      simulation.dependentDeductions,
    );
    final joint = _joint(
      simulation,
      secondary,
      ages,
      jointDeductions,
      allowMinimumExistence,
    );
    final recommended = joint.taxDue.cents <= separate.taxDue.cents
        ? FilingMode.joint
        : FilingMode.separate;
    return HouseholdTaxComparison(
      available: true,
      separate: separate,
      joint: joint,
      recommendedMode: recommended,
      difference: Money.fromCents(
        (joint.taxDue.cents - separate.taxDue.cents).abs(),
      ),
      warnings: const [
        'Comparação limitada a Categoria A e agregado standard sem guarda partilhada.',
      ],
    );
  }

  TaxResult _joint(
    TaxSimulation source,
    TaxpayerInput secondary,
    List<int> ages,
    DeductionInput deductions,
    bool allowMinimumExistence,
  ) {
    final engine = TaxEngine(_jointRules());
    final specificA = engine.specificDeductionFor(source.income);
    final specificB = engine.specificDeductionFor(secondary.income);
    final minimumA = allowMinimumExistence
        ? engine.minimumExistenceAllowanceFor(source.income, specificA)
        : Money.zero;
    final minimumB = allowMinimumExistence
        ? engine.minimumExistenceAllowanceFor(secondary.income, specificB)
        : Money.zero;
    final taxable =
        (source.income.gross +
                secondary.income.gross -
                specificA -
                specificB -
                minimumA -
                minimumB)
            .max(Money.zero);
    final jointDivisor = rules.h('jointDivisor');
    final quotient = Money.fromCents(
      Money.mulDiv(taxable.cents, 1, jointDivisor),
    );
    final detail = engine.generalTaxDetailFor(quotient);
    final grossTax = Money.fromCents(detail.tax.cents * jointDivisor);
    final solidarityHalf = engine.solidarityTaxForTaxableIncome(quotient);
    final solidarity = Money.fromCents(solidarityHalf.cents * jointDivisor);
    final warnings = <String>[];
    final creditSimulation = _creditSimulation(
      source,
      age: source.profile.age,
      deductions: deductions,
      dependentAges: ages,
    );
    final credits = engine.creditsForSimulation(
      creditSimulation,
      quotient,
      grossTax,
      warnings,
      // O limite do EBF artigo 21.º é individual. Somar apenas os créditos já
      // limitados por titular impede transferir para A o limite PPR não usado
      // por B (ou vice-versa) na tributação conjunta.
      pprCreditOverride:
          _individualPprCredit(source.deductions.ppr, source.profile.age) +
          _individualPprCredit(secondary.deductions.ppr, secondary.age),
    );
    final taxDue = (grossTax - credits.total).max(Money.zero) + solidarity;
    final withholding =
        source.income.withholding + secondary.income.withholding;
    return TaxResult(
      available: true,
      grossIncome: source.income.gross + secondary.income.gross,
      specificDeduction: specificA + specificB,
      minimumExistenceAllowance: minimumA + minimumB,
      taxableIncome: taxable,
      grossTax: grossTax,
      taxCredits: credits.total,
      solidarityTax: solidarity,
      taxDue: taxDue,
      withholding: withholding,
      balance: withholding - taxDue,
      breakdown: [
        TaxBreakdown(
          'Rendimento coletável do agregado',
          taxable,
          'Total dos dois titulares.',
        ),
        TaxBreakdown(
          'Quociente conjugal',
          quotient,
          'Metade do rendimento coletável, nos termos do artigo 69.º.',
        ),
        TaxBreakdown(
          'Coleta conjunta',
          grossTax,
          'Imposto sobre o quociente multiplicado por dois.',
        ),
      ],
      warnings: warnings,
      assumptions: [
        'Tributação conjunta standard; quociente conjugal 2.',
        'Regras ${rules.taxYear} ${rules.jurisdiction}, ${rules.rulesVersion}.',
      ],
      creditBreakdown: credits.breakdown,
      bracketBaseTax: Money.fromCents(detail.baseTax.cents * jointDivisor),
      bracketExcess: Money.fromCents(detail.excess.cents * jointDivisor),
      marginalRatePpm: detail.ratePpm,
      overallDeductionsCap: credits.overallCap,
    );
  }

  TaxResult _individual(
    TaxSimulation source, {
    required int age,
    required EmploymentIncome income,
    required DeductionInput deductions,
    required List<int> dependentAges,
    required TaxRuleSet calculationRules,
    required bool allowMinimumExistence,
    required String label,
  }) {
    final engine = TaxEngine(calculationRules);
    final specific = engine.specificDeductionFor(income);
    final minimum = allowMinimumExistence
        ? engine.minimumExistenceAllowanceFor(income, specific)
        : Money.zero;
    final taxable = (income.gross - specific - minimum).max(Money.zero);
    final detail = engine.generalTaxDetailFor(taxable);
    final solidarity = engine.solidarityTaxForTaxableIncome(taxable);
    final warnings = <String>[];
    final credits = engine.creditsForSimulation(
      _creditSimulation(
        source,
        age: age,
        deductions: deductions,
        dependentAges: dependentAges,
      ),
      taxable,
      detail.tax,
      warnings,
    );
    final due = (detail.tax - credits.total).max(Money.zero) + solidarity;
    return TaxResult(
      available: true,
      grossIncome: income.gross,
      specificDeduction: specific,
      minimumExistenceAllowance: minimum,
      taxableIncome: taxable,
      grossTax: detail.tax,
      taxCredits: credits.total,
      solidarityTax: solidarity,
      taxDue: due,
      withholding: income.withholding,
      balance: income.withholding - due,
      breakdown: [
        TaxBreakdown(
          label,
          due,
          'Liquidação individual em tributação separada.',
        ),
      ],
      warnings: warnings,
      assumptions: [
        'Tributação separada: despesas próprias + 50% das despesas dos dependentes.',
      ],
      creditBreakdown: credits.breakdown,
      bracketBaseTax: detail.baseTax,
      bracketExcess: detail.excess,
      marginalRatePpm: detail.ratePpm,
      overallDeductionsCap: credits.overallCap,
    );
  }

  TaxResult _sumResults(TaxResult a, TaxResult b, FilingMode mode) => TaxResult(
    available: a.available && b.available,
    grossIncome: a.grossIncome + b.grossIncome,
    specificDeduction: a.specificDeduction + b.specificDeduction,
    minimumExistenceAllowance:
        a.minimumExistenceAllowance + b.minimumExistenceAllowance,
    taxableIncome: a.taxableIncome + b.taxableIncome,
    grossTax: a.grossTax + b.grossTax,
    taxCredits: a.taxCredits + b.taxCredits,
    solidarityTax: a.solidarityTax + b.solidarityTax,
    taxDue: a.taxDue + b.taxDue,
    withholding: a.withholding + b.withholding,
    balance: a.balance + b.balance,
    breakdown: [...a.breakdown, ...b.breakdown],
    warnings: [...a.warnings, ...b.warnings],
    assumptions: ['Resultado agregado de duas liquidações ${mode.name}.'],
    creditBreakdown: [...a.creditBreakdown, ...b.creditBreakdown],
    bracketBaseTax: a.bracketBaseTax + b.bracketBaseTax,
    bracketExcess: a.bracketExcess + b.bracketExcess,
    marginalRatePpm: a.marginalRatePpm > b.marginalRatePpm
        ? a.marginalRatePpm
        : b.marginalRatePpm,
    overallDeductionsCap:
        a.overallDeductionsCap != null && b.overallDeductionsCap != null
        ? a.overallDeductionsCap! + b.overallDeductionsCap!
        : null,
  );

  TaxSimulation _creditSimulation(
    TaxSimulation source, {
    required int age,
    required DeductionInput deductions,
    required List<int> dependentAges,
  }) => source.copyWith(
    profile: source.profile.copyWith(
      age: age,
      civilStatus: CivilStatus.single,
      filingMode: FilingMode.separate,
      dependentAges: dependentAges,
      isSingleParentHousehold: false,
    ),
    deductions: deductions,
    clearSecondaryTaxpayer: true,
  );

  TaxRuleSet _separateRules() {
    final divisor = rules.h('familyLimitDivisor');
    // O artigo 78.º, n.º 14 reduz os limites referidos ao agregado e atribui
    // metade das despesas dos dependentes a cada titular. O limite de despesas
    // gerais e o PPR continuam individuais e, por isso, não são divididos aqui.
    return rules.copyWith(
      deductions: {
        ...rules.deductions,
        'dependentBaseCents': Money.mulDiv(
          rules.d('dependentBaseCents'),
          1,
          divisor,
        ),
        'dependentUnderThreeExtraCents': Money.mulDiv(
          rules.d('dependentUnderThreeExtraCents'),
          1,
          divisor,
        ),
        'secondAndLaterUnderSixExtraCents': Money.mulDiv(
          rules.d('secondAndLaterUnderSixExtraCents'),
          1,
          divisor,
        ),
        'healthCapCents': Money.mulDiv(rules.d('healthCapCents'), 1, divisor),
        'educationCapCents': Money.mulDiv(
          rules.d('educationCapCents'),
          1,
          divisor,
        ),
        'careHomeCapCents': Money.mulDiv(
          rules.d('careHomeCapCents'),
          1,
          divisor,
        ),
        'invoiceVatCapCents': Money.mulDiv(
          rules.d('invoiceVatCapCents'),
          1,
          divisor,
        ),
        'rentFloorCapCents': Money.mulDiv(
          rules.d('rentFloorCapCents'),
          1,
          divisor,
        ),
        'rentTransitionLowCapCents': Money.mulDiv(
          rules.d('rentTransitionLowCapCents'),
          1,
          divisor,
        ),
        'rentTransitionBaseCapCents': Money.mulDiv(
          rules.d('rentTransitionBaseCapCents'),
          1,
          divisor,
        ),
        'overallLowIncomeCapCents': Money.mulDiv(
          rules.d('overallLowIncomeCapCents'),
          1,
          divisor,
        ),
        'overallHighIncomeCapCents': Money.mulDiv(
          rules.d('overallHighIncomeCapCents'),
          1,
          divisor,
        ),
      },
    );
  }

  TaxRuleSet _jointRules() {
    return rules.copyWith(
      deductions: {
        ...rules.deductions,
        'generalCapPerTaxpayerCents':
            rules.d('generalCapPerTaxpayerCents') * rules.h('jointDivisor'),
      },
    );
  }

  Money _individualPprCredit(Money contribution, int age) {
    final cap = age < 35
        ? rules.d('pprUnder35CapCents')
        : age <= 50
        ? rules.d('ppr35To50CapCents')
        : rules.d('pprOver50CapCents');
    return contribution
        .timesPpm(rules.d('pprRatePpm'))
        .min(Money.fromCents(cap));
  }

  static DeductionInput _add(DeductionInput a, DeductionInput b) =>
      DeductionInput(
        general: a.general + b.general,
        health: a.health + b.health,
        education: a.education + b.education,
        rent: a.rent + b.rent,
        careHomes: a.careHomes + b.careHomes,
        invoiceVat15: a.invoiceVat15 + b.invoiceVat15,
        invoiceVat30: a.invoiceVat30 + b.invoiceVat30,
        invoiceVat35: a.invoiceVat35 + b.invoiceVat35,
        invoiceVat100: a.invoiceVat100 + b.invoiceVat100,
        ppr: a.ppr + b.ppr,
      );

  static DeductionInput _scale(
    DeductionInput value,
    int numerator,
    int denominator,
  ) => DeductionInput(
    general: Money.fromCents(
      Money.mulDiv(value.general.cents, numerator, denominator),
    ),
    health: Money.fromCents(
      Money.mulDiv(value.health.cents, numerator, denominator),
    ),
    education: Money.fromCents(
      Money.mulDiv(value.education.cents, numerator, denominator),
    ),
    rent: Money.fromCents(
      Money.mulDiv(value.rent.cents, numerator, denominator),
    ),
    careHomes: Money.fromCents(
      Money.mulDiv(value.careHomes.cents, numerator, denominator),
    ),
    invoiceVat15: Money.fromCents(
      Money.mulDiv(value.invoiceVat15.cents, numerator, denominator),
    ),
    invoiceVat30: Money.fromCents(
      Money.mulDiv(value.invoiceVat30.cents, numerator, denominator),
    ),
    invoiceVat35: Money.fromCents(
      Money.mulDiv(value.invoiceVat35.cents, numerator, denominator),
    ),
    invoiceVat100: Money.fromCents(
      Money.mulDiv(value.invoiceVat100.cents, numerator, denominator),
    ),
    ppr: Money.fromCents(Money.mulDiv(value.ppr.cents, numerator, denominator)),
  );
}
