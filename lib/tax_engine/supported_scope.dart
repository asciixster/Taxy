import '../domain/models.dart';

final class ScopeValidationIssue {
  const ScopeValidationIssue(this.code, this.message);
  final String code;
  final String message;
}

/// Única porta de entrada para o âmbito fiscal suportado pela Taxy 0.3.
/// Qualquer situação não explicitamente validada falha de forma fechada.
final class SupportedScopeValidator {
  const SupportedScopeValidator(this.taxYear);
  final int taxYear;

  List<ScopeValidationIssue> validate(TaxSimulation simulation) {
    final p = simulation.profile;
    final s = simulation.situations;
    final issues = <ScopeValidationIssue>[];

    void reject(bool condition, String code, String message) {
      if (condition) issues.add(ScopeValidationIssue(code, message));
    }

    reject(
      p.taxYear != taxYear,
      'TAX_YEAR',
      'As regras de ${p.taxYear} ainda não estão validadas (NEEDS_VERIFICATION).',
    );
    final isCouple = p.civilStatus != CivilStatus.single;
    reject(
      isCouple && simulation.secondaryTaxpayer == null,
      'SECOND_TAXPAYER_REQUIRED',
      'Casados e unidos de facto exigem dados completos dos dois titulares.',
    );
    reject(
      !isCouple && simulation.secondaryTaxpayer != null,
      'UNEXPECTED_SECOND_TAXPAYER',
      'Um segundo titular só é permitido num casal ou união de facto.',
    );
    reject(
      !isCouple && p.filingMode == FilingMode.joint,
      'JOINT_REQUIRES_COUPLE',
      'A tributação conjunta exige casamento ou união de facto.',
    );
    reject(
      !p.fullYearResident,
      'PARTIAL_RESIDENCE',
      'Residência fiscal parcial ainda não está validada (NEEDS_VERIFICATION).',
    );
    reject(
      p.taxYear == 2025 && p.region != TaxRegion.continent,
      'REGION_YEAR',
      'Em 2025 apenas o Continente está validado (NEEDS_VERIFICATION).',
    );
    reject(
      p.dependents > 0 &&
          p.civilStatus == CivilStatus.single &&
          !p.isSingleParentHousehold,
      'DEPENDENTS_HOUSEHOLD_STATUS',
      'Agregados com dependentes só são calculados após confirmação de família monoparental standard (NEEDS_VERIFICATION).',
    );
    reject(
      p.dependents == 0 && p.isSingleParentHousehold,
      'INVALID_SINGLE_PARENT',
      'Uma família monoparental deve incluir pelo menos um dependente.',
    );
    reject(
      isCouple && p.isSingleParentHousehold,
      'INVALID_SINGLE_PARENT_COUPLE',
      'Um casal não pode ser tratado como família monoparental.',
    );
    reject(
      simulation.dependents.any(
        (dependent) =>
            dependent.sharedCustody || dependent.alternatingResidence,
      ),
      'SHARED_CUSTODY',
      'Guarda partilhada ou residência alternada permanece NEEDS_VERIFICATION.',
    );
    reject(
      simulation.dependents.any(
        (dependent) => dependent.allocation != DependentAllocation.household,
      ),
      'DEPENDENT_ALLOCATION',
      'Alocação especial de dependentes a um titular permanece NEEDS_VERIFICATION.',
    );
    reject(
      simulation.incomeTypes.any((type) => type != IncomeType.employment),
      'UNSUPPORTED_INCOME_TYPE',
      'A simulação inclui tipos de rendimento ainda não suportados.',
    );
    reject(
      p.dependentAges.any((age) => age < 0 || age > 25),
      'DEPENDENT_AGE',
      'A idade de um dependente está fora do âmbito validado.',
    );

    reject(
      s.irsJovem,
      'IRS_JOVEM',
      'IRS Jovem ainda não é suportado (NEEDS_VERIFICATION).',
    );
    reject(
      s.categoryB,
      'CATEGORY_B',
      'Categoria B ainda não é suportada (NEEDS_VERIFICATION).',
    );
    reject(
      s.pensions,
      'PENSIONS',
      'Pensões ainda não são suportadas (NEEDS_VERIFICATION).',
    );
    reject(
      s.foreignIncome,
      'FOREIGN_INCOME',
      'Rendimentos estrangeiros ainda não são suportados (NEEDS_VERIFICATION).',
    );
    reject(
      s.capitalIncome,
      'CAPITAL_INCOME',
      'Rendimentos de capitais ainda não são suportados (NEEDS_VERIFICATION).',
    );
    reject(
      s.propertyIncome,
      'PROPERTY_INCOME',
      'Rendimentos prediais ainda não são suportados (NEEDS_VERIFICATION).',
    );
    reject(
      s.capitalGains,
      'CAPITAL_GAINS',
      'Mais-valias ainda não são suportadas (NEEDS_VERIFICATION).',
    );
    reject(
      s.disability,
      'DISABILITY',
      'Deficiência fiscalmente relevante ainda não é suportada (NEEDS_VERIFICATION).',
    );
    reject(
      s.displacedStudent,
      'DISPLACED_STUDENT',
      'Estudante deslocado ainda não é suportado (NEEDS_VERIFICATION).',
    );
    reject(
      s.sharedCustody,
      'SHARED_CUSTODY',
      'Residência alternada ou responsabilidades parentais partilhadas ainda não são suportadas (NEEDS_VERIFICATION).',
    );
    reject(
      s.otherSpecialSituation,
      'OTHER_SPECIAL',
      'A situação especial indicada ainda não é suportada (NEEDS_VERIFICATION).',
    );

    final monetary = <int>[
      simulation.income.gross.cents,
      simulation.income.withholding.cents,
      simulation.income.socialSecurity.cents,
      simulation.deductions.general.cents,
      simulation.deductions.health.cents,
      simulation.deductions.education.cents,
      simulation.deductions.rent.cents,
      simulation.deductions.careHomes.cents,
      simulation.deductions.invoiceVat15.cents,
      simulation.deductions.invoiceVat30.cents,
      simulation.deductions.invoiceVat35.cents,
      simulation.deductions.invoiceVat100.cents,
      simulation.deductions.ppr.cents,
      if (simulation.secondaryTaxpayer case final secondary?) ...[
        secondary.income.gross.cents,
        secondary.income.withholding.cents,
        secondary.income.socialSecurity.cents,
        ..._deductionCents(secondary.deductions),
      ],
      ..._deductionCents(simulation.dependentDeductions),
    ];
    reject(
      monetary.any((value) => value < 0),
      'NEGATIVE_VALUE',
      'Os valores monetários não podem ser negativos.',
    );
    return issues;
  }

  static List<int> _deductionCents(DeductionInput input) => [
    input.general.cents,
    input.health.cents,
    input.education.cents,
    input.rent.cents,
    input.careHomes.cents,
    input.invoiceVat15.cents,
    input.invoiceVat30.cents,
    input.invoiceVat35.cents,
    input.invoiceVat100.cents,
    input.ppr.cents,
  ];
}
