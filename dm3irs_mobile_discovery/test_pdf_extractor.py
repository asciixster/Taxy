from __future__ import annotations

import io
import json
import subprocess
import sys
import unittest
from pathlib import Path

from reportlab.pdfgen import canvas

from pdf_extractor import extract_pdf


def _grid(document, rows, *, x=40, y=690, widths=(190, 50, 100), height=22):
    for row_index, row in enumerate(rows):
        top = y - row_index * height
        cursor = x
        for column_index, width in enumerate(widths):
            document.rect(cursor, top - height, width, height)
            if column_index < len(row) and row[column_index]:
                document.drawString(cursor + 4, top - 15, row[column_index])
            cursor += width


def structural_fixture() -> bytes:
    output = io.BytesIO()
    document = canvas.Canvas(output)
    document.drawString(40, 800, "ROSTO")
    document.showPage()
    _grid(document, [("ANEXOS", "Quantidade"), ("Anexo A", "1"), ("Anexo C", "1"), ("Anexo H", "1"), ("Anexo SS", "1")], widths=(130, 60))
    document.showPage()
    document.drawString(40, 800, "MODELO 3 Anexo A")
    document.drawString(40, 770, "QUADRO 4A")
    document.drawString(65, 700, "999999990")
    document.drawString(150, 700, "401")
    document.drawString(181, 700, "A")
    document.drawString(233, 700, "123,45")
    document.drawString(315, 700, "123,45")
    document.drawString(394, 700, "123,45")
    document.drawString(549, 700, "123,45")
    document.showPage()
    document.drawString(40, 800, "MODELO 3 Anexo C")
    document.drawString(40, 775, "RENDIMENTOS DA CATEGORIA B")
    document.drawString(40, 750, "07 4015")
    _grid(document, [("Resultado liquido", "401", "123,45"), ("Lucro tributavel", "470", "123,45")])
    _grid(document, [("601", "123,45", "602", "123,45", "603", "")], y=560, widths=(45, 75, 45, 75, 45, 75))
    document.showPage()
    document.drawString(40, 800, "MODELO 3 Anexo H")
    _grid(document, [("Deducao", "601", "123,45")])
    document.showPage()
    document.drawString(40, 800, "MODELO 3 ANEXO SS")
    _grid(document, [("Servicos", "406", "123,45")])
    document.save()
    return output.getvalue()


class PdfExtractorTest(unittest.TestCase):
    def test_routes_annexes_and_owns_values_by_code_cell(self) -> None:
        extraction = extract_pdf(structural_fixture())
        summary = extraction.sanitized_summary()
        self.assertEqual(summary["annexes_detected"], {"A": 1, "C": 1, "H": 1, "SS": 1})
        self.assertEqual(extraction.coded_field("C", "401").classification, "EXACT")
        self.assertEqual(extraction.coded_field("C", "470").classification, "EXACT")
        self.assertEqual(extraction.coded_field("C", "442").classification, "REJECTED")

    def test_repeated_code_in_label_does_not_steal_value(self) -> None:
        extraction = extract_pdf(structural_fixture())
        self.assertEqual(extraction.coded_field("C", "442").classification, "REJECTED")

    def test_multiple_field_codes_use_their_own_cells(self) -> None:
        extraction = extract_pdf(structural_fixture())
        self.assertEqual(extraction.coded_field("C", "601").classification, "EXACT")
        self.assertEqual(extraction.coded_field("C", "602").classification, "EXACT")
        self.assertEqual(extraction.coded_field("C", "603").classification, "REJECTED")

    def test_annex_a_uses_table_column_coordinates(self) -> None:
        rows = extract_pdf(structural_fixture()).annex_a_rows
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0].income_code, "401")
        self.assertTrue(rows[0].nif_present)
        self.assertIn("withholding", rows[0].populated_columns)
        self.assertNotIn("surtax_withholding", rows[0].populated_columns)

    def test_summary_never_exposes_values(self) -> None:
        summary = extract_pdf(structural_fixture()).sanitized_summary()
        self.assertNotIn("123,45", repr(summary))
        self.assertTrue(all("value" not in item for item in summary["fields"]))

    def test_stdin_probe_never_persists_pdf_or_values(self) -> None:
        fixture = structural_fixture()
        probe = Path(__file__).with_name("pdf_extractor_probe.py")
        completed = subprocess.run([sys.executable, str(probe), "-"], input=fixture, capture_output=True, check=True)
        summary = json.loads(completed.stdout)
        self.assertEqual(summary["parser_model"], "ANNEX->QUADRO->FIELD_CODE->CELL")
        self.assertNotIn("123,45", completed.stdout.decode("utf-8"))


if __name__ == "__main__":
    unittest.main()
