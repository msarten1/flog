"""Tornegolf (https://www.tornegolf.com): agregador de torneos amateur.

La página de cada provincia es una app Next.js que incrusta en el HTML
(`self.__next_f.push(...)`) el array completo de torneos con todos sus
campos (fecha, campo, modalidad, precio, inscripción abierta, enlace
externo...). Se extrae ese JSON y no hace falta pedir cada ficha.
"""

from __future__ import annotations

import json
import logging
import re

from ..model import Torneo, club_canonico, provincia_canonica, norm_text

log = logging.getLogger(__name__)

NAME = "tornegolf"
BASE = "https://www.tornegolf.com"
LIST_URLS = {
    "Alicante": f"{BASE}/torneos/provincia/alicante",
    "Valencia": f"{BASE}/torneos/provincia/valencia",
    "Castellón": f"{BASE}/torneos/provincia/castellon",
}

_PUSH_RE = re.compile(r'self\.__next_f\.push\(\[1,"(.*?)"\]\)</script>', re.S)
_RECORDS_RE = re.compile(r'\[\{"id":\d+,"name":')
_HREF_RE = re.compile(r'href="(/torneos/[^"]+--(\d+))"')
_GOLFCV_ID_RE = re.compile(r"torneoid=(\d+)")

_FORMAT_WORDS = {
    "individual": "Individual",
    "fourball": "Fourball",
    "foursome": "Foursome",
    "greensome": "Greensome",
    "scramble": "Scramble",
    "canadacup": "Copa Canadá",
    "chapman": "Chapman",
    "stableford": "Stableford",
    "strokeplay": "Stroke Play",
    "matchplay": "Match Play",
    "medal": "Medal",
    "texas": "Texas",
    "shotgun": "",
}


def _decode_stream(html: str) -> str:
    chunks = _PUSH_RE.findall(html)
    parts = []
    for c in chunks:
        try:
            parts.append(json.loads('"' + c + '"'))
        except json.JSONDecodeError:
            continue
    return "".join(parts)


def extract_records(html: str) -> list[dict]:
    """Devuelve el array de torneos incrustado en la página de provincia."""
    stream = _decode_stream(html)
    decoder = json.JSONDecoder()
    best: list[dict] = []
    for m in _RECORDS_RE.finditer(stream):
        try:
            arr, _ = decoder.raw_decode(stream, m.start())
        except json.JSONDecodeError:
            continue
        if isinstance(arr, list) and arr and isinstance(arr[0], dict) and "date" in arr[0]:
            if len(arr) > len(best):
                best = arr
    return best


def extract_links(html: str) -> dict[int, str]:
    """id numérico → URL de la ficha en Tornegolf."""
    return {int(i): BASE + path for path, i in _HREF_RE.findall(html)}


def modalidad_legible(fmt: str | None) -> str | None:
    if not fmt:
        return None
    words = []
    for w in re.split(r"[\s_]+", fmt.strip()):
        key = w.lower()
        words.append(_FORMAT_WORDS.get(key, w.capitalize()))
    return " ".join(w for w in words if w) or None


def _precio(rec: dict) -> str | None:
    fee = rec.get("entry_fee")
    ext, mem = rec.get("price_external"), rec.get("price_member")
    if fee:
        s = str(fee).strip()
        return s if "€" in s or not re.fullmatch(r"[\d.,]+", s) else f"{s} €"
    partes = []
    if mem:
        partes.append(f"Socios {mem} €")
    if ext:
        partes.append(f"Visitantes {ext} €" if mem else f"{ext} €")
    return " · ".join(partes) or None


def record_to_torneo(rec: dict, links: dict[int, str], provincia_pagina: str) -> Torneo | None:
    fecha = (rec.get("date") or "")[:10]
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", fecha):
        return None
    nombre = re.sub(r"\s+", " ", (rec.get("name") or "")).strip()
    if not nombre:
        return None
    fecha_fin: str | None = None
    # Algunos clubes ponen el rango de fechas en el nombre: "… 20/11/2026-21/11/2026"
    m_rango = re.search(r"\s*(\d{2})/(\d{2})/(\d{4})\s*[-–]\s*(\d{2})/(\d{2})/(\d{4})\s*$", nombre)
    if m_rango:
        d1, m1, y1, d2, m2, y2 = m_rango.groups()
        fecha, fecha_fin = f"{y1}-{m1}-{d1}", f"{y2}-{m2}-{d2}"
        if fecha_fin == fecha:
            fecha_fin = None
        nombre = nombre[: m_rango.start()].strip(" -–")
    provincia = provincia_canonica(rec.get("location")) or provincia_pagina
    club = club_canonico(rec.get("course"))
    more = rec.get("more_info_url") or None
    origen = rec.get("source") or None

    # Los registros que Tornegolf copia de la Federación llevan el id de golfcv:
    # se les da el mismo id para que se fusionen con la fuente golfcv.
    tid: str
    m = _GOLFCV_ID_RE.search(more or "")
    if origen == "comunidad-valenciana" and m:
        tid = f"golfcv-{m.group(1)}"
        origen = "golfcv"
    else:
        tid = f"tornegolf-{rec['id']}"

    reg_open = rec.get("registration_open")
    estado = "abierta" if reg_open is True else ("cerrada" if reg_open is False else None)
    detalles = (rec.get("registration_details") or "").strip() or None
    # La RFEG pone "Competición05/05/2027 — 06/05/2027": es el rango de fechas.
    if detalles:
        m_det = re.search(r"(\d{2})/(\d{2})/(\d{4})\s*[—–-]\s*(\d{2})/(\d{2})/(\d{4})", detalles)
        if m_det:
            d1, m1, y1, d2, m2, y2 = m_det.groups()
            if f"{y1}-{m1}-{d1}" == fecha and fecha_fin is None:
                fecha_fin = f"{y2}-{m2}-{d2}" if f"{y2}-{m2}-{d2}" != fecha else None
            detalles = re.sub(r"competici[oó]n\s*\d{2}/\d{2}/\d{4}\s*[—–-]\s*\d{2}/\d{2}/\d{4}", "", detalles, flags=re.I).strip(" ·-") or None

    descripcion = " | ".join(
        s
        for s in (
            rec.get("description"),
            rec.get("categories"),
            rec.get("play_type"),
            f"club_city={rec.get('club_city')}" if rec.get("club_city") else None,
            f"origen={origen}" if origen else None,
        )
        if s
    ) or None

    return Torneo(
        id=tid,
        fecha=fecha,
        fecha_fin=fecha_fin,
        nombre=nombre,
        club=club,
        provincia=provincia,
        tipo="Club",  # se ajusta en rules.clasificar_tipo
        fuente=NAME,
        modalidad=modalidad_legible(rec.get("scoring_format") or rec.get("modality")),
        inscripcion=detalles,
        precio=_precio(rec),
        estado_inscripcion=estado,
        enlace=links.get(int(rec["id"])),
        enlace_inscripcion=more,
        descripcion=descripcion,
        origen=origen,
    )


def parse_list(html: str, provincia_pagina: str) -> list[Torneo]:
    records = extract_records(html)
    links = extract_links(html)
    out: list[Torneo] = []
    for rec in records:
        t = record_to_torneo(rec, links, provincia_pagina)
        if t is not None:
            out.append(t)
    log.info("tornegolf %s: %d registros", provincia_pagina, len(out))
    return out


def fetch(fetcher) -> list[Torneo]:
    out: list[Torneo] = []
    for provincia, url in LIST_URLS.items():
        try:
            html = fetcher.get(url)
        except Exception as exc:  # noqa: BLE001 - una provincia caída no para el resto
            log.error("tornegolf %s: no se pudo descargar (%s)", provincia, exc)
            continue
        out.extend(parse_list(html, provincia))
    return out


def es_tornegolf(t: Torneo) -> bool:
    return t.fuente == NAME and norm_text(t.origen or "") != "golfcv"
