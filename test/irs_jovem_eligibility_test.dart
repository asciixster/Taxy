import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxy_pt/domain/models.dart';
import 'package:taxy_pt/domain/money.dart';
import 'package:taxy_pt/tax_engine/irs_jovem_eligibility_engine.dart';
import 'package:taxy_pt/tax_engine/tax_rules.dart';

void main() {
  late IrsJovemEligibilityEngine engine;

  setUpAll(() async {
    final repository = TaxRuleRepository((path) => File(path).readAsString());
    engine = IrsJovemEligibilityEngine(
      await repository.load(2026, 'continent'),
    );
  });

  for (var year = 1; year <= 10; year++) {
    test('IRS Jovem ano $year tem taxa legal', () {
      final result = engine.evaluate(
        ageAtYearEnd: 30,
        categoryAIncome: const Money.fromCents(2000000),
        answers: _answers(year: year),
      );
      final expected = year == 1
          ? 1000000
          : year <= 4
          ? 750000
          : year <= 7
          ? 500000
          : 250000;
      expect(result.status, IrsJovemEligibility.eligible);
      expect(result.exemptionRatePpm, expected);
    });
  }

  for (final age in [0, 18, 34, 35]) {
    test('idade $age permanece elegível com restantes requisitos', () {
      expect(
        engine
            .evaluate(
              ageAtYearEnd: age,
              categoryAIncome: const Money.fromCents(100000),
              answers: _answers(),
            )
            .status,
        IrsJovemEligibility.eligible,
      );
    });
  }

  for (final age in [36, 50, 99]) {
    test('idade $age não é elegível', () {
      expect(
        engine
            .evaluate(
              ageAtYearEnd: age,
              categoryAIncome: const Money.fromCents(100000),
              answers: _answers(),
            )
            .status,
        IrsJovemEligibility.notEligible,
      );
    });
  }

  for (final year in [0, 11, 20]) {
    test('ano de rendimentos $year não é elegível', () {
      expect(
        engine
            .evaluate(
              ageAtYearEnd: 30,
              categoryAIncome: const Money.fromCents(100000),
              answers: _answers(year: year),
            )
            .status,
        IrsJovemEligibility.notEligible,
      );
    });
  }

  test('sem opção fica notRequested', () {
    final result = engine.evaluate(
      ageAtYearEnd: 30,
      categoryAIncome: const Money.fromCents(100000),
      answers: const IrsJovemAnswers(),
    );
    expect(result.status, IrsJovemEligibility.notRequested);
  });

  for (final answers in [
    const IrsJovemAnswers(
      requested: true,
      qualifyingIncomeYears: 1,
      taxSituationRegularized: true,
    ),
    const IrsJovemAnswers(
      requested: true,
      wasDependentAtYearEnd: false,
      taxSituationRegularized: true,
    ),
    const IrsJovemAnswers(
      requested: true,
      wasDependentAtYearEnd: false,
      qualifyingIncomeYears: 1,
    ),
  ]) {
    test('resposta obrigatória em falta pede mais informação', () {
      expect(
        engine
            .evaluate(
              ageAtYearEnd: 30,
              categoryAIncome: const Money.fromCents(100000),
              answers: answers,
            )
            .status,
        IrsJovemEligibility.needsMoreInformation,
      );
    });
  }

  test('dependente não é elegível', () {
    expect(
      engine
          .evaluate(
            ageAtYearEnd: 25,
            categoryAIncome: const Money.fromCents(100000),
            answers: _answers(dependent: true),
          )
          .status,
      IrsJovemEligibility.notEligible,
    );
  });

  test('situação tributária irregular não é elegível', () {
    expect(
      engine
          .evaluate(
            ageAtYearEnd: 25,
            categoryAIncome: const Money.fromCents(100000),
            answers: _answers(regularized: false),
          )
          .status,
      IrsJovemEligibility.notEligible,
    );
  });

  for (final answers in [_answers(rnh: true), _answers(returnProgram: true)]) {
    test('regime incompatível não é elegível', () {
      expect(
        engine
            .evaluate(
              ageAtYearEnd: 25,
              categoryAIncome: const Money.fromCents(100000),
              answers: answers,
            )
            .status,
        IrsJovemEligibility.notEligible,
      );
    });
  }

  test('rendimento zero não é elegível', () {
    expect(
      engine
          .evaluate(
            ageAtYearEnd: 25,
            categoryAIncome: Money.zero,
            answers: _answers(),
          )
          .status,
      IrsJovemEligibility.notEligible,
    );
  });

  test('isenção é limitada a 55 IAS', () {
    final result = engine.evaluate(
      ageAtYearEnd: 25,
      categoryAIncome: const Money.fromCents(100000000),
      answers: _answers(),
    );
    expect(result.eligibleExemptIncome, result.exemptionLimit);
    expect(result.exemptionLimit.cents, 53713 * 55);
  });

  test('um cêntimo de Categoria A é rendimento elegível', () {
    final result = engine.evaluate(
      ageAtYearEnd: 30,
      categoryAIncome: const Money.fromCents(1),
      answers: const IrsJovemAnswers(
        requested: true,
        taxSituationRegularized: true,
        historyConfirmedComplete: true,
        incomeHistory: [
          IrsJovemIncomeYear(
            year: 2026,
            hadCategoryAIncome: true,
            hadCategoryBIncome: false,
            wasDependent: false,
            residentInPortugal: true,
          ),
        ],
      ),
    );
    expect(result.status, IrsJovemEligibility.eligible);
    expect(result.eligibleExemptIncome, const Money.fromCents(1));
  });

  test(
    'histórico objetivo ignora anos sem rendimento e anos como dependente',
    () {
      final result = engine.evaluate(
        ageAtYearEnd: 30,
        categoryAIncome: const Money.fromCents(2000000),
        answers: const IrsJovemAnswers(
          requested: true,
          taxSituationRegularized: true,
          historyConfirmedComplete: true,
          incomeHistory: [
            IrsJovemIncomeYear(
              year: 2022,
              hadCategoryAIncome: true,
              hadCategoryBIncome: false,
              wasDependent: true,
              residentInPortugal: true,
            ),
            IrsJovemIncomeYear(
              year: 2023,
              hadCategoryAIncome: true,
              hadCategoryBIncome: false,
              wasDependent: false,
              residentInPortugal: true,
            ),
            IrsJovemIncomeYear(
              year: 2024,
              hadCategoryAIncome: false,
              hadCategoryBIncome: false,
              wasDependent: false,
              residentInPortugal: true,
            ),
            IrsJovemIncomeYear(
              year: 2025,
              hadCategoryAIncome: false,
              hadCategoryBIncome: false,
              wasDependent: false,
              residentInPortugal: true,
            ),
            IrsJovemIncomeYear(
              year: 2026,
              hadCategoryAIncome: true,
              hadCategoryBIncome: false,
              wasDependent: false,
              residentInPortugal: true,
            ),
          ],
        ),
      );
      expect(result.status, IrsJovemEligibility.eligible);
      expect(result.exemptionRatePpm, 750000);
      expect(result.reasons.single, contains('2.º ano'));
    },
  );

  test('histórico contraditório pede mais informação', () {
    final result = engine.evaluate(
      ageAtYearEnd: 30,
      categoryAIncome: const Money.fromCents(2000000),
      answers: const IrsJovemAnswers(
        requested: true,
        taxSituationRegularized: true,
        historyConfirmedComplete: true,
        incomeHistory: [
          IrsJovemIncomeYear(
            year: 2026,
            hadCategoryAIncome: false,
            hadCategoryBIncome: false,
            wasDependent: false,
            residentInPortugal: true,
          ),
        ],
      ),
    );
    expect(result.status, IrsJovemEligibility.needsMoreInformation);
  });

  test('histórico sem o ano simulado pede mais informação', () {
    final result = engine.evaluate(
      ageAtYearEnd: 30,
      categoryAIncome: const Money.fromCents(2000000),
      answers: const IrsJovemAnswers(
        requested: true,
        taxSituationRegularized: true,
        historyConfirmedComplete: true,
        incomeHistory: [
          IrsJovemIncomeYear(
            year: 2025,
            hadCategoryAIncome: true,
            hadCategoryBIncome: false,
            wasDependent: false,
            residentInPortugal: true,
          ),
        ],
      ),
    );
    expect(result.status, IrsJovemEligibility.needsMoreInformation);
  });

  test('histórico objetivo não confirmado pede mais informação', () {
    final result = engine.evaluate(
      ageAtYearEnd: 30,
      categoryAIncome: const Money.fromCents(1),
      answers: const IrsJovemAnswers(
        requested: true,
        taxSituationRegularized: true,
        incomeHistory: [
          IrsJovemIncomeYear(
            year: 2026,
            hadCategoryAIncome: true,
            hadCategoryBIncome: false,
            wasDependent: false,
            residentInPortugal: true,
          ),
        ],
      ),
    );
    expect(result.status, IrsJovemEligibility.needsMoreInformation);
  });

  test('ano em falta no histórico interrompido pede mais informação', () {
    final result = engine.evaluate(
      ageAtYearEnd: 30,
      categoryAIncome: const Money.fromCents(100000),
      answers: const IrsJovemAnswers(
        requested: true,
        taxSituationRegularized: true,
        historyConfirmedComplete: true,
        incomeHistory: [
          IrsJovemIncomeYear(
            year: 2024,
            hadCategoryAIncome: true,
            hadCategoryBIncome: false,
            wasDependent: false,
            residentInPortugal: true,
          ),
          IrsJovemIncomeYear(
            year: 2026,
            hadCategoryAIncome: true,
            hadCategoryBIncome: false,
            wasDependent: false,
            residentInPortugal: true,
          ),
        ],
      ),
    );
    expect(result.status, IrsJovemEligibility.needsMoreInformation);
    expect(result.reasons.single, contains('2025'));
  });

  test('ano duplicado pede mais informação', () {
    const duplicate = IrsJovemIncomeYear(
      year: 2026,
      hadCategoryAIncome: true,
      hadCategoryBIncome: false,
      wasDependent: false,
      residentInPortugal: true,
    );
    final result = engine.evaluate(
      ageAtYearEnd: 30,
      categoryAIncome: const Money.fromCents(100000),
      answers: const IrsJovemAnswers(
        requested: true,
        taxSituationRegularized: true,
        historyConfirmedComplete: true,
        incomeHistory: [duplicate, duplicate],
      ),
    );
    expect(result.status, IrsJovemEligibility.needsMoreInformation);
  });

  test('regime incompatível num ano histórico torna o titular inelegível', () {
    final result = engine.evaluate(
      ageAtYearEnd: 30,
      categoryAIncome: const Money.fromCents(100000),
      answers: const IrsJovemAnswers(
        requested: true,
        taxSituationRegularized: true,
        historyConfirmedComplete: true,
        incomeHistory: [
          IrsJovemIncomeYear(
            year: 2026,
            hadCategoryAIncome: true,
            hadCategoryBIncome: false,
            wasDependent: false,
            residentInPortugal: true,
            usedIncompatibleRegime: true,
          ),
        ],
      ),
    );
    expect(result.status, IrsJovemEligibility.notEligible);
  });

  test('A/B em ano anterior de não residência pede validação adicional', () {
    final result = engine.evaluate(
      ageAtYearEnd: 30,
      categoryAIncome: const Money.fromCents(100000),
      answers: const IrsJovemAnswers(
        requested: true,
        taxSituationRegularized: true,
        historyConfirmedComplete: true,
        incomeHistory: [
          IrsJovemIncomeYear(
            year: 2025,
            hadCategoryAIncome: true,
            hadCategoryBIncome: false,
            wasDependent: false,
            residentInPortugal: false,
          ),
          IrsJovemIncomeYear(
            year: 2026,
            hadCategoryAIncome: true,
            hadCategoryBIncome: false,
            wasDependent: false,
            residentInPortugal: true,
          ),
        ],
      ),
    );
    expect(result.status, IrsJovemEligibility.needsMoreInformation);
  });

  test('Categoria B é contada na elegibilidade mas não liquidada como A', () {
    final result = engine.evaluate(
      ageAtYearEnd: 30,
      categoryAIncome: Money.zero,
      answers: const IrsJovemAnswers(
        requested: true,
        taxSituationRegularized: true,
        historyConfirmedComplete: true,
        incomeHistory: [
          IrsJovemIncomeYear(
            year: 2026,
            hadCategoryAIncome: false,
            hadCategoryBIncome: true,
            wasDependent: false,
            residentInPortugal: true,
          ),
        ],
      ),
    );
    expect(result.status, IrsJovemEligibility.eligible);
    expect(result.eligibleExemptIncome, Money.zero);
  });
}

IrsJovemAnswers _answers({
  int year = 1,
  bool dependent = false,
  bool regularized = true,
  bool rnh = false,
  bool returnProgram = false,
}) => IrsJovemAnswers(
  requested: true,
  wasDependentAtYearEnd: dependent,
  qualifyingIncomeYears: year,
  taxSituationRegularized: regularized,
  usedRnhOrIfici: rnh,
  usedReturnProgram: returnProgram,
);
