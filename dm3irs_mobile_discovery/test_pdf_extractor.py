from __future__ import annotations

import json
import subprocess
import sys
import unittest
from pathlib import Path

from pdf_extractor import extract_pdf
from pdf_synthetic_fixtures import SYNTHETIC_FIXTURES, build_fixture


def extraction(name: str):
    return extract_pdf(build_fixture(SYNTHETIC_FIXTURES[name]))


class PdfExtractorStructuralTest(unittest.TestCase):
    def test_fixture_inventory_is_explicit(self) -> None:
        self.assertEqual(len(SYNTHETIC_FIXTURES), 10)

    def test_field_603_filled_is_exact(self) -> None:
        self.assertEqual(extraction("field_filled").coded_field("C", "603").classification, "EXACT")

    def test_field_603_empty_is_rejected_not_zero(self) -> None:
        field = extraction("field_empty").coded_field("C", "603")
        self.assertEqual(field.classification, "REJECTED")
        self.assertIsNone(field.value)

    def test_zero_is_present_and_distinct_from_empty(self) -> None:
        zero = extraction("zero_value").coded_field("C", "603")
        empty = extraction("field_empty").coded_field("C", "603")
        self.assertEqual((zero.classification, zero.value), ("EXACT", "0,00"))
        self.assertEqual((empty.classification, empty.value), ("REJECTED", None))

    def test_multiple_annex_a_lines_keep_column_ownership(self) -> None:
        rows = extraction("multiple_lines").annex_a_rows
        self.assertEqual(len(rows), 3)
        self.assertTrue(all(row.classification == "EXACT" for row in rows))
        self.assertTrue(all(row.nif_present for row in rows))
        self.assertTrue(all("withholding" in row.populated_columns for row in rows))

    def test_checkboxes_require_code_relative_coordinates(self) -> None:
        parsed = extraction("checkboxes")
        self.assertEqual(parsed.category_b_regime, "REGIME_SIMPLIFICADO")
        self.assertFalse(parsed.ss_more_than_half_single_entity)

    def test_alternative_469_excludes_empty_470(self) -> None:
        parsed = extraction("alternative_field")
        self.assertEqual(parsed.coded_field("C", "469").classification, "EXACT")
        self.assertEqual(parsed.coded_field("C", "470").classification, "REJECTED")

    def test_annex_absent_is_not_routed_or_inferred(self) -> None:
        parsed = extraction("annex_absent")
        self.assertNotIn("C", parsed.sanitized_summary()["annexes_detected"])
        self.assertFalse(parsed.category_b_detected)
        self.assertTrue(all(field.classification == "REJECTED" for field in parsed.fields_for("C")))

    def test_duplicate_filled_page_is_ambiguous_and_never_exact(self) -> None:
        field = extraction("duplicate_page").coded_field("C", "603")
        self.assertEqual(field.classification, "AMBIGUOUS")
        self.assertIsNone(field.value)

    def test_annex_order_is_independent_of_routing(self) -> None:
        parsed = extraction("different_order")
        self.assertEqual(parsed.coded_field("C", "603").classification, "EXACT")
        self.assertEqual(set(parsed.sanitized_summary()["annexes_detected"]), {"A", "C", "H", "SS"})

    def test_alternative_table_coordinates_are_supported(self) -> None:
        parsed = extraction("different_order")
        self.assertEqual(parsed.coded_field("C", "603").classification, "EXACT")

    def test_portuguese_money_formats_remain_owned_by_code(self) -> None:
        parsed = extraction("pt_money")
        self.assertEqual(parsed.coded_field("C", "601").value, "1.234,56")
        self.assertEqual(parsed.coded_field("C", "602").value, "1 234,56")
        self.assertEqual(parsed.coded_field("C", "604").value, "1234,56")

    def test_priority_fields_601_602_603_604_are_independent(self) -> None:
        parsed = extraction("field_filled")
        self.assertTrue(all(parsed.coded_field("C", code).classification == "EXACT" for code in ("601", "602", "603", "604")))

    def test_activity_code_and_organized_regime_are_structural(self) -> None:
        parsed = extraction("field_filled")
        self.assertTrue(parsed.activity_code_present)
        self.assertEqual(parsed.category_b_regime, "CONTABILIDADE_ORGANIZADA")

    def test_all_target_ss_codes_have_independent_cells(self) -> None:
        parsed = extraction("field_filled")
        for code in [*(str(code) for code in range(401, 410)), "501", "502"]:
            with self.subTest(code=code):
                self.assertEqual(parsed.coded_field("SS", code).classification, "EXACT")

    def test_label_text_cannot_create_a_field(self) -> None:
        parsed = extraction("field_empty")
        self.assertEqual(parsed.coded_field("C", "442").classification, "REJECTED")

    def test_sanitized_summary_omits_all_values(self) -> None:
        summary = extraction("field_filled").sanitized_summary()
        self.assertNotIn("12.345,67", repr(summary))
        self.assertTrue(all("value" not in item for item in summary["fields"]))

    def test_stdin_probe_never_persists_pdf_or_values(self) -> None:
        fixture = build_fixture(SYNTHETIC_FIXTURES["field_filled"])
        probe = Path(__file__).with_name("pdf_extractor_probe.py")
        completed = subprocess.run([sys.executable, str(probe), "-"], input=fixture, capture_output=True, check=True)
        summary = json.loads(completed.stdout)
        self.assertEqual(summary["parser_model"], "ANNEX->QUADRO->FIELD_CODE->CELL")
        self.assertNotIn("12.345,67", completed.stdout.decode("utf-8"))


if __name__ == "__main__":
    unittest.main()
