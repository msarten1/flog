from __future__ import annotations

import json
from datetime import date, timedelta
from pathlib import Path

from flog_scraper.__main__ import FixtureFetcher, main
from flog_scraper.model import Torneo
from flog_scraper.pipeline import guardar, procesar, recolectar
from flog_scraper.store import Catalogo, reconciliar

from conftest import FIXTURES, HOY

ROOT = Path(__file__).resolve().parents[2]


def _legacy(tmp_path: Path) -> Path:
    data = tmp_path / "data"
    data.mkdir()
    src = ROOT / "data" / "torneos.json"
    if src.exists():
        (data / "torneos.json").write_text(src.read_text(encoding="utf-8"), encoding="utf-8")
    return data


def test_pipeline_con_fixtures(tmp_path):
    data = _legacy(tmp_path)
    capturados = recolectar(FixtureFetcher(FIXTURES))
    assert len(capturados) > 150
    res = procesar(capturados, data, usar_llm=False, today=HOY)
    nombres = {t.nombre.lower() for t in res.catalogo.torneos}

    # Sin sociedades ni ligas internas
    assert not any("holanda" in n or "teigur" in n or "monday" in n for n in nombres)
    # Lo federativo y los campeonatos de España están
    assert any("absoluto de la cv" in n for n in nombres)
    assert any("campeonato de españa dobles senior" in n for n in nombres)
    # Nada terminado hace más de 14 días
    assert all(t.fecha_final >= (HOY - timedelta(days=14)).isoformat() for t in res.catalogo.torneos)
    # Los dudosos sin LLM quedan marcados y no se pierden
    assert any(t.revisar for t in res.catalogo.torneos)
    # Nada duplicado (misma fecha, club y nombre)
    claves = [(t.fecha, t.club_norm, t.nombre_norm) for t in res.catalogo.torneos]
    assert len(claves) == len(set(claves))

    guardar(res, data)
    publicado = json.loads((data / "torneos.json").read_text(encoding="utf-8"))
    assert publicado["actualizado"] == HOY.isoformat()
    assert publicado["primera"] <= HOY.isoformat()
    assert all({"id", "fecha", "nombre", "club", "provincia", "tipo"} <= set(t) for t in publicado["torneos"])
    cambios = json.loads((data / "changes.json").read_text(encoding="utf-8"))
    assert set(cambios) >= {"fecha", "nuevos", "cambios", "eliminados", "proximos_14_dias", "inscripciones_cierran"}


def test_pipeline_es_idempotente(tmp_path):
    data = _legacy(tmp_path)
    capturados = recolectar(FixtureFetcher(FIXTURES))
    primera = procesar(capturados, data, usar_llm=False, today=HOY)
    guardar(primera, data)
    segunda = procesar(recolectar(FixtureFetcher(FIXTURES)), data, usar_llm=False, today=HOY)
    assert segunda.cambios.nuevos == []
    assert segunda.cambios.cambios == []
    assert {t.id for t in segunda.catalogo.torneos} == {t.id for t in primera.catalogo.torneos}


def _t(id: str, fecha: str, nombre: str, club: str = "El Bosque", **kw) -> Torneo:
    return Torneo(id=id, fecha=fecha, nombre=nombre, club=club, provincia="Valencia", tipo="Club", fuente="tornegolf", **kw)


def test_reconciliar_detecta_cambios_y_cancelaciones():
    hoy = date(2026, 11, 16)
    anterior = Catalogo(
        actualizado="2026-11-09",
        primera="2026-11-08",
        torneos=[
            _t("a", "2026-12-19", "Torneo de Navidad", anadido="2026-11-08"),
            _t("b", "2026-12-05", "Torneo Desaparecido", anadido="2026-11-08"),
            _t("c", "2026-10-20", "Torneo Antiguo", anadido="2026-11-08"),
        ],
    )
    nuevos = [
        _t("tornegolf-9", "2026-12-20", "Torneo de Navidad"),  # mismo torneo, nueva fecha
        _t("tornegolf-10", "2026-12-28", "Torneo Nuevo"),
    ]
    cat, cambios = reconciliar(nuevos, anterior, today=hoy)
    por_id = {t.id: t for t in cat.torneos}
    assert "a" in por_id and por_id["a"].cambio == "Cambio de fecha (antes 19 dic)"
    assert por_id["a"].anadido == "2026-11-08"
    assert por_id["b"].cambio == "Posiblemente cancelado" and por_id["b"].sin_fuente_desde == hoy.isoformat()
    assert "c" not in por_id
    assert [n["nombre"] for n in cambios.nuevos] == ["Torneo Nuevo"]
    assert cat.primera == "2026-11-08"

    # Ocho días después sigue sin fuente: se elimina.
    cat2, cambios2 = reconciliar([_t("tornegolf-9", "2026-12-20", "Torneo de Navidad")], cat, today=hoy + timedelta(days=8))
    assert "b" not in {t.id for t in cat2.torneos}
    assert [e["id"] for e in cambios2.eliminados] == ["b"]


def test_cli_dry_run(tmp_path, capsys):
    data = _legacy(tmp_path)
    rc = main(["run", "--fixtures", str(FIXTURES), "--data", str(data), "--dry-run", "--no-llm", "--today", HOY.isoformat()])
    assert rc == 0
    out = capsys.readouterr().out
    assert "dry-run" in out and "publicados" in out


def test_descartado_por_clasificador_no_se_anuncia_como_cancelado():
    hoy = date(2026, 11, 16)
    anterior = Catalogo(
        actualizado="2026-11-09",
        primera="2026-11-08",
        torneos=[_t("tornegolf-1", "2026-11-21", "Orden Mérito Parejas", revisar=True)],
    )
    cat, cambios = reconciliar([], anterior, today=hoy, descartados={"tornegolf-1"})
    assert cat.torneos == []
    assert cambios.cambios == [] and cambios.eliminados == []
