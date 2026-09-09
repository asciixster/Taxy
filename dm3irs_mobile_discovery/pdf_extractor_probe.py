"""Run the research parser and print only field-presence metadata."""

from __future__ import annotations

import json
import sys
from pathlib import Path

from pdf_extractor import extract_pdf


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: pdf_extractor_probe.py PDF|-")
    pdf_bytes = sys.stdin.buffer.read() if sys.argv[1] == "-" else Path(sys.argv[1]).read_bytes()
    print(json.dumps(extract_pdf(pdf_bytes).sanitized_summary(), indent=2))


if __name__ == "__main__":
    main()
