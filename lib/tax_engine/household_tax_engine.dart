import '../domain/models.dart';
import '../domain/money.dart';
import 'supported_scope.dart';
import 'tax_engine.dart';
import 'irs_jovem_eligibility_engine.dart';
import 'irs_jovem_tax_engine.dart';
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

final class HouseholdIrsJovemComparison {
  const HouseholdIrsJovemComparison({
    required this.normal,
    required this.withIrsJovem,
    required this.primaryEligibility,
    required this.secondaryEligibility,
    required this.estimatedBenefit,
    required this.warnings,
  });

  final HouseholdTaxComparison normal;
  final HouseholdTaxComparison? withIrsJovem;
  final IrsJovemEligibilityResult primaryEligibility;
  final IrsJovemEligibilityResult secondaryEligibility;
  final Money estimatedBenefit;
  final List<String> warnings;

  bool get available => normal.available;
}

/// Liquidação standard de casados/unidos de facto com dois titulares.
/// Exclui expressamente guarda partilhada, rendimentos não-A e situações
/// especiais. A separada usa despesas próprias + 50% das dos dependentes.
final class HouseholdTaxEngine {
  const HouseholdTaxEngine(this.rules);

  final TaxRuleSet rules;

  HouseholdTaxComparison compare(TaxSimulation simulation) =>
      _compare(simulation, exemptA: Money.zero, exemptB: Money.zero);

  HouseholdIrsJovemComparison compareWithIrsJovem(TaxSimulation simulation) {
    final secondary = simulation.secondaryTaxpayer;
    final primaryEligibility = IrsJovemEligibilityEngine(rules).evaluate(
      ageAtYearEnd: simulation.profile.age,
      categoryAIncome: simulation.income.gross,
      answers: simulation.primaryIrsJovem,
    );
    final secondaryEligibility = IrsJovemEligibilityEngine(rules).evaluate(
      ageAtYearEnd: secondary?.age ?? 0,
      categoryAIncome: secondary?.income.gross ?? Money.zero,
      answers: secondary?.irsJovem ?? const IrsJovemAnswers(),
    );
    final normal = compare(simulation);
    final incomplete = [
      primaryEligibility,
      secondaryEligibility,
    ].any((value) => value.status == IrsJovemEligibility.needsMoreInformation);
    if (!normal.available || incomplete) {
      return HouseholdIrsJovemComparison(
        normal: normal,
        withIrsJovem: null,
        primaryEligibility: primaryEligibility,
        secondaryEligibility: secondaryEligibility,
        estimatedBenefit: Money.zero,
        warnings: [
          if (incomplete)
            'Falta informação para aplicar IRS Jovem com segurança.',
        ],
      );
    }
    final withBenefit = _compare(
      simulation,
      exemptA: primaryEligibility.status == IrsJovemEligibility.eligible
          ? primaryEligibility.eligibleExemptIncome
          : Money.zero,
      exemptB: secondaryEligibility.status == IrsJovemEligibility.eligible
          ? secondaryEligibility.eligibleExemptIncome
          : Money.zero,
    );
    final normalBest =
        normal.joint!.taxDue.cents <= normal.separate!.taxDue.cents
        ? normal.joint!.taxDue
        : normal.separate!.taxDue;
    final jovemBest =
        withBenefit.joint!.taxDue.cents <= withBenefit.separate!.taxDue.cents
        ? withBenefit.joint!.taxDue
        : withBenefit.separate!.taxDue;
    return HouseholdIrsJovemComparison(
      normal: normal,
      withIrsJovem: withBenefit,
      primaryEligibility: primaryEligibility,
      secondaryEligibility: secondaryEligibility,
      estimatedBenefit: (normalBest - jovemBest).max(Money.zero),
      warnings: const [],
    );
  }

  HouseholdTaxComparison _compare(
    TaxSimulation simulation, {
    required Money exemptA,
    required Money exemptB,
  }) {
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
      eligibleExemptIncome: exemptA,
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
      eligibleExemptIncome: exemptB,
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
      exemptA + exemptB,
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
    Money eligibleExemptIncome,
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
    final normalTaxable =
        (source.income.gross +
                secondary.income.gross -
                specificA -
                specificB -
                minimumA -
                minimumB)
            .max(Money.zero);
    final jointDivisor = rules.h('jointDivisor');
    final adjustment = IrsJovemTaxAdjustment.calculate(
      engine: engine,
      normalTaxableIncome: normalTaxable,
      eligibleExemptIncome: eligibleExemptIncome,
      divisor: jointDivisor,
    );
    final taxable = adjustment.taxableIncome;
    final quotient = Money.fromCents(
      Money.mulDiv(taxable.cents, 1, jointDivisor),
    );
    final grossTax = adjustment.adjustedGrossTax;
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
        if (adjustment.exemptIncome.cents > 0)
          TaxBreakdown(
            'Rendimento isento IRS Jovem do agregado',
            -adjustment.exemptIncome,
            'Soma das parcelas elegíveis dos titulares, limitada individualmente.',
          ),
        TaxBreakdown(
          'Rendimento coletável do agregado',
          taxable,
          'Total dos dois titulares.',
        ),
        if (adjustment.exemptIncome.cents > 0) ...[
          TaxBreakdown(
            'Rendimento do agregado para taxa',
            adjustment.rateDeterminingIncome,
            'Inclui o rendimento isento sem deduções, nos termos do artigo 22.º.',
          ),
          TaxBreakdown(
            'Quociente para determinação da taxa',
            adjustment.rateDeterminingQuotient,
            'Rendimento para taxa dividido pelo quociente conjugal 2.',
          ),
          TaxBreakdown(
            'Coleta imputada ao rendimento isento',
            -adjustment.taxOnExemptIncome,
            'Parcela proporcional retirada depois de apurada a coleta para taxa.',
          ),
        ],
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
      bracketBaseTax: adjustment.bracketBaseTax,
      bracketExcess: adjustment.bracketExcess,
      marginalRatePpm: adjustment.marginalRatePpm,
      overallDeductionsCap: credits.overallCap,
      trace: TaxCalculationTrace(
        grossIncome: source.income.gross + secondary.income.gross,
        specificDeduction: specificA + specificB,
        minimumExistenceAllowance: minimumA + minimumB,
        taxableIncome: taxable,
        maritalQuotient: jointDivisor,
        rateDeterminingIncome: adjustment.rateDeterminingIncome,
        rateDeterminingQuotient: adjustment.rateDeterminingQuotient,
        bracketBaseTax: adjustment.bracketBaseTax,
        bracketExcess: adjustment.bracketExcess,
        marginalRatePpm: adjustment.marginalRatePpm,
        taxBeforeExemption: adjustment.taxBeforeExemptAllocation,
        exemptIncome: adjustment.exemptIncome,
        taxAllocatedToExemptIncome: adjustment.taxOnExemptIncome,
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
        withholding: withholding,
        balance: withholding - taxDue,
      ),
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
    required Money eligibleExemptIncome,
  }) {
    final engine = TaxEngine(calculationRules);
    final specific = engine.specificDeductionFor(income);
    final minimum = allowMinimumExistence
        ? engine.minimumExistenceAllowanceFor(income, specific)
        : Money.zero;
    final normalTaxable = (income.gross - specific - minimum).max(Money.zero);
    final adjustment = IrsJovemTaxAdjustment.calculate(
      engine: engine,
      normalTaxableIncome: normalTaxable,
      eligibleExemptIncome: eligibleExemptIncome,
    );
    final taxable = adjustment.taxableIncome;
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
      adjustment.adjustedGrossTax,
      warnings,
    );
    final due =
        (adjustment.adjustedGrossTax - credits.total).max(Money.zero) +
        solidarity;
    return TaxResult(
      available: true,
      grossIncome: income.gross,
      specificDeduction: specific,
      minimumExistenceAllowance: minimum,
      taxableIncome: taxable,
      grossTax: adjustment.adjustedGrossTax,
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
        if (adjustment.exemptIncome.cents > 0) ...[
          TaxBreakdown(
            'Rendimento isento IRS Jovem · $label',
            -adjustment.exemptIncome,
            'Isenção elegível deste titular.',
          ),
          TaxBreakdown(
            'Rendimento para taxa · $label',
            adjustment.rateDeterminingIncome,
            'Inclui a parcela isenta sem deduções.',
          ),
          TaxBreakdown(
            'Coleta imputada ao rendimento isento · $label',
            -adjustment.taxOnExemptIncome,
            'Imputação proporcional do artigo 22.º.',
          ),
        ],
      ],
      warnings: warnings,
      assumptions: [
        'Tributação separada: despesas próprias + 50% das despesas dos dependentes.',
      ],
      creditBreakdown: credits.breakdown,
      bracketBaseTax: adjustment.bracketBaseTax,
      bracketExcess: adjustment.bracketExcess,
      marginalRatePpm: adjustment.marginalRatePpm,
      overallDeductionsCap: credits.overallCap,
      trace: TaxCalculationTrace(
        grossIncome: income.gross,
        specificDeduction: specific,
        minimumExistenceAllowance: minimum,
        taxableIncome: taxable,
        maritalQuotient: 1,
        rateDeterminingIncome: adjustment.rateDeterminingIncome,
        rateDeterminingQuotient: adjustment.rateDeterminingQuotient,
        bracketBaseTax: adjustment.bracketBaseTax,
        bracketExcess: adjustment.bracketExcess,
        marginalRatePpm: adjustment.marginalRatePpm,
        taxBeforeExemption: adjustment.taxBeforeExemptAllocation,
        exemptIncome: adjustment.exemptIncome,
        taxAllocatedToExemptIncome: adjustment.taxOnExemptIncome,
        grossTaxAfterExemption: adjustment.adjustedGrossTax,
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
        finalTaxDue: due,
        withholding: income.withholding,
        balance: income.withholding - due,
      ),
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
    trace: TaxCalculationTrace(
      grossIncome: a.trace.grossIncome + b.trace.grossIncome,
      specificDeduction: a.trace.specificDeduction + b.trace.specificDeduction,
      minimumExistenceAllowance:
          a.trace.minimumExistenceAllowance + b.trace.minimumExistenceAllowance,
      taxableIncome: a.trace.taxableIncome + b.trace.taxableIncome,
      maritalQuotient: 1,
      rateDeterminingIncome:
          a.trace.rateDeterminingIncome + b.trace.rateDeterminingIncome,
      rateDeterminingQuotient:
          a.trace.rateDeterminingQuotient + b.trace.rateDeterminingQuotient,
      bracketBaseTax: a.trace.bracketBaseTax + b.trace.bracketBaseTax,
      bracketExcess: a.trace.bracketExcess + b.trace.bracketExcess,
      marginalRatePpm: a.trace.marginalRatePpm > b.trace.marginalRatePpm
          ? a.trace.marginalRatePpm
          : b.trace.marginalRatePpm,
      taxBeforeExemption:
          a.trace.taxBeforeExemption + b.trace.taxBeforeExemption,
      exemptIncome: a.trace.exemptIncome + b.trace.exemptIncome,
      taxAllocatedToExemptIncome:
          a.trace.taxAllocatedToExemptIncome +
          b.trace.taxAllocatedToExemptIncome,
      grossTaxAfterExemption:
          a.trace.grossTaxAfterExemption + b.trace.grossTaxAfterExemption,
      dependentCredits: a.trace.dependentCredits + b.trace.dependentCredits,
      generalExpenseCredit:
          a.trace.generalExpenseCredit + b.trace.generalExpenseCredit,
      healthCredit: a.trace.healthCredit + b.trace.healthCredit,
      educationCredit: a.trace.educationCredit + b.trace.educationCredit,
      careHomeCredit: a.trace.careHomeCredit + b.trace.careHomeCredit,
      rentCredit: a.trace.rentCredit + b.trace.rentCredit,
      invoiceVatCredit: a.trace.invoiceVatCredit + b.trace.invoiceVatCredit,
      pprCredit: a.trace.pprCredit + b.trace.pprCredit,
      overallDeductionsCap:
          a.trace.overallDeductionsCap != null &&
              b.trace.overallDeductionsCap != null
          ? a.trace.overallDeductionsCap! + b.trace.overallDeductionsCap!
          : null,
      potentialTaxCredits:
          a.trace.potentialTaxCredits + b.trace.potentialTaxCredits,
      effectiveTaxCredits:
          a.trace.effectiveTaxCredits + b.trace.effectiveTaxCredits,
      totalTaxCredits: a.trace.totalTaxCredits + b.trace.totalTaxCredits,
      solidarityTax: a.trace.solidarityTax + b.trace.solidarityTax,
      finalTaxDue: a.trace.finalTaxDue + b.trace.finalTaxDue,
      withholding: a.trace.withholding + b.trace.withholding,
      balance: a.trace.balance + b.trace.balance,
    ),
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
