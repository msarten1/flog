"""Lectura y escritura de data/torneos.json y data/changes.json, y
reconciliación con la versión anterior (ids, "anadido", "cambio")."""

from __future__ import annotations

import json
import logging
from dataclasses import dataclass, field
from datetime import date, timedelta
from pathlib import Path

from rapidfuzz import fuzz

from . import config
from .dedupe import UMBRAL_NOMBRE
from .model import Torneo, fecha_corta

log = logging.getLogger(__name__)

CABECERA_NOTA = (
    "Torneos amateur de la Comunitat Valenciana (Alicante, Valencia, Castellón). "
    "Se excluyen competiciones profesionales, juveniles y las ligas internas de sociedades/socios."
)
FUENTES = [
    {"nombre": "Federación de Golf de la Comunitat Valenciana (FGCV)", "url": "https://golfcv.com/"},
    {"nombre": "Tornegolf – Alicante", "url": "https://www.tornegolf.com/torneos/provincia/alicante"},
    {"nombre": "Tornegolf – Valencia", "url": "https://www.tornegolf.com/torneos/provincia/valencia"},
    {"nombre": "Tornegolf – Castellón", "url": "https://www.tornegolf.com/torneos/provincia/castellon"},
    {"nombre": "Mediterráneo Golf – Calendario", "url": "https://mediterraneo.golf/en/calendar/"},
]


@dataclass
class Catalogo:
    actualizado: str
    primera: str
    torneos: list[Torneo]
    nota: str = CABECERA_NOTA
    fuentes: list[dict] = field(default_factory=lambda: list(FUENTES))

    def to_json(self) -> dict:
        return {
            "actualizado": self.actualizado,
            "primera": self.primera,
            "nota": self.nota,
            "fuentes": self.fuentes,
            "torneos": [t.to_json() for t in sorted(self.torneos, key=lambda t: (t.fecha, t.provincia, t.nombre))],
        }


@dataclass
class Cambios:
    fecha: str
    nuevos: list[dict] = field(default_factory=list)
    cambios: list[dict] = field(default_factory=list)
    eliminados: list[dict] = field(default_factory=list)
    proximos_14_dias: list[dict] = field(default_factory=list)
    inscripciones_cierran: list[dict] = field(default_factory=list)
    revisar: list[dict] = field(default_factory=list)

    def to_json(self) -> dict:
        return self.__dict__

    def resumen(self) -> str:
        partes = [f"{len(self.nuevos)} nuevos", f"{len(self.cambios)} cambios"]
        if self.eliminados:
            partes.append(f"{len(self.eliminados)} eliminados")
        return " · ".join(partes)


def leer_catalogo(path: Path) -> Catalogo | None:
    if not path.exists():
        return None
    data = json.loads(path.read_text(encoding="utf-8"))
    return Catalogo(
        actualizado=data.get("actualizado", date.today().isoformat()),
        primera=data.get("primera", data.get("actualizado", date.today().isoformat())),
        torneos=[Torneo.from_json(t) for t in data.get("torneos", [])],
        nota=data.get("nota", CABECERA_NOTA),
        fuentes=data.get("fuentes", list(FUENTES)),
    )


def escribir_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")


def _resumen_torneo(t: Torneo) -> dict:
    d = {"id": t.id, "fecha": t.fecha, "nombre": t.nombre, "club": t.club, "provincia": t.provincia, "tipo": t.tipo}
    if t.cambio:
        d["cambio"] = t.cambio
    return d


def _emparejar(nuevo: Torneo, anteriores: list[Torneo]) -> Torneo | None:
    """Busca el registro anterior que corresponde a `nuevo`."""
    for a in anteriores:
        if a.id == nuevo.id:
            return a
    if nuevo.enlace:
        for a in anteriores:
            if a.enlace and a.enlace == nuevo.enlace:
                return a
    # Mismo club y nombre parecido en una ventana de ±21 días (cubre cambios de fecha).
    f_nuevo = date.fromisoformat(nuevo.fecha)
    mejor, mejor_score = None, 0
    for a in anteriores:
        if a.club_norm != nuevo.club_norm:
            continue
        try:
            delta = abs((date.fromisoformat(a.fecha) - f_nuevo).days)
        except ValueError:
            continue
        if delta > 21:
            continue
        score = fuzz.token_set_ratio(a.nombre_norm, nuevo.nombre_norm)
        if score >= UMBRAL_NOMBRE and score > mejor_score and (delta == 0 or score >= 90):
            mejor, mejor_score = a, score
    return mejor


def reconciliar(
    nuevos: list[Torneo],
    anterior: Catalogo | None,
    today: date | None = None,
    descartados: set[str] | None = None,
) -> tuple[Catalogo, Cambios]:
    """Combina la captura de hoy con el catálogo anterior.

    - Conserva `id` y `anadido` de los torneos ya conocidos.
    - Marca `cambio` cuando cambia fecha o sede.
    - Mantiene unos días los que desaparecen de su fuente ("Posiblemente cancelado").
    - Los ids en `descartados` (excluidos hoy por reglas o clasificador) se retiran sin aviso.
    - Elimina los que terminaron hace más de DIAS_RETENCION_PASADOS días.
    """
    today = today or date.today()
    hoy = today.isoformat()
    descartados = descartados or set()
    anteriores = list(anterior.torneos) if anterior else []
    usados: set[int] = set()
    resultado: list[Torneo] = []
    cambios = Cambios(fecha=hoy)

    for t in nuevos:
        prev = _emparejar(t, [a for i, a in enumerate(anteriores) if i not in usados])
        if prev is None:
            if t.fecha_final < hoy:
                continue  # descubierto después de jugarse: no se anuncia ni se publica
            t.anadido = hoy
            resultado.append(t)
            cambios.nuevos.append(_resumen_torneo(t))
            continue
        usados.add(anteriores.index(prev))
        t.id = prev.id
        t.anadido = prev.anadido or anterior.primera if anterior else hoy
        t.cambio = None
        if prev.fecha != t.fecha:
            t.cambio = f"Cambio de fecha (antes {fecha_corta(prev.fecha)})"
        elif prev.club_norm != t.club_norm:
            t.cambio = f"Cambio de sede (antes {prev.club})"
        elif prev.estado_inscripcion != "abierta" and t.estado_inscripcion == "abierta" and prev.estado_inscripcion is not None:
            t.cambio = "Inscripción abierta"
        if t.cambio:
            cambios.cambios.append(_resumen_torneo(t))
        resultado.append(t)

    # Anteriores no encontrados hoy en ninguna fuente.
    for i, a in enumerate(anteriores):
        if i in usados:
            continue
        if a.fecha_final < hoy:
            continue  # ya se jugó: lo gestiona la purga de abajo
        if a.id in descartados:
            continue  # hoy se ha decidido que no es un torneo abierto: fuera sin aviso
        if a.fuente == "legacy":
            # Datos de la etapa anterior sin fuente automatizable: se mantienen hasta su fecha.
            resultado.append(a)
            continue
        desde = a.sin_fuente_desde or hoy
        if (today - date.fromisoformat(desde)).days >= config.DIAS_SIN_FUENTE:
            cambios.eliminados.append(_resumen_torneo(a))
            continue
        a.sin_fuente_desde = desde
        if a.cambio != "Posiblemente cancelado":
            a.cambio = "Posiblemente cancelado"
            cambios.cambios.append(_resumen_torneo(a))
        resultado.append(a)

    # Purga de torneos pasados.
    limite = (today - timedelta(days=config.DIAS_RETENCION_PASADOS)).isoformat()
    resultado = [t for t in resultado if t.fecha_final >= limite]

    # Listas informativas.
    en_14 = (today + timedelta(days=14)).isoformat()
    cambios.proximos_14_dias = [
        _resumen_torneo(t) for t in sorted(resultado, key=lambda x: x.fecha) if hoy <= t.fecha <= en_14
    ]
    en_10 = (today + timedelta(days=10)).isoformat()
    cambios.inscripciones_cierran = [
        {**_resumen_torneo(t), "cierre": t.cierre_inscripcion}
        for t in sorted(resultado, key=lambda x: x.cierre_inscripcion or "")
        if t.cierre_inscripcion and hoy <= t.cierre_inscripcion <= en_10
    ]
    cambios.revisar = [_resumen_torneo(t) for t in resultado if t.revisar]

    catalogo = Catalogo(
        actualizado=hoy,
        primera=anterior.primera if anterior else hoy,
        torneos=resultado,
    )
    return catalogo, cambios
