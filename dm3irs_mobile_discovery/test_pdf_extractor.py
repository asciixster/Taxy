from __future__ import annotations

import io
import json
import subprocess
import sys
import unittest
from pathlib import Path

from reportlab.pdfgen import canvas

from pdf_extractor import extract_pdf


def sanitized_pdf_fixture() -> bytes:
    output = io.BytesIO()
    document = canvas.Canvas(output)
    lines = (
        "MODELO 3 - ANO DOS RENDIMENTOS 2024",
        "[X] Tributacao conjunta",
        "ANEXO A",
        "ANEXO B",
        "Agregado familiar",
        "Dependentes",
        "Rendimento global 12 345,67",
        "Rendimento coletavel 10 000,00",
        "Retencoes na fonte 1 234,56",
        "Valor a reembolsar 123,45",
    )
    y = 800
    for line in lines:
        document.drawString(60, y, line)
        y -= 28
    document.save()
    return output.getvalue()


class PdfExtractorTest(unittest.TestCase):
    def test_extracts_sanitized_fixture_deterministically(self) -> None:
        first = extract_pdf(sanitized_pdf_fixture())
        second = extract_pdf(sanitized_pdf_fixture())
        self.assertEqual(first.sanitized_summary(), second.sanitized_summary())
        self.assertEqual(first.field("tax_year").classification, "EXACT")
        self.assertEqual(first.field("taxation_type").classification, "EXACT")
        self.assertEqual(first.field("category_a").classification, "EXACT")
        self.assertEqual(first.field("category_b").classification, "EXACT")
        self.assertEqual(first.field("global_income").classification, "EXACT")
        self.assertEqual(first.field("taxable_income").classification, "EXACT")
        self.assertEqual(first.field("withholding").classification, "EXACT")
        self.assertEqual(first.field("tax_or_refund").classification, "EXACT")
        self.assertEqual(first.ocr_requirement, "NO")

    def test_never_invents_absent_fields(self) -> None:
        output = io.BytesIO()
        document = canvas.Canvas(output)
        document.drawString(60, 800, "Documento fiscal sintetico sem resultados")
        document.save()
        extraction = extract_pdf(output.getvalue())
        self.assertEqual(extraction.field("global_income").classification, "NOT_FOUND")
        self.assertEqual(extraction.field("taxable_income").classification, "NOT_FOUND")
        self.assertEqual(extraction.field("tax_or_refund").classification, "NOT_FOUND")

    def test_sanitized_summary_omits_values(self) -> None:
        summary = extract_pdf(sanitized_pdf_fixture()).sanitized_summary()
        self.assertNotIn("12 345,67", repr(summary))
        self.assertTrue(all("value" not in field for field in summary["fields"]))

    def test_stdin_probe_never_persists_pdf_or_values(self) -> None:
        fixture = sanitized_pdf_fixture()
        probe = Path(__file__).with_name("pdf_extractor_probe.py")
        completed = subprocess.run(
            [sys.executable, str(probe), "-"],
            input=fixture,
            capture_output=True,
            check=True,
        )
        summary = json.loads(completed.stdout)
        self.assertTrue(summary["pdf_text_layer"])
        self.assertNotIn("12 345,67", completed.stdout.decode("utf-8"))


if __name__ == "__main__":
    unittest.main()
