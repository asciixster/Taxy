import '../domain/models.dart';
import '../domain/money.dart';
import 'irs_jovem_eligibility_engine.dart';
import 'tax_engine.dart';
import 'tax_rules.dart';

/// Resultado puro da aplicação dos artigos 12.º-B e 22.º do CIRS.
///
/// O rendimento isento não integra o rendimento coletável tributado, mas é
/// somado, sem deduções, para determinar a taxa aplicável ao rendimento
/// restante. O imposto correspondente ao rendimento isento é retirado de forma
/// proporcional à coleta calculada sobre o rendimento para taxa.
final class IrsJovemTaxAdjustment {
  const IrsJovemTaxAdjustment({
    required this.exemptIncome,
    required this.taxableIncome,
    required this.rateDeterminingIncome,
    required this.rateDeterminingQuotient,
    required this.taxBeforeExemptAllocation,
    required this.taxOnExemptIncome,
    required this.adjustedGrossTax,
    required this.bracketBaseTax,
    required this.bracketExcess,
    required this.marginalRatePpm,
  });

  final Money exemptIncome;
  final Money taxableIncome;
  final Money rateDeterminingIncome;
  final Money rateDeterminingQuotient;
  final Money taxBeforeExemptAllocation;
  final Money taxOnExemptIncome;
  final Money adjustedGrossTax;
  final Money bracketBaseTax;
  final Money bracketExcess;
  final int marginalRatePpm;

  factory IrsJovemTaxAdjustment.calculate({
    required TaxEngine engine,
    required Money normalTaxableIncome,
    required Money eligibleExemptIncome,
    int divisor = 1,
  }) {
    final exempt = eligibleExemptIncome;
    final taxable = (normalTaxableIncome - exempt).max(Money.zero);
    final rateIncome = taxable + exempt;
    final quotient = Money.fromCents(
      Money.mulDiv(rateIncome.cents, 1, divisor),
    );
    final detail = engine.generalTaxDetailFor(quotient);
    final taxBefore = Money.fromCents(detail.tax.cents * divisor);
    final exemptTax = rateIncome.cents == 0
        ? Money.zero
        : Money.fromCents(
            Money.mulDiv(taxBefore.cents, exempt.cents, rateIncome.cents),
          );
    return IrsJovemTaxAdjustment(
      exemptIncome: exempt,
      taxableIncome: taxable,
      rateDeterminingIncome: rateIncome,
      rateDeterminingQuotient: quotient,
      taxBeforeExemptAllocation: taxBefore,
      taxOnExemptIncome: exemptTax,
      adjustedGrossTax: (taxBefore - exemptTax).max(Money.zero),
      bracketBaseTax: Money.fromCents(detail.baseTax.cents * divisor),
      bracketExcess: Money.fromCents(detail.excess.cents * divisor),
      marginalRatePpm: detail.ratePpm,
    );
  }
}

final class IrsJovemCalculationComparison {
  const IrsJovemCalculationComparison({
    required this.normal,
    required this.withIrsJovem,
    required this.eligibility,
    required this.adjustment,
    required this.estimatedBenefit,
  });

  final TaxResult normal;
  final TaxResult? withIrsJovem;
  final IrsJovemEligibilityResult eligibility;
  final IrsJovemTaxAdjustment? adjustment;
  final Money estimatedBenefit;

  bool get applied => withIrsJovem?.available ?? false;
}

/// Aplica a isenção à liquidação individual sem misturar a decisão de
/// elegibilidade no motor fiscal base.
final class IrsJovemTaxEngine {
  const IrsJovemTaxEngine(this.rules);

  final TaxRuleSet rules;

  IrsJovemCalculationComparison compare(TaxSimulation simulation) {
    final baseEngine = TaxEngine(rules);
    final normal = baseEngine.calculate(simulation);
    final eligibility = IrsJovemEligibilityEngine(rules).evaluate(
      ageAtYearEnd: simulation.profile.age,
      categoryAIncome: simulation.income.gross,
      answers: simulation.primaryIrsJovem,
    );
    if (!normal.available ||
        eligibility.status != IrsJovemEligibility.eligible) {
      return IrsJovemCalculationComparison(
        normal: normal,
        withIrsJovem: null,
        eligibility: eligibility,
        adjustment: null,
        estimatedBenefit: Money.zero,
      );
    }

    final adjustment = IrsJovemTaxAdjustment.calculate(
      engine: baseEngine,
      normalTaxableIncome: normal.taxableIncome,
      eligibleExemptIncome: eligibility.eligibleExemptIncome,
    );
    final warnings = <String>[];
    final credits = baseEngine.creditsForSimulation(
      simulation,
      adjustment.taxableIncome,
      adjustment.adjustedGrossTax,
      warnings,
    );
    final solidarity = baseEngine.solidarityTaxForTaxableIncome(
      adjustment.taxableIncome,
    );
    final due =
        (adjustment.adjustedGrossTax - credits.total).max(Money.zero) +
        solidarity;
    final result = TaxResult(
      available: true,
      grossIncome: normal.grossIncome,
      specificDeduction: normal.specificDeduction,
      minimumExistenceAllowance: normal.minimumExistenceAllowance,
      taxableIncome: adjustment.taxableIncome,
      grossTax: adjustment.adjustedGrossTax,
      taxCredits: credits.total,
      solidarityTax: solidarity,
      taxDue: due,
      withholding: normal.withholding,
      balance: normal.withholding - due,
      breakdown: [
        TaxBreakdown(
          'Rendimento bruto',
          normal.grossIncome,
          'Rendimento Categoria A antes de deduções e isenção.',
        ),
        TaxBreakdown(
          'Dedução específica',
          -normal.specificDeduction,
          'Dedução específica da Categoria A.',
        ),
        if (normal.minimumExistenceAllowance.cents > 0)
          TaxBreakdown(
            'Mínimo de existência',
            -normal.minimumExistenceAllowance,
            'Abatimento apurado antes da isenção IRS Jovem.',
          ),
        TaxBreakdown(
          'Rendimento isento IRS Jovem',
          -adjustment.exemptIncome,
          'Parcela isenta dentro da percentagem e limite anual aplicáveis.',
        ),
        TaxBreakdown(
          'Rendimento coletável',
          adjustment.taxableIncome,
          'Parcela efetivamente sujeita a imposto.',
        ),
        TaxBreakdown(
          'Rendimento para determinação da taxa',
          adjustment.rateDeterminingIncome,
          'Inclui o rendimento isento por imposição do artigo 22.º do CIRS.',
        ),
        TaxBreakdown(
          'Imposto correspondente ao rendimento isento',
          -adjustment.taxOnExemptIncome,
          'Parcela proporcional retirada à coleta calculada para determinação da taxa.',
        ),
      ],
      warnings: warnings,
      assumptions: [
        'IRS Jovem aplicado nos termos dos artigos 12.º-B e 22.º do CIRS.',
        ...eligibility.reasons,
      ],
      creditBreakdown: credits.breakdown,
      bracketBaseTax: adjustment.bracketBaseTax,
      bracketExcess: adjustment.bracketExcess,
      marginalRatePpm: adjustment.marginalRatePpm,
      overallDeductionsCap: credits.overallCap,
      trace: TaxCalculationTrace(
        grossIncome: normal.grossIncome,
        specificDeduction: normal.specificDeduction,
        minimumExistenceAllowance: normal.minimumExistenceAllowance,
        taxableIncome: adjustment.taxableIncome,
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
        totalTaxCredits: credits.total,
        solidarityTax: solidarity,
        finalTaxDue: due,
        withholding: normal.withholding,
        balance: normal.withholding - due,
      ),
    );
    return IrsJovemCalculationComparison(
      normal: normal,
      withIrsJovem: result,
      eligibility: eligibility,
      adjustment: adjustment,
      estimatedBenefit: (normal.taxDue - due).max(Money.zero),
    );
  }
}
