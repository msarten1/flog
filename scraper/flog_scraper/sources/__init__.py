"""Fuentes de datos. Cada módulo expone `fetch(fetcher) -> list[Torneo]`
y `parse_*` puros para poder testearlos con fixtures."""

from . import golfcv, mediterraneo, tornegolf

ALL_SOURCES = (tornegolf, golfcv, mediterraneo)

__all__ = ["ALL_SOURCES", "tornegolf", "golfcv", "mediterraneo"]
