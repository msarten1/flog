"""Fusión de torneos repetidos entre fuentes."""

from __future__ import annotations

import logging
from collections import defaultdict

from rapidfuzz import fuzz

from .model import Torneo

log = logging.getLogger(__name__)

UMBRAL_NOMBRE = 80
# Prioridad de fuente cuando dos registros son el mismo torneo.
PRIORIDAD = {"golfcv": 0, "mediterraneo": 1, "tornegolf": 2, "legacy": 3}

_RELLENABLES = (
    "fecha_fin",
    "modalidad",
    "inscripcion",
    "precio",
    "estado_inscripcion",
    "enlace",
    "enlace_inscripcion",
    "descripcion",
    "cierre_inscripcion",
)


_TOKENS_GENERICOS = {
    "golf", "torneo", "club", "campo", "final", "edicion", "prueba",
    "individual", "parejas", "dobles", "stableford", "masculino", "femenino", "masculina", "femenina",
}


def _tokens_significativos(nombre_norm: str) -> set[str]:
    return {w for w in nombre_norm.split() if len(w) >= 4 and w not in _TOKENS_GENERICOS and not w.isdigit()}


def mismo_torneo(a: Torneo, b: Torneo) -> bool:
    """Mismo día y mismo club, y nombres equivalentes.

    Equivalentes = muy parecidos (token_set_ratio) o que comparten al menos
    dos palabras distintivas (p. ej. "Copa Levante Summum" y "Villaitana Copa
    Levante 2026" son el mismo torneo en el mismo campo y fecha).
    """
    if a.id == b.id:
        return True
    if a.fecha != b.fecha or a.club_norm != b.club_norm:
        return False
    if fuzz.token_set_ratio(a.nombre_norm, b.nombre_norm) >= UMBRAL_NOMBRE:
        return True
    return len(_tokens_significativos(a.nombre_norm) & _tokens_significativos(b.nombre_norm)) >= 2


def fusionar(a: Torneo, b: Torneo) -> Torneo:
    """Devuelve el registro ganador completado con los datos del otro."""
    ganador, otro = sorted((a, b), key=lambda t: (PRIORIDAD.get(t.fuente, 9), -len(t.nombre)))
    for campo in _RELLENABLES:
        if getattr(ganador, campo) is None and getattr(otro, campo) is not None:
            setattr(ganador, campo, getattr(otro, campo))
    # Tornegolf tiene fichas propias más completas que la de golfcv: se guarda como inscripción.
    if otro.fuente == "tornegolf" and otro.enlace and ganador.enlace != otro.enlace and not ganador.enlace_inscripcion:
        ganador.enlace_inscripcion = otro.enlace
    if ganador.tipo == "Club" and otro.tipo != "Club":
        ganador.tipo = otro.tipo
    return ganador


def deduplicar(torneos: list[Torneo]) -> list[Torneo]:
    por_clave: dict[tuple[str, str], list[Torneo]] = defaultdict(list)
    por_id: dict[str, Torneo] = {}
    resultado: list[Torneo] = []
    fusiones = 0

    for t in sorted(torneos, key=lambda x: (PRIORIDAD.get(x.fuente, 9), x.fecha)):
        if t.id in por_id:
            base = por_id[t.id]
            fusionado = fusionar(base, t)
            _reemplazar(resultado, base, fusionado)
            por_id[t.id] = fusionado
            fusiones += 1
            continue
        clave = (t.fecha, t.club_norm)
        candidato = next((c for c in por_clave[clave] if mismo_torneo(c, t)), None)
        if candidato is not None:
            fusionado = fusionar(candidato, t)
            _reemplazar(resultado, candidato, fusionado)
            por_clave[clave] = [fusionado if c is candidato else c for c in por_clave[clave]]
            por_id[fusionado.id] = fusionado
            fusiones += 1
            continue
        por_clave[clave].append(t)
        por_id[t.id] = t
        resultado.append(t)

    if fusiones:
        log.info("dedupe: %d registros fusionados", fusiones)
    return resultado


def _reemplazar(lista: list[Torneo], viejo: Torneo, nuevo: Torneo) -> None:
    for i, x in enumerate(lista):
        if x is viejo:
            lista[i] = nuevo
            return
    lista.append(nuevo)
