"""Offline, research-only parser for DM3IRS PDF responses.

The parser accepts bytes, keeps extracted values in memory, and exposes a sanitized
summary that never contains taxpayer values. It is not imported by the Taxy app.
"""

from __future__ import annotations

import io
import re
import unicodedata
from dataclasses import asdict, dataclass
from typing import Iterable

import pdfplumber
from pypdf import PdfReader


CONFIDENCE = ("EXACT", "HIGH_CONFIDENCE", "LOW_CONFIDENCE", "NOT_FOUND")
MONEY = re.compile(r"(?<!\d)(?:\d{1,3}(?:[.\s]\d{3})+|\d+)[,.]\d{2}(?!\d)")
YEAR = re.compile(r"\b(?:19|20)\d{2}\b")
CHOICE_MARKER = re.compile(r"(?:^|\s)(?:x|\[x\]|☒)(?:\s|$)", re.IGNORECASE)


def normalize(value: str) -> str:
    value = unicodedata.normalize("NFKD", value)
    value = "".join(char for char in value if not unicodedata.combining(char))
    return re.sub(r"\s+", " ", value).strip().lower()


def resolve(value):
    return value.get_object() if hasattr(value, "get_object") else value


@dataclass(frozen=True)
class ExtractedField:
    name: str
    classification: str
    page: int | None
    value: str | None = None
    anchor: str | None = None

    def __post_init__(self) -> None:
        if self.classification not in CONFIDENCE:
            raise ValueError(f"unsupported classification: {self.classification}")

    def sanitized(self) -> dict:
        result = asdict(self)
        result.pop("value")
        return result


@dataclass(frozen=True)
class PageStructure:
    page: int
    text_native: bool
    text_chars: int
    image_count: int
    table_count: int
    font_count: int
    embedded_font_count: int


@dataclass
class PdfExtraction:
    pages: list[PageStructure]
    fields: list[ExtractedField]
    acroform: bool
    xfa: bool

    @property
    def ocr_requirement(self) -> str:
        image_only = [page for page in self.pages if not page.text_native and page.image_count]
        if not image_only:
            return "NO"
        return "YES" if len(image_only) == len(self.pages) else "PARTIAL"

    def field(self, name: str) -> ExtractedField:
        return next(item for item in self.fields if item.name == name)

    def sanitized_summary(self) -> dict:
        found = [field for field in self.fields if field.classification != "NOT_FOUND"]
        categories = [
            label.removeprefix("category_").upper()
            for label in (field.name for field in found)
            if label.startswith("category_")
        ]
        household = [field for field in found if field.name in {"household", "dependents"}]
        category_b = [field for field in found if field.name.startswith("category_b")]
        tax_result_names = {
            "global_income",
            "taxable_income",
            "withholding",
            "tax_or_refund",
        }
        tax_results = [field for field in found if field.name in tax_result_names]
        counts = {classification: 0 for classification in CONFIDENCE}
        for field in self.fields:
            counts[field.classification] += 1
        return {
            "pdf_text_layer": any(page.text_native for page in self.pages),
            "acroform": self.acroform,
            "xfa": self.xfa,
            "native_text_extraction_works": any(page.text_chars for page in self.pages),
            "ocr_required": self.ocr_requirement,
            "pages_structurally_parsed": len(self.pages),
            "image_only_pages": sum(
                not page.text_native and page.image_count > 0 for page in self.pages
            ),
            "fields_extracted": len(found),
            "confidence_counts": counts,
            "income_categories_detected": categories,
            "household_fields_detected": len(household),
            "category_b_fields_detected": len(category_b),
            "tax_result_fields_detected": len(tax_results),
            "fonts": sum(page.font_count for page in self.pages),
            "embedded_fonts": sum(page.embedded_font_count for page in self.pages),
            "tables": sum(page.table_count for page in self.pages),
            "parser_deterministic": True,
            "fields": [field.sanitized() for field in self.fields],
        }


def _line_records(page) -> list[tuple[str, str]]:
    text = page.extract_text(x_tolerance=2, y_tolerance=3) or ""
    return [(line, normalize(line)) for line in text.splitlines() if line.strip()]


def _field_by_anchor(
    pages: list[list[tuple[str, str]]],
    name: str,
    anchors: Iterable[str],
    *,
    value_pattern: re.Pattern[str] | None = MONEY,
) -> ExtractedField:
    for page_number, lines in enumerate(pages, 1):
        for raw, line in lines:
            matched_anchor = next((anchor for anchor in anchors if anchor in line), None)
            if not matched_anchor:
                continue
            if value_pattern is None:
                return ExtractedField(name, "LOW_CONFIDENCE", page_number, anchor=matched_anchor)
            match = value_pattern.search(raw)
            if match:
                return ExtractedField(
                    name,
                    "EXACT",
                    page_number,
                    value=match.group(0),
                    anchor=matched_anchor,
                )
            return ExtractedField(name, "LOW_CONFIDENCE", page_number, anchor=matched_anchor)
    return ExtractedField(name, "NOT_FOUND", None)


def _selected_choice(
    pages: list[list[tuple[str, str]]], name: str, choices: Iterable[str]
) -> ExtractedField:
    for page_number, lines in enumerate(pages, 1):
        for index, (raw, line) in enumerate(lines):
            choice = next((candidate for candidate in choices if candidate in line), None)
            if not choice:
                continue
            if CHOICE_MARKER.search(raw):
                return ExtractedField(name, "EXACT", page_number, value=choice, anchor=choice)
            # The official PDF sometimes places the mark in a separate text run.
            adjacent = " ".join(
                lines[position][0]
                for position in range(max(0, index - 1), min(len(lines), index + 2))
            )
            if CHOICE_MARKER.search(adjacent):
                return ExtractedField(
                    name, "HIGH_CONFIDENCE", page_number, value=choice, anchor=choice
                )
            return ExtractedField(name, "LOW_CONFIDENCE", page_number, anchor=choice)
    return ExtractedField(name, "NOT_FOUND", None)


def _present_annexes(pages: list[list[tuple[str, str]]]) -> dict[str, int]:
    present: dict[str, int] = {}
    for page_number, lines in enumerate(pages, 1):
        top = " ".join(line for _, line in lines[:20])
        markers = set(re.findall(r"\banexo\s+([a-z](?:1)?)\b", top))
        # A checklist/index names many annexes; a real annex header names very few.
        all_annexes = set(re.findall(r"\banexo\s+([a-z](?:1)?)\b", top))
        if len(all_annexes) > 3:
            continue
        for marker in markers:
            present.setdefault(marker, page_number)
    return present


def _semantic_marker(
    pages: list[list[tuple[str, str]]], name: str, anchors: Iterable[str]
) -> ExtractedField:
    for page_number, lines in enumerate(pages, 1):
        for _, line in lines:
            anchor = next((candidate for candidate in anchors if candidate in line), None)
            if anchor:
                return ExtractedField(name, "EXACT", page_number, value=anchor, anchor=anchor)
    return ExtractedField(name, "NOT_FOUND", None)


def extract_pdf(pdf_bytes: bytes) -> PdfExtraction:
    reader = PdfReader(io.BytesIO(pdf_bytes), strict=False)
    root = resolve(reader.trailer["/Root"])
    acroform_object = resolve(root.get("/AcroForm")) if root.get("/AcroForm") else None
    acroform = bool(acroform_object)
    xfa = bool(acroform_object and acroform_object.get("/XFA"))

    page_structures: list[PageStructure] = []
    page_lines: list[list[tuple[str, str]]] = []
    with pdfplumber.open(io.BytesIO(pdf_bytes)) as plumber_pdf:
        for index, (reader_page, plumber_page) in enumerate(
            zip(reader.pages, plumber_pdf.pages), 1
        ):
            lines = _line_records(plumber_page)
            page_lines.append(lines)
            char_count = len(re.sub(r"\s+", "", " ".join(raw for raw, _ in lines)))

            resources = resolve(reader_page.get("/Resources")) or {}
            fonts = resolve(resources.get("/Font")) or {}
            embedded = 0
            for font_reference in fonts.values():
                font = resolve(font_reference)
                descriptor_reference = font.get("/FontDescriptor")
                if not descriptor_reference:
                    continue
                descriptor = resolve(descriptor_reference)
                if any(
                    descriptor.get(key) for key in ("/FontFile", "/FontFile2", "/FontFile3")
                ):
                    embedded += 1

            xobjects = resolve(resources.get("/XObject")) or {}
            images = sum(
                resolve(reference).get("/Subtype") == "/Image"
                for reference in xobjects.values()
            )
            try:
                tables = len(plumber_page.find_tables())
            except Exception:
                tables = 0
            page_structures.append(
                PageStructure(
                    page=index,
                    text_native=char_count >= 40,
                    text_chars=char_count,
                    image_count=images,
                    table_count=tables,
                    font_count=len(fonts),
                    embedded_font_count=embedded,
                )
            )

    annexes = _present_annexes(page_lines)
    fields = [
        _field_by_anchor(
            page_lines,
            "tax_year",
            ("ano dos rendimentos", "ano fiscal", "exercicio"),
            value_pattern=YEAR,
        ),
        _selected_choice(
            page_lines,
            "taxation_type",
            ("tributacao conjunta", "tributacao separada"),
        ),
        *[
            ExtractedField(
                f"category_{annex.lower()}",
                "EXACT" if annex.lower() in annexes else "NOT_FOUND",
                annexes.get(annex.lower()),
                anchor=f"anexo {annex.lower()}" if annex.lower() in annexes else None,
            )
            for annex in ("A", "B", "F")
        ],
        _semantic_marker(
            page_lines, "category_h", ("categoria h", "rendimentos de pensoes")
        ),
        ExtractedField(
            "annex_j",
            "EXACT" if "j" in annexes else "NOT_FOUND",
            annexes.get("j"),
            value="anexo j" if "j" in annexes else None,
            anchor="anexo j" if "j" in annexes else None,
        ),
        _field_by_anchor(
            page_lines, "household", ("agregado familiar",), value_pattern=None
        ),
        _field_by_anchor(
            page_lines, "dependents", ("dependentes",), value_pattern=None
        ),
        _field_by_anchor(page_lines, "global_income", ("rendimento global",)),
        _field_by_anchor(page_lines, "taxable_income", ("rendimento coletavel",)),
        _field_by_anchor(
            page_lines, "withholding", ("retencoes na fonte", "retencoes")
        ),
        _field_by_anchor(
            page_lines,
            "tax_or_refund",
            (
                "valor a pagar",
                "valor a reembolsar",
                "reembolso",
                "imposto apurado",
                "resultado final",
            ),
        ),
    ]
    return PdfExtraction(page_structures, fields, acroform, xfa)
