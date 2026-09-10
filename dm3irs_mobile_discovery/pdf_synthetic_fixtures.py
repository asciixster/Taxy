"""In-memory synthetic DM3IRS PDFs for structural parser research.

No fixture contains real taxpayer data and no fixture is written to disk.
"""

from __future__ import annotations

import io
from dataclasses import dataclass, field

from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas


@dataclass(frozen=True)
class FixtureSpec:
    name: str
    annex_order: tuple[str, ...] = ("A", "C", "H", "SS")
    a_rows: int = 1
    c_fields: dict[str, str | None] = field(default_factory=dict)
    ss_fields: dict[str, str | None] = field(default_factory=dict)
    c_regime: str | None = "organized"
    ss_regime: str | None = "organized"
    activity_code: str | None = "4015"
    duplicate_c_page: bool = False
    c_table_x: float = 40
    c_table_widths: tuple[float, ...] = (250, 55, 110)


def _grid(document, rows, *, x=40, y=690, widths=(190, 50, 100), height=22):
    for row_index, row in enumerate(rows):
        top = y - row_index * height
        cursor = x
        for column_index, width in enumerate(widths):
            document.rect(cursor, top - height, width, height)
            if column_index < len(row) and row[column_index] is not None:
                document.drawString(cursor + 4, top - 15, str(row[column_index]))
            cursor += width


def _rosto(document, annexes: tuple[str, ...]) -> None:
    document.drawString(40, 800, "ROSTO")
    document.showPage()
    rows = [("ANEXOS", "Quantidade")]
    for annex in ("A", "B", "C", "H", "SS"):
        rows.append((f"Anexo {annex}", "1" if annex in annexes else None))
    _grid(document, rows, widths=(130, 60), y=780)
    document.showPage()


def _annex_a(document, row_count: int) -> None:
    document.drawString(40, 815, "MODELO 3 Anexo A")
    document.drawString(40, 790, "QUADRO 4A")
    for index in range(row_count):
        y = 700 - index * 20
        document.drawString(65, y, "999999990")
        document.drawString(150, y, "401")
        document.drawString(181, y, "A" if index == 0 else "B")
        document.drawString(233, y, "1.234,56")
        document.drawString(315, y, "123,45")
        document.drawString(394, y, "123,45")
        document.drawString(549, y, "12,34")
    document.showPage()


def _checkbox(document, code: str, *, code_x: float, y: float, marked: bool) -> None:
    document.drawString(code_x, y, code)
    document.rect(code_x + 14, y - 2, 12, 12)
    if marked:
        # Keep the glyph a distinct text object while retaining it inside the
        # checkbox cell and close enough to its printed code for ownership.
        document.drawString(code_x + (20 if len(code) > 1 else 16), y, "X")


def _annex_c(document, spec: FixtureSpec) -> None:
    document.drawString(40, 820, "MODELO 3 Anexo C")
    document.drawString(40, 795, "RENDIMENTOS DA CATEGORIA B")
    _checkbox(document, "01", code_x=350, y=775, marked=spec.c_regime == "organized")
    _checkbox(document, "02", code_x=350, y=746, marked=spec.c_regime == "agricultural")
    if spec.activity_code is not None:
        _grid(document, [("07", spec.activity_code)], x=55, y=725, widths=(35, 75))
    rows = [(f"Campo {code}", code, value) for code, value in spec.c_fields.items()]
    if rows:
        _grid(document, rows, x=spec.c_table_x, y=650, widths=spec.c_table_widths, height=24)
    document.showPage()


def _annex_h(document) -> None:
    document.drawString(40, 815, "MODELO 3 Anexo H")
    _grid(document, [("Campo H", "601", "123,45")])
    document.showPage()


def _annex_ss(document, spec: FixtureSpec) -> None:
    document.drawString(40, 815, "MODELO 3 ANEXO SS")
    _checkbox(document, "01", code_x=381, y=768, marked=spec.ss_regime == "simplified")
    _checkbox(document, "02", code_x=381, y=740, marked=spec.ss_regime == "organized")
    _checkbox(document, "03", code_x=381, y=711, marked=spec.ss_regime == "transparency")
    _grid(document, [("04", "2024")], x=468, y=690, widths=(35, 75))
    document.drawString(60, 650, "06 999999990")
    rows = [(f"Campo {code}", code, value) for code, value in spec.ss_fields.items()]
    if rows:
        _grid(document, rows, x=40, y=610, widths=(250, 55, 110), height=24)
    _checkbox(document, "1", code_x=280, y=220, marked=False)
    _checkbox(document, "2", code_x=351, y=220, marked=True)
    document.showPage()


def build_fixture(spec: FixtureSpec) -> bytes:
    output = io.BytesIO()
    document = canvas.Canvas(output, pagesize=A4)
    _rosto(document, spec.annex_order)
    for annex in spec.annex_order:
        if annex == "A":
            _annex_a(document, spec.a_rows)
        elif annex == "B":
            document.drawString(40, 815, "MODELO 3 Anexo B")
            document.showPage()
        elif annex == "C":
            _annex_c(document, spec)
            if spec.duplicate_c_page:
                _annex_c(document, spec)
        elif annex == "H":
            _annex_h(document)
        elif annex == "SS":
            _annex_ss(document, spec)
    document.save()
    return output.getvalue()


SYNTHETIC_FIXTURES = {
    "field_filled": FixtureSpec(
        "field_filled",
        c_fields={"469": None, "470": "12.345,67", "601": "1.234,56", "602": "123,45", "603": "45,67", "604": "8,90"},
        ss_fields={**{str(code): f"{code},00" for code in range(401, 410)}, "501": "501,00", "502": "502,00"},
    ),
    "field_empty": FixtureSpec("field_empty", c_fields={"603": None}),
    "multiple_lines": FixtureSpec("multiple_lines", a_rows=3, c_fields={"602": "123,45"}),
    "checkboxes": FixtureSpec("checkboxes", c_regime=None, ss_regime="simplified", c_fields={"601": "123,45"}),
    "alternative_field": FixtureSpec("alternative_field", c_fields={"469": "321,00", "470": None}),
    "annex_absent": FixtureSpec("annex_absent", annex_order=("A", "H", "SS"), c_fields={}),
    "duplicate_page": FixtureSpec("duplicate_page", c_fields={"603": "50,00"}, duplicate_c_page=True),
    "different_order": FixtureSpec(
        "different_order", annex_order=("SS", "H", "C", "A"), c_fields={"603": "50,00"},
        c_table_x=120, c_table_widths=(180, 45, 90),
    ),
    "zero_value": FixtureSpec("zero_value", c_fields={"603": "0,00"}, ss_fields={"409": "0,00", "502": "0,00"}),
    "pt_money": FixtureSpec("pt_money", c_fields={"601": "1.234,56", "602": "1 234,56", "604": "1234,56"}),
}
