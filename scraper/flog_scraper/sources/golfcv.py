"""Federación de Golf de la Comunitat Valenciana (https://golfcv.com).

El buscador de competiciones consulta un endpoint JSON de WordPress:
    POST https://golfcv.com/wp-json/bt_ws/v1/torneos_lt/?criterio=year&lang=0
    body: year=2026
Devuelve todas las competiciones federativas del año con fechas, campo,
provincia, precio y plazo de inscripción.
"""

from __future__ import annotations

import json
import logging
import re
from datetime import date

from ..model import Torneo, club_canonico, fecha_corta, provincia_canonica

log = logging.getLogger(__name__)

NAME = "golfcv"
ENDPOINT = "https://golfcv.com/wp-json/bt_ws/v1/torneos_lt/?criterio=year&lang=0"
FICHA = "https://golfcv.com/torneo_seek/ver-torneo/?torneoid={id}"

# Códigos del formulario de búsqueda (https://golfcv.com/torneo_seek/).
NIVEL = {
    "2": "Absoluto",
    "3": "Senior",
    "4": "Mayor",
    "130": "Mayor de 21",
    "131": "Menor de 26",
    "9": "Junior",
    "5": "Junior o inferior",
    "6": "Juvenil",
    "10": "Cadete",
    "11": "Infantil",
    "7": "Infantil o inferior",
}
NIVELES_JUVENILES = {"9", "5", "6", "10", "11", "7"}
FORMA_JUEGO = {"1": "Stroke Play", "2": "Match Play", "3": "Stroke Play y Match Play"}
MODALIDAD = {
    "2": "Individual",
    "3": "Foursome",
    "4": "Fourball",
    "5": "Greensome",
    "6": "Greensome Chapman",
    "7": "Copa Canadá",
    "1": "Varias modalidades",
    "8": "Scramble Modificado",
}
COMITES_EXCLUIDOS = ("juvenil", "profesional")

_NACIONAL_RE = re.compile(
    r"(campeonato|cto\.?|internacional|copa)\s+(de\s+)?espa[ñn]a|\brfeg\b", re.I
)


def _fecha_ok(s: str | None) -> str | None:
    if s and re.fullmatch(r"\d{4}-\d{2}-\d{2}", s) and not s.startswith("0000"):
        return s
    return None


def _modalidad(rec: dict) -> str | None:
    partes = [MODALIDAD.get(str(rec.get("modalidadjuego") or "")), FORMA_JUEGO.get(str(rec.get("formajuego") or ""))]
    partes = [p for p in partes if p]
    if not partes:
        return None
    return " · ".join(partes)


def _inscripcion(rec: dict) -> tuple[str | None, str | None, str | None]:
    """→ (texto, precio, cierre_iso)."""
    ini, fin = _fecha_ok(rec.get("finicio")), _fecha_ok(rec.get("ffin"))
    pvp = str(rec.get("pvp") or "0").strip()
    precio = f"{pvp} €" if pvp not in ("", "0", "0.0", "0.00") else None
    texto = None
    if ini and fin:
        texto = f"Inscripción del {fecha_corta(ini)} al {fecha_corta(fin)}"
    elif fin:
        texto = f"Inscripción hasta el {fecha_corta(fin)}"
    nivel = NIVEL.get(str(rec.get("nivelparticipantes") or ""))
    if nivel and nivel not in ("Absoluto",):
        texto = f"{texto} · {nivel}" if texto else nivel
    return texto, precio, fin


def record_to_torneo(rec: dict, today: date | None = None) -> Torneo | None:
    today = today or date.today()
    fecha = _fecha_ok(rec.get("fecha"))
    if not fecha:
        return None
    provincia = provincia_canonica(rec.get("provincia"))
    if provincia is None:
        return None  # "Resto": se juega fuera de la Comunitat
    nombre = re.sub(r"\s+", " ", (rec.get("torneo") or "")).strip()
    if not nombre:
        return None
    if str(rec.get("publicarsn", "1")) == "0":
        return None
    comite = (rec.get("comitename") or "").lower()
    nivel = str(rec.get("nivelparticipantes") or "")
    if any(x in comite for x in COMITES_EXCLUIDOS) or nivel in NIVELES_JUVENILES:
        return None

    campo = rec.get("campo") or ""
    if "fuera de la" in campo.lower() and rec.get("campotxt"):
        campo = rec["campotxt"]
    club = club_canonico(campo)

    fecha_fin = _fecha_ok(rec.get("fechafin"))
    if fecha_fin == fecha:
        fecha_fin = None

    texto, precio, cierre = _inscripcion(rec)
    estado = None
    if "abierta" in str(rec.get("abierta") or "").lower():
        estado = "abierta"
    elif cierre and cierre < today.isoformat():
        estado = "cerrada"

    tipo = "Nacional en la CV" if _NACIONAL_RE.search(nombre) else "Federación"

    descripcion = " | ".join(
        s
        for s in (
            f"comite={rec.get('comitename')}" if rec.get("comitename") else None,
            f"nivel={NIVEL.get(nivel)}" if NIVEL.get(nivel) else None,
            re.sub(r"<[^>]+>|&[a-z]+;", " ", str(rec.get("notas") or ""))[:200].strip() or None,
        )
        if s
    ) or None

    return Torneo(
        id=f"golfcv-{rec.get('torneoid')}",
        fecha=fecha,
        fecha_fin=fecha_fin,
        nombre=nombre,
        club=club,
        provincia=provincia,
        tipo=tipo,
        fuente=NAME,
        modalidad=_modalidad(rec),
        inscripcion=texto,
        precio=precio,
        estado_inscripcion=estado,
        enlace=FICHA.format(id=rec.get("torneoid")),
        descripcion=descripcion,
        origen=NAME,
        cierre_inscripcion=cierre,
    )


def parse_json(text: str, today: date | None = None) -> list[Torneo]:
    try:
        data = json.loads(text)
    except json.JSONDecodeError:
        log.error("golfcv: respuesta no es JSON")
        return []
    if not isinstance(data, list):
        return []
    out = []
    for rec in data:
        if isinstance(rec, dict):
            t = record_to_torneo(rec, today)
            if t is not None:
                out.append(t)
    return out


def fetch(fetcher) -> list[Torneo]:
    year = date.today().year
    out: list[Torneo] = []
    for y in (year, year + 1):
        try:
            text = fetcher.post(ENDPOINT, data={"year": str(y)})
        except Exception as exc:  # noqa: BLE001
            log.error("golfcv %s: no se pudo consultar (%s)", y, exc)
            continue
        parsed = parse_json(text)
        log.info("golfcv %s: %d competiciones válidas", y, len(parsed))
        out.extend(parsed)
    return out
