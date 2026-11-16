"""Reglas de inclusión / exclusión y de tipo de torneo.

Criterio (heredado de la tarea semanal original):
  INCLUIR campeonatos y circuitos federativos amateur, torneos abiertos de
  club, circuitos amateur y pruebas nacionales RFEG que se jueguen en la CV.
  EXCLUIR profesionales (salvo pro-am), juveniles/infantiles/benjamines y
  competiciones semanales de sociedades o socios (ligas internas, Monday
  Competition, Tuesday Duel, Golf Holanda, Teigur, SAS...).
"""

from __future__ import annotations

import re
from enum import Enum

from .model import Torneo, norm_text


class Decision(str, Enum):
    INCLUIR = "incluir"
    EXCLUIR = "excluir"
    DUDOSO = "dudoso"


# Patrones sobre el nombre normalizado (minúsculas, sin acentos).
# Se aplican a todas las fuentes: categorías que nunca entran.
_EXCLUIR_CATEGORIA = [
    # Categorías juveniles
    r"\b(juvenil(es)?|infantil(es)?|benjamin(es)?|cadete(s)?|alevin(es)?|junior)\b",
    r"\bsub\s?-?\s?1[0-8]\b",
    r"\bsub\s?-?\s?2[0-5]\b",
    # Profesionales (el pro-am se rescata más abajo)
    r"\bprofesional(es)?\b",
    r"\bpro\b(?!\s*-?\s*am)",
    # Entrenamientos, clases, jornadas no competitivas
    r"\b(clinic|clase|entrenamiento|practica)\b",
]
# Solo para fuentes no federativas: ligas internas y sociedades.
_EXCLUIR_SOCIEDAD = [
    r"\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b",
    r"\bgolf holanda\b",
    r"\bteigur\b",
    r"\bsas\b",
    r"\bsociety\b",
    r"\bwcgs\b",
    r"\brencontre\b",
    r"\bdeutscher\b",
    r"\beclectic\b",
    r"\bround\s*\d+",
    r"\bmedal\b",
    r"\bleague\b",
    r"\bliga\b",
    r"\bligas?\s+(internas?|sociales?)\b",
    r"\bsocios\b",
    r"\binterclub(e)?s\b.*\bsocios\b",
    r"\bduel\b",
]
_RESCATAR = [r"\bpro\s*-?\s*am\b"]

_INCLUIR = [
    r"\b(campeonato|cto|championship)\b",
    r"\b(open|abierto)\b",
    r"\b(copa|cup|trofeo|trophy|torneo|tournament)\b",
    r"\bcircuito\b",
    r"\bmemorial\b",
    r"\bgran premio\b",
    r"\bchampion",
    r"\b(navidad|christmas|xmas|fin de a[ñn]o|reyes|otoño|otono|primavera|verano)\b",
    r"\bmaster(s)?\b",
    r"\bscramble\b",
    r"\bpro\s*-?\s*am\b",
]

_TIPO_NACIONAL = re.compile(
    r"(campeonato|cto|internacional|copa)\s+(de\s+)?espa[ñn]a|\brfeg\b|\bpuntuable nacional\b"
)
_TIPO_CIRCUITO = re.compile(r"\bcircuito\b|\btour\b|\bgran premio\b|\bliguilla\b")
_TIPO_FEDERACION = re.compile(r"\b(fgcv|federaci[oó]n|cv|comunitat|comunidad valenciana)\b|\bliguilla\b")

_CATEGORIA_RE = [re.compile(p) for p in _EXCLUIR_CATEGORIA]
_SOCIEDAD_RE = [re.compile(p) for p in _EXCLUIR_SOCIEDAD]
_RESCATAR_RE = [re.compile(p) for p in _RESCATAR]
_INCLUIR_RE = [re.compile(p) for p in _INCLUIR]


def es_federativo(t: Torneo) -> bool:
    """Datos que vienen de la Federación (directamente o republicados)."""
    return t.fuente == "golfcv" or (t.origen or "") == "golfcv"


def decidir(t: Torneo) -> tuple[Decision, str]:
    """Devuelve (decisión, motivo)."""
    nombre = norm_text(t.nombre)
    desc = norm_text(t.descripcion)
    rescatado = any(r.search(nombre) for r in _RESCATAR_RE)

    for rx in _CATEGORIA_RE:
        if rx.search(nombre) and not rescatado:
            return Decision.EXCLUIR, f"categoría excluida '{rx.pattern}'"

    # Lo federativo ya viene filtrado por comité y nivel en la fuente.
    if es_federativo(t):
        return Decision.INCLUIR, "competición federativa"

    for rx in _SOCIEDAD_RE:
        if rx.search(nombre) and not rescatado:
            return Decision.EXCLUIR, f"sociedad/liga interna '{rx.pattern}'"
    # Fuente RFEG republicada por Tornegolf (campeonatos de España)
    if (t.origen or "") == "rfeg":
        return Decision.INCLUIR, "prueba RFEG en la CV"
    for rx in _INCLUIR_RE:
        if rx.search(nombre):
            return Decision.INCLUIR, f"coincide '{rx.pattern}'"
    if "society" in desc or "socios" in desc:
        return Decision.EXCLUIR, "descripción de sociedad/socios"
    return Decision.DUDOSO, "sin regla aplicable"


def clasificar_tipo(t: Torneo) -> str:
    """Ajusta `tipo` según nombre y origen."""
    nombre = norm_text(t.nombre)
    if _TIPO_NACIONAL.search(nombre) or (t.origen or "") == "rfeg":
        return "Nacional en la CV"
    if es_federativo(t):
        return "Federación"
    if _TIPO_CIRCUITO.search(nombre):
        return "Circuito"
    if _TIPO_FEDERACION.search(nombre):
        return "Federación"
    return "Club"


def aplicar_reglas(torneos: list[Torneo]) -> tuple[list[Torneo], list[Torneo], list[tuple[Torneo, str]]]:
    """→ (incluidos, dudosos, excluidos_con_motivo)."""
    incluidos: list[Torneo] = []
    dudosos: list[Torneo] = []
    excluidos: list[tuple[Torneo, str]] = []
    for t in torneos:
        decision, motivo = decidir(t)
        if decision is Decision.EXCLUIR:
            excluidos.append((t, motivo))
            continue
        t.tipo = clasificar_tipo(t)
        if decision is Decision.INCLUIR:
            incluidos.append(t)
        else:
            dudosos.append(t)
    return incluidos, dudosos, excluidos
