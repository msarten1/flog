"""Constantes de configuración del scraper."""

from __future__ import annotations

import os

REPO_URL = os.environ.get("FLOG_REPO_URL", "https://github.com/msarten1/flog")
USER_AGENT = f"FlogBot/1.0 (+{REPO_URL})"

# Pausa mínima entre peticiones a la misma web (segundos).
REQUEST_DELAY = float(os.environ.get("FLOG_REQUEST_DELAY", "1.0"))
REQUEST_TIMEOUT = 20

PROVINCIAS = ("Alicante", "Valencia", "Castellón")

# Temas de Firebase Cloud Messaging (solo [a-zA-Z0-9-_.~%]).
FCM_TOPICS = {
    "Alicante": "prov-alicante",
    "Valencia": "prov-valencia",
    "Castellón": "prov-castellon",
}
FCM_TOPIC_GLOBAL = "todos"

# Torneos terminados hace más de estos días se eliminan del calendario.
DIAS_RETENCION_PASADOS = 14
# Un torneo que desaparece de su fuente antes de celebrarse se mantiene
# marcado como "Posiblemente cancelado" durante estos días antes de borrarse.
DIAS_SIN_FUENTE = 8

TIPOS = ("Federación", "Club", "Circuito", "Nacional en la CV")

OPENAI_MODEL = os.environ.get("FLOG_OPENAI_MODEL", "gpt-4.1-mini")
