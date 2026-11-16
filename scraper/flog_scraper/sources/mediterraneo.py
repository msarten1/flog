"""Club de Campo Mediterráneo (Borriol, Castellón): https://mediterraneo.golf/en/calendar/

Calendario del plugin "Simple Calendar": cada evento es un `li.simcal-event`
con microdatos schema.org (name, startDate) y un enlace de detalle.
"""

from __future__ import annotations

import logging
import re

from bs4 import BeautifulSoup

from ..model import Torneo, slug

log = logging.getLogger(__name__)

NAME = "mediterraneo"
URL = "https://mediterraneo.golf/en/calendar/"
CLUB = "Mediterráneo Golf"
PROVINCIA = "Castellón"
_GOLFCV_ID_RE = re.compile(r"torneoid=(\d+)")


def parse_html(html: str) -> list[Torneo]:
    soup = BeautifulSoup(html, "lxml")
    out: list[Torneo] = []
    for li in soup.select("li.simcal-event"):
        name_el = li.select_one('[itemprop="name"]')
        start_el = li.select_one('[itemprop="startDate"]')
        if not name_el or not start_el:
            continue
        nombre = re.sub(r"\s+", " ", name_el.get_text(" ", strip=True)).strip()
        fecha = (start_el.get("content") or "")[:10]
        if not nombre or not re.fullmatch(r"\d{4}-\d{2}-\d{2}", fecha):
            continue
        desc_link = li.select_one(".simcal-event-description a[href]")
        insc = li.select_one("a.btn-insc[href]")
        enlace = desc_link["href"] if desc_link else (insc["href"] if insc else URL)
        enlace_insc = insc["href"] if insc else None

        origen = NAME
        tid = f"mediterraneo-{fecha.replace('-', '')}-{slug(nombre, 30)}"
        m = _GOLFCV_ID_RE.search(enlace or "")
        if m:
            tid = f"golfcv-{m.group(1)}"
            origen = "golfcv"
        tipo = "Circuito" if "circuito" in nombre.lower() else "Club"
        out.append(
            Torneo(
                id=tid,
                fecha=fecha,
                nombre=nombre,
                club=CLUB,
                provincia=PROVINCIA,
                tipo=tipo,
                fuente=NAME,
                enlace=enlace,
                enlace_inscripcion=enlace_insc,
                descripcion=f"origen={origen}",
                origen=origen,
            )
        )
    log.info("mediterraneo: %d eventos", len(out))
    return out


def fetch(fetcher) -> list[Torneo]:
    try:
        html = fetcher.get(URL)
    except Exception as exc:  # noqa: BLE001
        log.error("mediterraneo: no se pudo descargar (%s)", exc)
        return []
    return parse_html(html)
