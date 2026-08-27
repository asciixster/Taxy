import '../domain/models.dart';
import '../domain/money.dart';
import 'tax_rules.dart';

final class IrsJovemEligibilityResult {
  const IrsJovemEligibilityResult({
    required this.status,
    required this.exemptionRatePpm,
    required this.exemptionLimit,
    required this.eligibleExemptIncome,
    required this.relevantIncomeYear,
    required this.yearsAlreadyConsumed,
    required this.skippedYears,
    required this.reasons,
  });

  final IrsJovemEligibility status;
  final int exemptionRatePpm;
  final Money exemptionLimit;
  final Money eligibleExemptIncome;
  final int? relevantIncomeYear;
  final int yearsAlreadyConsumed;
  final int skippedYears;
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
      int? relevantIncomeYear,
      int yearsAlreadyConsumed = 0,
      int skippedYears = 0,
    }) => IrsJovemEligibilityResult(
      status: status,
      exemptionRatePpm: rate,
      exemptionLimit: limit,
      eligibleExemptIncome: status == IrsJovemEligibility.eligible
          ? categoryAIncome.timesPpm(rate).min(limit)
          : Money.zero,
      relevantIncomeYear: relevantIncomeYear,
      yearsAlreadyConsumed: yearsAlreadyConsumed,
      skippedYears: skippedYears,
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
    if (ageAtYearEnd < 0) {
      return result(IrsJovemEligibility.needsMoreInformation, [
        'A idade indicada é inválida.',
      ]);
    }
    if (categoryAIncome.cents <= 0 && answers.incomeHistory.isEmpty) {
      return result(IrsJovemEligibility.notEligible, [
        'É necessário rendimento elegível de Categoria A ou B.',
      ]);
    }
    final history = answers.incomeHistory;
    if (history.isNotEmpty && !answers.historyConfirmedComplete) {
      return result(IrsJovemEligibility.needsMoreInformation, [
        'É necessário confirmar que o histórico anual está completo.',
      ]);
    }
    final distinctYears = history.map((entry) => entry.year).toSet();
    final currentEntries = history
        .where((entry) => entry.year == rules.taxYear)
        .toList(growable: false);
    if (distinctYears.length != history.length ||
        history.any((entry) => entry.year > rules.taxYear)) {
      return result(IrsJovemEligibility.needsMoreInformation, [
        'O histórico anual contém anos duplicados ou posteriores ao ano fiscal.',
      ]);
    }
    final currentEntry = currentEntries.isEmpty ? null : currentEntries.first;
    if (history.isNotEmpty && currentEntry == null) {
      return result(IrsJovemEligibility.needsMoreInformation, [
        'O histórico anual não contém o ano fiscal que está a ser simulado.',
      ]);
    }
    if (history.isNotEmpty) {
      final orderedYears = [...distinctYears]..sort();
      for (var year = orderedYears.first; year <= rules.taxYear; year++) {
        if (!distinctYears.contains(year)) {
          return result(IrsJovemEligibility.needsMoreInformation, [
            'Falta o ano $year no histórico anual.',
          ]);
        }
      }
    }
    if (currentEntry != null && !currentEntry.hadCategoryAOrBIncome) {
      return result(IrsJovemEligibility.needsMoreInformation, [
        'O histórico não confirma rendimento A/B no ano que está a ser simulado.',
      ]);
    }
    if (currentEntry != null && !currentEntry.residentInPortugal) {
      return result(IrsJovemEligibility.notEligible, [
        'O titular não era residente fiscal em Portugal no ano simulado.',
      ]);
    }
    if (history.any(
      (entry) =>
          entry.year < rules.taxYear &&
          entry.hadCategoryAOrBIncome &&
          !entry.residentInPortugal,
    )) {
      return result(IrsJovemEligibility.needsMoreInformation, [
        'Rendimentos A/B obtidos em anos de não residência exigem validação histórica adicional.',
      ]);
    }
    if (history.any((entry) => entry.usedIncompatibleRegime)) {
      return result(IrsJovemEligibility.notEligible, [
        'O histórico contém utilização de um regime fiscal incompatível.',
      ]);
    }
    final wasDependent =
        currentEntry?.wasDependent ?? answers.wasDependentAtYearEnd;
    final qualifyingYear = history.isNotEmpty
        ? history
              .where(
                (entry) =>
                    entry.year <= rules.taxYear &&
                    entry.hadCategoryAOrBIncome &&
                    !entry.wasDependent &&
                    entry.residentInPortugal,
              )
              .length
        : answers.qualifyingIncomeYears;
    if (wasDependent == null ||
        qualifyingYear == null ||
        answers.taxSituationRegularized == null) {
      return result(IrsJovemEligibility.needsMoreInformation, [
        'Faltam respostas objetivas para determinar a elegibilidade.',
      ]);
    }
    if (wasDependent) {
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
    final year = qualifyingYear;
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
    final skippedYears = history
        .where(
          (entry) =>
              !entry.hadCategoryAOrBIncome ||
              entry.wasDependent ||
              !entry.residentInPortugal,
        )
        .length;
    return result(
      IrsJovemEligibility.eligible,
      [
        'Elegível no $year.º ano de obtenção de rendimentos.',
        if (history.isEmpty) 'Contagem transitória declarada pelo utilizador; histórico objetivo ainda não fornecido.',
      ],
      rate: rate,
      relevantIncomeYear: year,
      yearsAlreadyConsumed: year - 1,
      skippedYears: skippedYears,
    );
  }
}
