from __future__ import annotations

from datetime import date
from pathlib import Path

import pytest

FIXTURES = Path(__file__).parent / "fixtures"
HOY = date(2026, 11, 16)


@pytest.fixture
def fixtures() -> Path:
    return FIXTURES


@pytest.fixture
def hoy() -> date:
    return HOY


def leer(nombre: str) -> str:
    return (FIXTURES / nombre).read_text(encoding="utf-8")
