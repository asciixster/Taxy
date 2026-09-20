const isRecord = (value) => value !== null && typeof value === 'object' &&
  !Array.isArray(value);

const at = (value, ...path) => {
  let current = value;
  for (const segment of path) {
    if (current == null) return null;
    current = current[segment];
  }
  return current ?? null;
};

const cents = (value, field) => {
  if (value === null || value === undefined || value === '') return null;
  if (typeof value === 'string' && /^\d+$/.test(value)) value = Number(value);
  if (!Number.isSafeInteger(value) || value < 0) {
    throw new Error(`INVALID_MONEY_FIELD:${field}`);
  }
  return value;
};

const code = (value, field, pattern = /^[A-Za-z0-9]+$/) => {
  if (value === null || value === undefined || value === '') return null;
  const normalized = String(value).trim();
  if (!pattern.test(normalized)) throw new Error(`INVALID_CODE_FIELD:${field}`);
  return normalized;
};

const sum = (rows, key) => rows.reduce((total, row) => total + (row[key] ?? 0), 0);

const officialCandidate = (field, value, confidence = 'EXACT') => ({
  field,
  value,
  confidence,
  provenance: 'OFFICIAL_AT_PREFILL',
  requiresUserConfirmation: true,
});

export function normalizePortalPrefillModel(model, { taxYear }) {
  if (!isRecord(model) || !Number.isInteger(taxYear) || taxYear < 2000 || taxYear > 2100) {
    throw new Error('INVALID_PREFILL_MODEL');
  }

  const annexes = [];
  if (isRecord(model.anexoA)) annexes.push('A');
  if (Array.isArray(model.anexoC) && model.anexoC.length > 0) annexes.push('C');
  if (isRecord(model.anexoH)) annexes.push('H');

  const householdRows = at(model, 'rosto', 'quadro06', 'Rostoq06BT01');
  const householdMemberCount = Array.isArray(householdRows)
    ? householdRows.filter((row) => isRecord(row) && row.nif != null).length
    : 0;

  const rawCategoryA = at(model, 'anexoA', 'quadro04', 'AnexoAq04AT01');
  const categoryARows = (Array.isArray(rawCategoryA) ? rawCategoryA : [])
    .filter(isRecord)
    .map((row, index) => ({
      incomeCode: code(row.CodRendimentos, `A.4A.${index}.incomeCode`),
      holder: code(row.Titular, `A.4A.${index}.holder`),
      grossIncomeCents: cents(row.Rendimentos, `A.4A.${index}.grossIncome`),
      withholdingCents: cents(row.Retencoes, `A.4A.${index}.withholding`),
      socialSecurityCents: cents(row.Contribuicoes, `A.4A.${index}.socialSecurity`),
      unionDuesCents: cents(row.Quotizacoes, `A.4A.${index}.unionDues`),
    }))
    .filter((row) => Object.values(row).some((value) => value !== null));

  const categoryATotals = {
    grossIncomeCents: sum(categoryARows, 'grossIncomeCents'),
    withholdingCents: sum(categoryARows, 'withholdingCents'),
    socialSecurityCents: sum(categoryARows, 'socialSecurityCents'),
    unionDuesCents: sum(categoryARows, 'unionDuesCents'),
  };
  const officialCategoryATotals = {
    grossIncomeCents: cents(
      at(model, 'anexoA', 'quadro04', 'AnexoAq04AT01SomaC01'),
      'A.4A.totalGrossIncome',
    ),
    withholdingCents: cents(
      at(model, 'anexoA', 'quadro04', 'AnexoAq04AT01SomaC02'),
      'A.4A.totalWithholding',
    ),
    socialSecurityCents: cents(
      at(model, 'anexoA', 'quadro04', 'AnexoAq04AT01SomaC03'),
      'A.4A.totalSocialSecurity',
    ),
    unionDuesCents: cents(
      at(model, 'anexoA', 'quadro04', 'AnexoAq04AT01SomaC04'),
      'A.4A.totalUnionDues',
    ),
  };
  const categoryATotalsMatch = Object.entries(officialCategoryATotals).every(
    ([key, value]) => value === null || value === categoryATotals[key],
  );

  const categoryC = Array.isArray(model.anexoC) && isRecord(model.anexoC[0])
    ? model.anexoC[0]
    : null;
  const categoryB = categoryC === null ? null : {
    present: true,
    regime: 'ORGANIZED_ACCOUNTING',
    incomeSubjectToWithholdingCents: cents(
      at(categoryC, 'quadro06', 'AnexoCq06C601'),
      'C.6.601',
    ),
    withholdingCents: cents(at(categoryC, 'quadro06', 'AnexoCq06C602'), 'C.6.602'),
    paymentsOnAccountCents: cents(
      at(categoryC, 'quadro06', 'AnexoCq06C603'),
      'C.6.603',
    ),
    investmentTaxCreditCents: cents(
      at(categoryC, 'quadro06', 'AnexoCq06C604'),
      'C.6.604',
    ),
  };

  const candidates = [
    officialCandidate('taxYear', taxYear),
    officialCandidate('annexesPresent', annexes),
    officialCandidate('householdMemberCount', householdMemberCount),
    ifValue(categoryARows.length > 0, () => officialCandidate('categoryAPresent', true)),
    ifValue(categoryARows.length > 0 && categoryATotalsMatch, () =>
      officialCandidate('categoryATotals', categoryATotals)),
    ifValue(categoryB !== null, () => officialCandidate('categoryBPresent', true)),
    ifValue(categoryB !== null, () => officialCandidate('categoryBRegime', categoryB.regime)),
  ].filter(Boolean);

  return {
    schemaVersion: 1,
    taxYear,
    source: 'OFFICIAL_AT_PREFILL',
    annexes,
    household: { memberCount: householdMemberCount },
    categoryA: {
      rows: categoryARows,
      totals: categoryATotals,
      totalsMatchOfficialSummary: categoryATotalsMatch,
    },
    categoryB,
    candidates,
  };
}

const ifValue = (condition, create) => condition ? create() : null;

export function summarizeNormalizedPrefill(value) {
  return {
    schemaVersion: value.schemaVersion,
    taxYear: value.taxYear,
    annexes: value.annexes,
    householdMemberCount: value.household.memberCount,
    categoryARowCount: value.categoryA.rows.length,
    categoryATotalsMatchOfficialSummary:
      value.categoryA.totalsMatchOfficialSummary,
    categoryBPresent: value.categoryB?.present === true,
    categoryBRegime: value.categoryB?.regime ?? null,
    categoryBFieldPresence: value.categoryB === null ? [] : [
      ['601', value.categoryB.incomeSubjectToWithholdingCents],
      ['602', value.categoryB.withholdingCents],
      ['603', value.categoryB.paymentsOnAccountCents],
      ['604', value.categoryB.investmentTaxCreditCents],
    ].filter(([, fieldValue]) => fieldValue !== null).map(([field]) => field),
    candidateCount: value.candidates.length,
    requiresUserConfirmation: value.candidates.every(
      (candidate) => candidate.requiresUserConfirmation === true,
    ),
    identifiersRetained: false,
  };
}
