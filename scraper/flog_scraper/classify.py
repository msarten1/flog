"""Clasificación de los torneos dudosos con la API de OpenAI.

Solo se consulta por los torneos que las reglas no resuelven y que no están
ya en la caché `data/clasificaciones.json` (que se puede editar a mano y
tiene prioridad sobre la API).
"""

from __future__ import annotations

import json
import logging
import os
from pathlib import Path

from . import config
from .model import Torneo

log = logging.getLogger(__name__)

SYSTEM_PROMPT = """Eres el encargado de mantener un calendario de torneos de golf AMATEUR de la Comunitat Valenciana (Alicante, Valencia y Castellón) para golfistas aficionados que quieren apuntarse a torneos abiertos.

Para cada torneo decide si se INCLUYE en el calendario y de qué tipo es.

INCLUIR: campeonatos y circuitos federativos amateur, torneos abiertos de club (cualquier jugador con licencia puede inscribirse), circuitos amateur (Locos por el Golf, Yoingolf, Mediterráneo, Fuera de Límites, etc.), pruebas nacionales RFEG amateur que se juegan en la Comunitat Valenciana, torneos benéficos o de patrocinador abiertos, pro-am.

EXCLUIR: competiciones profesionales (salvo pro-am); juveniles, infantiles, benjamines, cadetes, junior; competiciones semanales o internas de sociedades o grupos de socios (Monday/Tuesday Competition, Tuesday Duel, Golf Holanda, Teigur Golf Society, SAS, Wednesday Afternoon, ligas internas, ligas senior de un club, órdenes de mérito internos, "The 12", eclectic, medal mensual, ladies league, encuentros de asociaciones extranjeras); clases, clínics o entrenamientos.

Si dudas entre incluir o excluir un torneo de club con nombre propio (sponsor, aniversario, copa de otoño...), inclúyelo.

Tipos: "Federación" (organiza la FGCV), "Club" (torneo abierto de un club), "Circuito" (prueba de un circuito amateur), "Nacional en la CV" (campeonato o internacional de España de la RFEG)."""

SCHEMA = {
    "name": "clasificacion_torneos",
    "strict": True,
    "schema": {
        "type": "object",
        "additionalProperties": False,
        "properties": {
            "items": {
                "type": "array",
                "items": {
                    "type": "object",
                    "additionalProperties": False,
                    "properties": {
                        "id": {"type": "string"},
                        "incluir": {"type": "boolean"},
                        "tipo": {"type": "string", "enum": list(config.TIPOS)},
                        "motivo": {"type": "string"},
                    },
                    "required": ["id", "incluir", "tipo", "motivo"],
                },
            }
        },
        "required": ["items"],
    },
}


def cargar_cache(path: Path) -> dict[str, dict]:
    if path.exists():
        try:
            return json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            log.warning("clasificaciones.json corrupto; se ignora")
    return {}


def guardar_cache(path: Path, cache: dict[str, dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(dict(sorted(cache.items())), ensure_ascii=False, indent=1) + "\n",
        encoding="utf-8",
    )


def _describir(t: Torneo) -> dict:
    return {
        "id": t.id,
        "nombre": t.nombre,
        "club": t.club,
        "provincia": t.provincia,
        "fecha": t.fecha,
        "modalidad": t.modalidad,
        "precio": t.precio,
        "inscripcion": t.inscripcion,
        "descripcion": t.descripcion,
        "fuente": t.fuente,
    }


def consultar_openai(torneos: list[Torneo], model: str = config.OPENAI_MODEL) -> dict[str, dict]:
    """Llama a la API con todos los dudosos en un único mensaje."""
    from openai import OpenAI  # import diferido: solo si hace falta

    client = OpenAI()
    payload = json.dumps([_describir(t) for t in torneos], ensure_ascii=False, indent=1)
    resp = client.chat.completions.create(
        model=model,
        temperature=0,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {
                "role": "user",
                "content": "Clasifica estos torneos. Devuelve exactamente un elemento por id.\n\n" + payload,
            },
        ],
        response_format={"type": "json_schema", "json_schema": SCHEMA},
    )
    content = resp.choices[0].message.content or "{}"
    data = json.loads(content)
    out: dict[str, dict] = {}
    for item in data.get("items", []):
        out[item["id"]] = {
            "incluir": bool(item["incluir"]),
            "tipo": item["tipo"],
            "motivo": item.get("motivo", ""),
            "modelo": model,
        }
    return out


def clasificar_dudosos(
    dudosos: list[Torneo],
    cache_path: Path,
    usar_llm: bool = True,
) -> tuple[list[Torneo], list[tuple[Torneo, str]]]:
    """→ (incluidos, excluidos_con_motivo). Los no resueltos se incluyen con `revisar=True`."""
    if not dudosos:
        return [], []
    cache = cargar_cache(cache_path)
    pendientes = [t for t in dudosos if t.id not in cache]

    if pendientes and usar_llm:
        if not os.environ.get("OPENAI_API_KEY"):
            log.warning("OPENAI_API_KEY no definida: %d dudosos quedan marcados para revisar", len(pendientes))
        else:
            try:
                nuevos = consultar_openai(pendientes)
                cache.update(nuevos)
                guardar_cache(cache_path, cache)
                log.info("openai: clasificados %d/%d dudosos", len(nuevos), len(pendientes))
            except Exception as exc:  # noqa: BLE001 - nunca bloquear el cron
                log.error("openai: fallo al clasificar (%s); se marcan para revisar", exc)

    incluidos: list[Torneo] = []
    excluidos: list[tuple[Torneo, str]] = []
    for t in dudosos:
        decision = cache.get(t.id)
        if decision is None:
            t.revisar = True
            incluidos.append(t)
        elif decision.get("incluir"):
            if decision.get("tipo") in config.TIPOS:
                t.tipo = decision["tipo"]
            incluidos.append(t)
        else:
            excluidos.append((t, f"openai: {decision.get('motivo', '')}"))
    return incluidos, excluidos
