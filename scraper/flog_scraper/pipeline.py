"""Orquestación: fuentes → reglas → clasificador → dedupe → reconciliación → ficheros."""

from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import date, timedelta
from pathlib import Path

from . import config
from .classify import clasificar_dudosos
from .dedupe import deduplicar
from .model import Torneo, titulo_bonito
from .rules import aplicar_reglas
from .sources import ALL_SOURCES
from .store import Cambios, Catalogo, escribir_json, leer_catalogo, reconciliar

log = logging.getLogger(__name__)


@dataclass
class Resultado:
    catalogo: Catalogo
    cambios: Cambios
    excluidos: list[tuple[Torneo, str]]
    capturados: int


def recolectar(fetcher, sources=ALL_SOURCES) -> list[Torneo]:
    torneos: list[Torneo] = []
    for src in sources:
        torneos.extend(src.fetch(fetcher))
    return torneos


def procesar(
    capturados: list[Torneo],
    data_dir: Path,
    usar_llm: bool = True,
    today: date | None = None,
) -> Resultado:
    today = today or date.today()
    # Solo interesa lo futuro (o terminado hace pocos días).
    limite = (today - timedelta(days=config.DIAS_RETENCION_PASADOS)).isoformat()
    vigentes = [t for t in capturados if t.fecha_final >= limite]
    for t in vigentes:
        t.nombre = titulo_bonito(t.nombre)
    incluidos, dudosos, excluidos = aplicar_reglas(vigentes)
    log.info("reglas: %d incluidos, %d dudosos, %d excluidos", len(incluidos), len(dudosos), len(excluidos))

    extra, excl_llm = clasificar_dudosos(dudosos, data_dir / "clasificaciones.json", usar_llm=usar_llm)
    incluidos.extend(extra)
    excluidos.extend(excl_llm)

    # Fuera de ventana: solo futuros (o terminados hace poco).
    unicos = deduplicar(incluidos)
    anterior = leer_catalogo(data_dir / "torneos.json")
    descartados = {t.id for t, _ in excluidos}
    catalogo, cambios = reconciliar(unicos, anterior, today=today, descartados=descartados)
    return Resultado(catalogo=catalogo, cambios=cambios, excluidos=excluidos, capturados=len(capturados))


def guardar(resultado: Resultado, data_dir: Path) -> None:
    escribir_json(data_dir / "torneos.json", resultado.catalogo.to_json())
    escribir_json(data_dir / "changes.json", resultado.cambios.to_json())
    log.info(
        "guardado: %d torneos en %s (%s)",
        len(resultado.catalogo.torneos),
        data_dir / "torneos.json",
        resultado.cambios.resumen(),
    )
