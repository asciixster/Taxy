import assert from 'node:assert/strict';
import test from 'node:test';

import {
  normalizePortalPrefillModel,
  summarizeNormalizedPrefill,
} from '../../src/portal_prefill_normalizer.mjs';

const fixture = () => ({
  rosto: { quadro06: { Rostoq06BT01: [{ nif: 999999990 }, { nif: 999999981 }] } },
  anexoA: {
    quadro04: {
      AnexoAq04AT01: [
        {
          nif: 999999972,
          CodRendimentos: '401',
          Titular: 'A',
          Rendimentos: 1000000,
          Retencoes: 120000,
          Contribuicoes: 110000,
          Quotizacoes: 1000,
        },
        {
          nif: 999999963,
          CodRendimentos: '401',
          Titular: 'A',
          Rendimentos: 500000,
          Retencoes: 60000,
          Contribuicoes: 55000,
          Quotizacoes: 500,
        },
      ],
      AnexoAq04AT01SomaC01: 1500000,
      AnexoAq04AT01SomaC02: 180000,
      AnexoAq04AT01SomaC03: 165000,
      AnexoAq04AT01SomaC04: 1500,
    },
  },
  anexoC: [{
    quadro06: {
      AnexoCq06C601: 300000,
      AnexoCq06C602: 75000,
      AnexoCq06C603: 25000,
      AnexoCq06C604: null,
    },
  }],
  anexoH: { quadro06: {} },
});

test('normalizes exact official fields in integer cents without retaining NIFs', () => {
  const result = normalizePortalPrefillModel(fixture(), { taxYear: 2025 });
  assert.deepEqual(result.annexes, ['A', 'C', 'H']);
  assert.equal(result.household.memberCount, 2);
  assert.equal(result.categoryA.rows.length, 2);
  assert.equal(result.categoryA.totals.grossIncomeCents, 1500000);
  assert.equal(result.categoryA.totals.withholdingCents, 180000);
  assert.equal(result.categoryA.totalsMatchOfficialSummary, true);
  assert.equal(result.categoryB.regime, 'ORGANIZED_ACCOUNTING');
  assert.equal(result.categoryB.paymentsOnAccountCents, 25000);
  assert.doesNotMatch(JSON.stringify(result), /9999999|\bnif\b/i);
});

test('every normalized value remains a confirmation candidate, never a TaxFact', () => {
  const result = normalizePortalPrefillModel(fixture(), { taxYear: 2025 });
  assert.ok(result.candidates.length > 0);
  assert.ok(result.candidates.every((item) => item.requiresUserConfirmation));
  assert.ok(result.candidates.every((item) => item.provenance === 'OFFICIAL_AT_PREFILL'));
  assert.doesNotMatch(JSON.stringify(result), /TaxFact/);
});

test('mismatched official totals fail closed by withholding the total candidate', () => {
  const input = fixture();
  input.anexoA.quadro04.AnexoAq04AT01SomaC01 += 1;
  const result = normalizePortalPrefillModel(input, { taxYear: 2025 });
  assert.equal(result.categoryA.totalsMatchOfficialSummary, false);
  assert.equal(result.candidates.some((item) => item.field === 'categoryATotals'), false);
});

test('empty and zero remain distinct', () => {
  const input = fixture();
  input.anexoC[0].quadro06.AnexoCq06C603 = 0;
  input.anexoC[0].quadro06.AnexoCq06C604 = null;
  const result = normalizePortalPrefillModel(input, { taxYear: 2025 });
  assert.equal(result.categoryB.paymentsOnAccountCents, 0);
  assert.equal(result.categoryB.investmentTaxCreditCents, null);
  assert.deepEqual(
    summarizeNormalizedPrefill(result).categoryBFieldPresence,
    ['601', '602', '603'],
  );
});

test('invalid money and year values are rejected rather than approximated', () => {
  const money = fixture();
  money.anexoA.quadro04.AnexoAq04AT01[0].Rendimentos = '1.23';
  assert.throws(
    () => normalizePortalPrefillModel(money, { taxYear: 2025 }),
    /INVALID_MONEY_FIELD/,
  );
  assert.throws(
    () => normalizePortalPrefillModel(fixture(), { taxYear: 0 }),
    /INVALID_PREFILL_MODEL/,
  );
});
