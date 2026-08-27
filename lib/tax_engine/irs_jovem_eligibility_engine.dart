import '../domain/models.dart';
import '../domain/money.dart';
import 'tax_rules.dart';

final class IrsJovemEligibilityResult {
  const IrsJovemEligibilityResult({
    required this.status,
    required this.exemptionRatePpm,
    required this.exemptionLimit,
    required this.eligibleExemptIncome,
    required this.reasons,
  });

  final IrsJovemEligibility status;
  final int exemptionRatePpm;
  final Money exemptionLimit;
  final Money eligibleExemptIncome;
  final List<String> reasons;
}

/// Determina elegibilidade pelo artigo 12.º-B. Não liquida IRS: o cálculo da
/// isenção com englobamento permanece separado do motor de elegibilidade.
final class IrsJovemEligibilityEngine {
  const IrsJovemEligibilityEngine(this.rules);

  final TaxRuleSet rules;

  IrsJovemEligibilityResult evaluate({
    required int ageAtYearEnd,
    required Money categoryAIncome,
    required IrsJovemAnswers answers,
  }) {
    final limit = Money.fromCents(
      rules.iasCents * rules.jovem('exemptionLimitIasMultiplier'),
    );
    IrsJovemEligibilityResult result(
      IrsJovemEligibility status,
      List<String> reasons, {
      int rate = 0,
    }) => IrsJovemEligibilityResult(
      status: status,
      exemptionRatePpm: rate,
      exemptionLimit: limit,
      eligibleExemptIncome: status == IrsJovemEligibility.eligible
          ? categoryAIncome.timesPpm(rate).min(limit)
          : Money.zero,
      reasons: reasons,
    );

    if (!answers.requested) {
      return result(IrsJovemEligibility.notRequested, const []);
    }
    if (rules.taxYear < 2025) {
      return result(IrsJovemEligibility.notEligible, [
        'O regime modelado aplica-se a rendimentos de 2025 e seguintes.',
      ]);
    }
    if (ageAtYearEnd > rules.jovem('maximumAge')) {
      return result(IrsJovemEligibility.notEligible, [
        'A idade em 31 de dezembro ultrapassa 35 anos.',
      ]);
    }
    if (ageAtYearEnd < 0 || categoryAIncome.cents <= 0) {
      return result(IrsJovemEligibility.notEligible, [
        'É necessário rendimento elegível de Categoria A ou B.',
      ]);
    }
    if (answers.wasDependentAtYearEnd == null ||
        answers.qualifyingIncomeYears == null ||
        answers.taxSituationRegularized == null) {
      return result(IrsJovemEligibility.needsMoreInformation, [
        'Faltam respostas objetivas para determinar a elegibilidade.',
      ]);
    }
    if (answers.wasDependentAtYearEnd!) {
      return result(IrsJovemEligibility.notEligible, [
        'O titular foi considerado dependente nesse ano.',
      ]);
    }
    if (!answers.taxSituationRegularized!) {
      return result(IrsJovemEligibility.notEligible, [
        'A situação tributária não está regularizada.',
      ]);
    }
    if (answers.usedRnhOrIfici || answers.usedReturnProgram) {
      return result(IrsJovemEligibility.notEligible, [
        'Existe um regime fiscal incompatível com o IRS Jovem.',
      ]);
    }
    final year = answers.qualifyingIncomeYears!;
    if (year < 1 || year > rules.jovem('maximumYears')) {
      return result(IrsJovemEligibility.notEligible, [
        'O período de 10 anos de rendimentos elegíveis não está em curso.',
      ]);
    }
    final rate = year == 1
        ? rules.jovem('year1RatePpm')
        : year <= 4
        ? rules.jovem('years2To4RatePpm')
        : year <= 7
        ? rules.jovem('years5To7RatePpm')
        : rules.jovem('years8To10RatePpm');
    return result(IrsJovemEligibility.eligible, [
      'Elegível no $year.º ano de obtenção de rendimentos.',
    ], rate: rate);
  }
}
