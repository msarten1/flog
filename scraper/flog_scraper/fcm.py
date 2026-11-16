"""Envío de notificaciones push con Firebase Cloud Messaging (HTTP v1).

Requiere el JSON de una cuenta de servicio del proyecto Firebase en la
variable de entorno FCM_SERVICE_ACCOUNT_JSON (contenido) o
FCM_SERVICE_ACCOUNT_FILE (ruta).
"""

from __future__ import annotations

import json
import logging
import os
from datetime import date
from pathlib import Path

import requests

from . import config
from .model import fecha_corta
from .novedades import Novedades
from .store import Cambios

log = logging.getLogger(__name__)

SCOPE = "https://www.googleapis.com/auth/firebase.messaging"


def _credenciales():
    from google.oauth2 import service_account  # import diferido

    raw = os.environ.get("FCM_SERVICE_ACCOUNT_JSON")
    path = os.environ.get("FCM_SERVICE_ACCOUNT_FILE")
    if raw:
        info = json.loads(raw)
    elif path:
        with open(path, encoding="utf-8") as fh:
            info = json.load(fh)
    else:
        raise RuntimeError("Falta FCM_SERVICE_ACCOUNT_JSON o FCM_SERVICE_ACCOUNT_FILE")
    creds = service_account.Credentials.from_service_account_info(info, scopes=[SCOPE])
    return creds, info["project_id"]


def _token(creds) -> str:
    from google.auth.transport.requests import Request

    creds.refresh(Request())
    return creds.token


def enviar(topic: str, titulo: str, cuerpo: str, data: dict[str, str] | None = None) -> dict:
    creds, project_id = _credenciales()
    url = f"https://fcm.googleapis.com/v1/projects/{project_id}/messages:send"
    mensaje = {
        "message": {
            "topic": topic,
            "notification": {"title": titulo, "body": cuerpo},
            "data": data or {},
            "android": {
                "priority": "high",
                "notification": {"channel_id": "flog_torneos", "icon": "ic_notification", "color": "#0F3D2E"},
            },
        }
    }
    r = requests.post(
        url,
        json=mensaje,
        headers={"Authorization": f"Bearer {_token(creds)}", "Content-Type": "application/json"},
        timeout=20,
    )
    r.raise_for_status()
    log.info("fcm: enviado a '%s': %s", topic, titulo)
    return r.json()


def _linea(t: dict) -> str:
    return f"{fecha_corta(t['fecha'])} · {t['nombre']} · {t['club']}"


def mensajes_desde_cambios(cambios: Cambios) -> list[tuple[str, str, str, dict[str, str]]]:
    """Construye (topic, título, cuerpo, data) por provincia y uno global."""
    out = []
    semana = fecha_corta(cambios.fecha)  # fecha de la revisión
    for provincia, topic in config.FCM_TOPICS.items():
        nuevos = [t for t in cambios.nuevos if t["provincia"] == provincia]
        cambiados = [t for t in cambios.cambios if t["provincia"] == provincia]
        if not nuevos and not cambiados:
            continue
        titulo = f"Flog · {provincia}: " + " y ".join(
            p for p in (f"{len(nuevos)} nuevos" if nuevos else "", f"{len(cambiados)} cambios" if cambiados else "") if p
        )
        lineas = [_linea(t) for t in nuevos[:3]] + [f"{_linea(t)} ({t.get('cambio')})" for t in cambiados[:2]]
        cuerpo = "\n".join(lineas)
        ids = ",".join(t["id"] for t in (nuevos + cambiados)[:10])
        out.append((topic, titulo, cuerpo, {"screen": "novedades", "provincia": provincia, "ids": ids}))
    if cambios.nuevos or cambios.cambios:
        out.append(
            (
                config.FCM_TOPIC_GLOBAL,
                f"Flog · novedades del {semana}",
                cambios.resumen() + (f" · {len(cambios.proximos_14_dias)} torneos en 14 días" if cambios.proximos_14_dias else ""),
                {"screen": "novedades"},
            )
        )
    return out


def mensajes_semanales(novedades: Novedades, today: date) -> list[tuple[str, str, str, dict[str, str]]]:
    """Resumen de los últimos 7 días para los temas '-semanal'."""
    out = []
    nuevos7, cambios7 = novedades.ultimos(7, today)
    for provincia, topic in config.FCM_TOPICS.items():
        nuevos = [t for t in nuevos7 if t["provincia"] == provincia]
        cambiados = [t for t in cambios7 if t["provincia"] == provincia]
        if not nuevos and not cambiados:
            continue
        titulo = f"Flog · {provincia}, esta semana: " + " y ".join(
            p for p in (f"{len(nuevos)} nuevos" if nuevos else "", f"{len(cambiados)} cambios" if cambiados else "") if p
        )
        lineas = [_linea(t) for t in nuevos[:4]] + [f"{_linea(t)} ({t.get('cambio')})" for t in cambiados[:2]]
        ids = ",".join(t["id"] for t in (nuevos + cambiados)[:10])
        out.append((topic + config.FCM_SUFIJO_SEMANAL, titulo, "\n".join(lineas), {"screen": "novedades", "provincia": provincia, "ids": ids}))
    if nuevos7 or cambios7:
        out.append(
            (
                config.FCM_TOPIC_GLOBAL + config.FCM_SUFIJO_SEMANAL,
                f"Flog · resumen de la semana",
                f"{len(nuevos7)} torneos nuevos · {len(cambios7)} cambios",
                {"screen": "novedades"},
            )
        )
    return out


def mensajes_cierre(cambios: Cambios, novedades: Novedades, today: date) -> list[tuple[str, str, str, dict[str, str]]]:
    """Aviso único por torneo cuando su inscripción cierra en DIAS_AVISO_CIERRE días o menos.

    Va a los dos temas de la provincia (diario y semanal): es urgente para todos.
    """
    out = []
    limite = (today.toordinal() + config.DIAS_AVISO_CIERRE)
    for t in cambios.inscripciones_cierran:
        cierre = t.get("cierre")
        if not cierre or t["id"] in novedades.avisos_cierre:
            continue
        if date.fromisoformat(cierre).toordinal() > limite:
            continue
        topic = config.FCM_TOPICS.get(t["provincia"])
        if not topic:
            continue
        cuando = "hoy" if cierre == today.isoformat() else f"el {fecha_corta(cierre)}"
        titulo = f"Flog · cierra inscripción {cuando}"
        cuerpo = f"{t['nombre']} · {t['club']} · se juega el {fecha_corta(t['fecha'])}"
        data = {"screen": "torneo", "ids": t["id"], "provincia": t["provincia"]}
        out.append((topic, titulo, cuerpo, data))
        out.append((topic + config.FCM_SUFIJO_SEMANAL, titulo, cuerpo, data))
        novedades.avisos_cierre.append(t["id"])
    return out


def notificar(
    cambios: Cambios,
    dry_run: bool = False,
    data_dir: Path | None = None,
    semanal: bool | None = None,
    today: date | None = None,
) -> int:
    """Envía los avisos diarios, los de cierre de inscripción y, los lunes, el resumen semanal."""
    today = today or date.today()
    mensajes = list(mensajes_desde_cambios(cambios))
    novedades = Novedades.leer(data_dir / "novedades.json") if data_dir else Novedades()
    mensajes += mensajes_cierre(cambios, novedades, today)
    if semanal is None:
        semanal = today.weekday() == 0  # lunes
    if semanal:
        mensajes += mensajes_semanales(novedades, today)

    enviados = 0
    for topic, titulo, cuerpo, data in mensajes:
        if dry_run:
            log.info("fcm (dry-run) → %s | %s | %s", topic, titulo, cuerpo.replace("\n", " / "))
            continue
        try:
            enviar(topic, titulo, cuerpo, data)
            enviados += 1
        except Exception as exc:  # noqa: BLE001
            log.error("fcm: fallo enviando a %s (%s)", topic, exc)
    if data_dir and not dry_run:
        from .store import escribir_json

        escribir_json(data_dir / "novedades.json", novedades.to_json())
    return enviados
