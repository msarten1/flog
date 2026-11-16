"""Historial de novedades de los últimos días (`data/novedades.json`).

Lo usa la app para mostrar el resumen semanal en la pestaña Avisos y el
scraper para construir el resumen semanal por push y no repetir los avisos
de cierre de inscripción.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from datetime import date, timedelta
from pathlib import Path

from .store import Cambios

DIAS_HISTORIAL = 14


@dataclass
class Novedades:
    dias: list[dict] = field(default_factory=list)  # [{fecha, nuevos, cambios, eliminados}] más reciente primero
    avisos_cierre: list[str] = field(default_factory=list)  # ids ya avisados por cierre inminente

    @classmethod
    def leer(cls, path: Path) -> "Novedades":
        if not path.exists():
            return cls()
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            return cls()
        return cls(dias=list(data.get("dias", [])), avisos_cierre=list(data.get("avisos_cierre", [])))

    def to_json(self) -> dict:
        return {"dias": self.dias, "avisos_cierre": self.avisos_cierre}

    def registrar(self, cambios: Cambios, today: date | None = None) -> None:
        """Añade (o sustituye) el día de `cambios` y recorta el historial."""
        today = today or date.fromisoformat(cambios.fecha)
        entrada = {
            "fecha": cambios.fecha,
            "nuevos": cambios.nuevos,
            "cambios": cambios.cambios,
            "eliminados": cambios.eliminados,
        }
        self.dias = [d for d in self.dias if d.get("fecha") != cambios.fecha]
        self.dias.append(entrada)
        limite = (today - timedelta(days=DIAS_HISTORIAL)).isoformat()
        self.dias = sorted(
            (d for d in self.dias if d.get("fecha", "") >= limite),
            key=lambda d: d["fecha"],
            reverse=True,
        )
        # Los ids avisados de torneos que ya no están en el historial pueden olvidarse.
        vivos = {t["id"] for d in self.dias for k in ("nuevos", "cambios") for t in d.get(k, [])}
        self.avisos_cierre = [i for i in self.avisos_cierre if i in vivos or len(self.avisos_cierre) < 500]

    def ultimos(self, dias: int, today: date) -> tuple[list[dict], list[dict]]:
        """→ (nuevos, cambios) de los últimos `dias` días, sin duplicar ids."""
        desde = (today - timedelta(days=dias)).isoformat()
        nuevos: dict[str, dict] = {}
        cambios: dict[str, dict] = {}
        for d in sorted(self.dias, key=lambda d: d["fecha"]):
            if d["fecha"] < desde:
                continue
            for t in d.get("nuevos", []):
                nuevos[t["id"]] = t
            for t in d.get("cambios", []):
                if t["id"] not in nuevos:
                    cambios[t["id"]] = t
        return sorted(nuevos.values(), key=lambda t: t["fecha"]), sorted(cambios.values(), key=lambda t: t["fecha"])
