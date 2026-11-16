"""CLI del scraper.

    python -m flog_scraper run [--data DIR] [--dry-run] [--no-llm] [--fixtures DIR]
    python -m flog_scraper notify [--data DIR] [--dry-run] [--test [--topic T]]
"""

from __future__ import annotations

import argparse
import json
import logging
import sys
from datetime import date
from pathlib import Path

from . import config, fcm
from .http import Fetcher
from .pipeline import guardar, procesar, recolectar
from .sources import golfcv, mediterraneo, tornegolf
from .store import Cambios

DEFAULT_DATA = Path(__file__).resolve().parents[2] / "data"


class FixtureFetcher:
    """Sirve los HTML/JSON guardados en tests/fixtures en lugar de la red."""

    def __init__(self, root: Path) -> None:
        self.root = root

    def _read(self, name: str) -> str:
        return (self.root / name).read_text(encoding="utf-8")

    def get(self, url: str, **_: object) -> str:
        for prov, u in tornegolf.LIST_URLS.items():
            if url == u:
                return self._read(f"tornegolf_{tornegolf.norm_text(prov)}.html")
        if url == mediterraneo.URL:
            return self._read("mediterraneo_calendar.html")
        raise FileNotFoundError(url)

    def post(self, url: str, data: dict | None = None, **_: object) -> str:
        if url == golfcv.ENDPOINT:
            path = self.root / f"golfcv_{(data or {}).get('year')}.json"
            return path.read_text(encoding="utf-8") if path.exists() else "[]"
        raise FileNotFoundError(url)


def cmd_run(args: argparse.Namespace) -> int:
    data_dir = Path(args.data)
    fetcher = FixtureFetcher(Path(args.fixtures)) if args.fixtures else Fetcher()
    capturados = recolectar(fetcher)
    if not capturados:
        logging.error("ninguna fuente devolvió datos; no se escribe nada")
        return 2
    today = date.fromisoformat(args.today) if args.today else None
    resultado = procesar(capturados, data_dir, usar_llm=not args.no_llm, today=today)

    print(f"Capturados: {resultado.capturados} · publicados: {len(resultado.catalogo.torneos)} · {resultado.cambios.resumen()}")
    if args.verbose:
        for t, motivo in resultado.excluidos:
            print(f"  - excluido  {t.fecha} {t.nombre[:50]!r} [{t.fuente}] → {motivo}")
    for t in resultado.cambios.nuevos:
        print(f"  + nuevo     {t['fecha']} {t['nombre']} · {t['club']} ({t['provincia']}, {t['tipo']})")
    for t in resultado.cambios.cambios:
        print(f"  ~ cambio    {t['fecha']} {t['nombre']} → {t.get('cambio')}")
    for t in resultado.cambios.eliminados:
        print(f"  x eliminado {t['fecha']} {t['nombre']}")
    for t in resultado.cambios.revisar:
        print(f"  ? revisar   {t['fecha']} {t['nombre']} · {t['club']}")

    if args.dry_run:
        print("(dry-run: no se ha escrito nada)")
        return 0
    guardar(resultado, data_dir)
    return 0


def cmd_notify(args: argparse.Namespace) -> int:
    if args.test:
        topic = args.topic or config.FCM_TOPIC_GLOBAL
        if args.dry_run:
            print(f"(dry-run) prueba → {topic}")
            return 0
        fcm.enviar(topic, "Flog · prueba", "Si lees esto, las notificaciones funcionan.", {"screen": "novedades"})
        print(f"Enviada notificación de prueba al tema '{topic}'")
        return 0
    path = Path(args.data) / "changes.json"
    if not path.exists():
        print("No hay changes.json; ejecuta primero `run`.")
        return 1
    cambios = Cambios(**json.loads(path.read_text(encoding="utf-8")))
    semanal = True if args.semanal else None
    n = fcm.notificar(cambios, dry_run=args.dry_run, data_dir=Path(args.data), semanal=semanal)
    print(f"Notificaciones enviadas: {n}")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="flog-scraper", description="Scraper de torneos de golf amateur de la CV")
    parser.add_argument("-v", "--verbose", action="store_true", help="muestra también los excluidos")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_run = sub.add_parser("run", help="descarga, clasifica y escribe data/torneos.json")
    p_run.add_argument("--data", default=str(DEFAULT_DATA))
    p_run.add_argument("--dry-run", action="store_true")
    p_run.add_argument("--no-llm", action="store_true", help="no consultar la API de OpenAI")
    p_run.add_argument("--fixtures", help="usar los HTML guardados en este directorio en vez de la red")
    p_run.add_argument("--today", help="fecha simulada AAAA-MM-DD (tests)")
    p_run.set_defaults(func=cmd_run)

    p_not = sub.add_parser("notify", help="envía las notificaciones push de data/changes.json")
    p_not.add_argument("--data", default=str(DEFAULT_DATA))
    p_not.add_argument("--dry-run", action="store_true")
    p_not.add_argument("--test", action="store_true", help="envía una notificación de prueba")
    p_not.add_argument("--topic")
    p_not.add_argument("--semanal", action="store_true", help="forzar el resumen semanal aunque no sea lunes")
    p_not.set_defaults(func=cmd_notify)

    args = parser.parse_args(argv)
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(name)s: %(message)s", stream=sys.stderr)
    logging.getLogger("flog_scraper").setLevel(logging.DEBUG if args.verbose else logging.INFO)
    for ruidoso in ("openai", "httpx", "httpx2", "httpcore", "httpcore2", "urllib3"):
        logging.getLogger(ruidoso).setLevel(logging.WARNING)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
