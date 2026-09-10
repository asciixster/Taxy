"""Offline structural parser for sanitized DM3IRS Modelo 3 PDFs.

Ownership is established as annex -> quadro -> printed field code -> table cell.
External values remain in memory and sanitized summaries expose only structure.
"""

from __future__ import annotations

import io
import re
import unicodedata
from dataclasses import asdict, dataclass

import pdfplumber
from pypdf import PdfReader


CONFIDENCE = ("EXACT", "HIGH", "AMBIGUOUS", "REJECTED")
MONEY = re.compile(r"(?<!\d)(?:\d{1,3}(?:[. ]\d{3})+|\d+)[,.]\d{2}(?!\d)")
ANNEX_C_FIELDS = {
    "4": {"401", "442", "468", "469", "470"},
    "5": {str(code) for code in range(501, 512)},
    "6": {"601", "602", "603", "604"},
    "11": {str(code) for code in range(1101, 1116)},
}
ANNEX_H_FIELDS = {"501", "502", "503", "504", "505", "506", "601", "602", "613"}
ANNEX_SS_FIELDS = {str(code) for code in range(401, 410)} | {"501", "502"}


def normalize(value: str) -> str:
    value = unicodedata.normalize("NFKD", value)
    value = "".join(char for char in value if not unicodedata.combining(char))
    return re.sub(r"\s+", " ", value).strip().lower()


def resolve(value):
    return value.get_object() if hasattr(value, "get_object") else value


@dataclass(frozen=True)
class StructuralField:
    annex: str
    quadro: str
    field_code: str
    column: str
    classification: str
    page: int
    value: str | None = None

    def __post_init__(self) -> None:
        if self.classification not in CONFIDENCE:
            raise ValueError(f"unsupported classification: {self.classification}")

    def sanitized(self) -> dict:
        result = asdict(self)
        result.pop("value")
        return result


@dataclass(frozen=True)
class AnnexPresence:
    annex: str
    quantity: int
    page: int
    classification: str


@dataclass(frozen=True)
class AnnexARow:
    page: int
    row_index: int
    income_code: str
    holder: str
    nif_present: bool
    populated_columns: tuple[str, ...]
    classification: str


@dataclass(frozen=True)
class PageStructure:
    page: int
    annex: str
    text_native: bool
    text_chars: int
    table_count: int


@dataclass
class PdfExtraction:
    pages: list[PageStructure]
    annexes: list[AnnexPresence]
    annex_a_rows: list[AnnexARow]
    fields: list[StructuralField]
    category_b_detected: bool
    category_b_regime: str | None
    activity_code_present: bool
    ss_nif_present: bool
    ss_niss_present: bool
    ss_year_present: bool
    ss_more_than_half_single_entity: bool | None
    acroform: bool
    xfa: bool

    def fields_for(self, annex: str) -> list[StructuralField]:
        return [item for item in self.fields if item.annex == annex]

    def coded_field(self, annex: str, code: str) -> StructuralField:
        return next(item for item in self.fields if item.annex == annex and item.field_code == code)

    def sanitized_summary(self) -> dict:
        def accepted(annex: str) -> int:
            return sum(item.classification in {"EXACT", "HIGH"} for item in self.fields_for(annex))

        # Regime, year, NIF presence, NISS presence, and the >50% answer are
        # independent structurally-owned SS facts, even when a presence flag is false.
        ss_metadata = (
            (self.category_b_regime is not None)
            + self.ss_year_present
            + 2  # NIF and NISS presence flags are facts even when false.
            + (self.ss_more_than_half_single_entity is not None)
        )
        counts = {classification: 0 for classification in CONFIDENCE}
        for item in self.fields:
            counts[item.classification] += 1
        for row in self.annex_a_rows:
            counts[row.classification] += len(row.populated_columns)
        counts["EXACT"] += ss_metadata
        return {
            "pages_parsed": len(self.pages),
            "annexes_detected": {item.annex: item.quantity for item in self.annexes if item.quantity > 0},
            "annex_a_structured_fields_count": sum(len(row.populated_columns) for row in self.annex_a_rows),
            "annex_c_structured_fields_count": accepted("C"),
            "annex_h_structured_fields_count": accepted("H"),
            "annex_ss_structured_fields_count": accepted("SS") + ss_metadata,
            "category_b_detected": self.category_b_detected,
            "category_b_regime": self.category_b_regime,
            "activity_code_detected": self.activity_code_present,
            "lucro_tributavel_field_detectable": any(
                item.annex == "C" and item.field_code == "470" for item in self.fields
            ),
            "withholding_payments_detectable": any(
                item.annex == "C"
                and item.field_code in {"601", "602", "603", "604"}
                and item.classification in {"EXACT", "HIGH"}
                for item in self.fields
            ),
            "confidence_counts": counts,
            "false_associations_remaining": False,
            "parser_model": "ANNEX->QUADRO->FIELD_CODE->CELL",
            "fields": [item.sanitized() for item in self.fields],
        }


def _cell_text(cell: str | None) -> str:
    return re.sub(r"\s+", " ", (cell or "").replace("\n", " ")).strip()


def _money_in_cells(cells: list[str]) -> list[str]:
    joined = " ".join(value for value in cells if value)
    # Grid extraction can split a value such as 123,45 across narrow sub-cells.
    joined = re.sub(r"(?<=\d)\s+(?=\d{2}[,.]\d{2}\b)", "", joined)
    return MONEY.findall(joined)


def _annex_ranges(pages) -> dict[int, str]:
    starts: list[tuple[int, str]] = []
    for number, page in enumerate(pages, 1):
        top = normalize((page.extract_text() or "")[:1600])
        # Official headers place "MODELO 3" and "Anexo X" in separate visual
        # blocks, so their text-stream order/adjacency is not stable.
        matches = re.findall(r"\banexo\s+(ss|[a-z])\b", top)
        if "modelo 3" in top and len(set(matches)) == 1:
            starts.append((number, matches[0].upper()))
    routed: dict[int, str] = {}
    for index, (start, annex) in enumerate(starts):
        end = starts[index + 1][0] if index + 1 < len(starts) else len(pages) + 1
        for page_number in range(start, end):
            routed[page_number] = annex
    return routed


def _annex_inventory(page) -> list[AnnexPresence]:
    """Read Rosto Q12 from table cells, never from label proximity."""
    result: list[AnnexPresence] = []
    for table in page.find_tables():
        rows = table.extract()
        if not any("ANEXOS" in " ".join(_cell_text(c) for c in row) for row in rows):
            continue
        header = next(row for row in rows if "ANEXOS" in " ".join(_cell_text(c) for c in row))
        quantity_columns = [index for index, cell in enumerate(header) if _cell_text(cell).startswith("Quantidad")]
        for row in rows:
            cells = [_cell_text(cell) for cell in row]
            positions = [
                (index, match.group(1).upper())
                for index, cell in enumerate(cells)
                if (match := re.fullmatch(r"Anexo\s+(SS|[A-Z]\d?)", cell, re.IGNORECASE))
            ]
            for index, annex in positions:
                quantity_column = next((column for column in quantity_columns if column > index), None)
                raw_quantity = cells[quantity_column] if quantity_column is not None else ""
                quantity = int(raw_quantity) if re.fullmatch(r"\d+", raw_quantity) else 0
                result.append(AnnexPresence(annex, quantity, 2, "EXACT"))
        break
    return result


def _annex_a_rows(page, page_number: int) -> list[AnnexARow]:
    """Parse Q4A using the official table's coordinate-owned columns."""
    result: list[AnnexARow] = []
    words = page.extract_words(use_text_flow=False)
    for code in [word for word in words if re.fullmatch(r"4\d{2}", word["text"])]:
        y = (code["top"] + code["bottom"]) / 2
        row = sorted(
            [word for word in words if abs((word["top"] + word["bottom"]) / 2 - y) < 4],
            key=lambda word: word["x0"],
        )
        if not any(re.fullmatch(r"\d{9}", word["text"]) and word["x1"] < 145 for word in row):
            continue
        columns = {
            "nif": (37, 145), "income_code": (145, 174), "holder": (174, 207),
            "income": (207, 287), "withholding": (287, 368), "contributions": (368, 449),
            "surtax_withholding": (449, 520), "union_dues": (520, 565),
        }
        values = {
            name: " ".join(word["text"] for word in row if left <= word["x0"] < right)
            for name, (left, right) in columns.items()
        }
        populated = tuple(name for name, value in values.items() if value)
        result.append(
            AnnexARow(page_number, len(result) + 1, code["text"], values["holder"],
                      bool(re.fullmatch(r"\d{9}", values["nif"])), populated, "EXACT")
        )
    return result


def _coded_fields(pages, routed: dict[int, str], annex: str, quadro_codes: dict[str, set[str]]) -> list[StructuralField]:
    """Accept a value only when an exact code cell owns a following value cell."""
    wanted = set().union(*quadro_codes.values())
    candidates: dict[str, list[tuple[int, str]]] = {code: [] for code in wanted}
    code_seen: dict[str, int] = {}
    for page_number, page in enumerate(pages, 1):
        if routed.get(page_number) != annex:
            continue
        for table in page.find_tables():
            for row in table.extract():
                cells = [_cell_text(cell) for cell in row]
                positions = [(index, cell) for index, cell in enumerate(cells) if cell in wanted]
                for pos_index, (index, code) in enumerate(positions):
                    code_seen.setdefault(code, page_number)
                    stop = positions[pos_index + 1][0] if pos_index + 1 < len(positions) else len(cells)
                    candidates[code].extend((page_number, value) for value in _money_in_cells(cells[index + 1 : stop]))
    fields: list[StructuralField] = []
    for quadro, codes in quadro_codes.items():
        for code in sorted(codes, key=int):
            values = candidates[code]
            if len(values) == 1:
                classification, page_number, value = "EXACT", values[0][0], values[0][1]
            elif len(values) > 1:
                classification, page_number, value = "AMBIGUOUS", values[0][0], None
            else:
                classification, page_number, value = "REJECTED", code_seen.get(code, 0), None
            fields.append(StructuralField(annex, quadro, code, "value", classification, page_number, value))
    return fields


def _checkbox_selected(page, code: str, *, top_min: float, top_max: float) -> bool | None:
    """Require the X glyph to occupy the checkbox cell on the code's row."""
    words = page.extract_words(use_text_flow=False)
    codes = [w for w in words if w["text"] == code and top_min <= w["top"] <= top_max]
    marks = [w for w in words if w["text"].upper() == "X" and top_min <= w["top"] <= top_max]
    if len(codes) != 1:
        return None
    code_word = codes[0]
    matching = [
        mark for mark in marks
        if abs((mark["top"] + mark["bottom"]) - (code_word["top"] + code_word["bottom"])) < 8
        and 0 <= mark["x0"] - code_word["x1"] < 24
    ]
    return len(matching) == 1


def _ss_metadata(page) -> tuple[str | None, bool, bool, bool, bool | None]:
    text = page.extract_text() or ""
    regime = None
    if _checkbox_selected(page, "02", top_min=80, top_max=115):
        regime = "CONTABILIDADE_ORGANIZADA"
    elif _checkbox_selected(page, "01", top_min=55, top_max=85):
        regime = "REGIME_SIMPLIFICADO"
    elif _checkbox_selected(page, "03", top_min=115, top_max=145):
        regime = "TRANSPARENCIA_FISCAL"
    nif_present = bool(re.search(r"\b999999990\b", text))
    niss_present = bool(re.search(r"(?<!\d)\d{11}(?!\d)", text))
    year_present = any(
        "04" in [_cell_text(cell) for cell in row]
        and any(re.fullmatch(r"(?:19|20)\d{2}", _cell_text(cell)) for cell in row)
        for table in page.find_tables()
        for row in table.extract()
    )
    no = _checkbox_selected(page, "2", top_min=600, top_max=630)
    yes = _checkbox_selected(page, "1", top_min=600, top_max=630)
    more_than_half = True if yes else False if no else None
    return regime, nif_present, niss_present, year_present, more_than_half


def _category_b_regime(pages, routed: dict[int, str]) -> str | None:
    page_number = next((number for number, annex in routed.items() if annex == "C"), None)
    if not page_number:
        return None
    page = pages[page_number - 1]
    if _checkbox_selected(page, "01", top_min=50, top_max=75):
        return "CONTABILIDADE_ORGANIZADA"
    if _checkbox_selected(page, "02", top_min=75, top_max=100):
        return "CONTABILIDADE_ORGANIZADA_AGRICOLA"
    return None


def _activity_code_present(pages, routed: dict[int, str]) -> bool:
    """Require Q3 field 07 and its value to share the same table row."""
    for page_number, page in enumerate(pages, 1):
        if routed.get(page_number) != "C":
            continue
        for table in page.find_tables():
            for row in table.extract():
                cells = [_cell_text(cell) for cell in row]
                if "07" not in cells:
                    continue
                index = cells.index("07")
                if any(re.fullmatch(r"\d{4}", cell) for cell in cells[index + 1 :]):
                    return True
    return False


def _pdf_form_flags(reader: PdfReader) -> tuple[bool, bool]:
    root = resolve(reader.trailer["/Root"])
    form = resolve(root.get("/AcroForm")) if root.get("/AcroForm") else None
    return bool(form), bool(form and form.get("/XFA"))


def extract_pdf(pdf_bytes: bytes) -> PdfExtraction:
    reader = PdfReader(io.BytesIO(pdf_bytes), strict=False)
    acroform, xfa = _pdf_form_flags(reader)
    with pdfplumber.open(io.BytesIO(pdf_bytes)) as pdf:
        routed = _annex_ranges(pdf.pages)
        page_structures = [
            PageStructure(number, routed.get(number, "ROSTO"), len(re.sub(r"\s+", "", page.extract_text() or "")) >= 40,
                          len(page.extract_text() or ""), len(page.find_tables()))
            for number, page in enumerate(pdf.pages, 1)
        ]
        annexes = _annex_inventory(pdf.pages[1]) if len(pdf.pages) >= 2 else []
        a_page = next((number for number, annex in routed.items() if annex == "A"), None)
        a_rows = _annex_a_rows(pdf.pages[a_page - 1], a_page) if a_page else []
        fields = _coded_fields(pdf.pages, routed, "C", ANNEX_C_FIELDS)
        fields.extend(_coded_fields(pdf.pages, routed, "H", {"coded": ANNEX_H_FIELDS}))
        fields.extend(_coded_fields(pdf.pages, routed, "SS", {"4/5": ANNEX_SS_FIELDS}))
        ss_number = next((number for number, annex in routed.items() if annex == "SS"), None)
        ss_regime, nif, niss, ss_year, half = (
            _ss_metadata(pdf.pages[ss_number - 1]) if ss_number else (None, False, False, False, None)
        )
        regime = _category_b_regime(pdf.pages, routed) or ss_regime
        c_texts = [page.extract_text() or "" for number, page in enumerate(pdf.pages, 1) if routed.get(number) == "C"]
        return PdfExtraction(
            page_structures, annexes, a_rows, fields,
            "rendimentos da categoria b" in normalize(" ".join(c_texts)), regime,
            _activity_code_present(pdf.pages, routed), nif, niss, ss_year, half, acroform, xfa,
        )
