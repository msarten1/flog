from __future__ import annotations

from flog_scraper.sources import golfcv, mediterraneo, tornegolf

from conftest import HOY, leer


def test_tornegolf_extrae_todos_los_registros():
    html = leer("tornegolf_alicante.html")
    assert len(tornegolf.extract_records(html)) == 76
    assert len(tornegolf.extract_links(html)) == 76


def test_tornegolf_parse_campos():
    torneos = tornegolf.parse_list(leer("tornegolf_valencia.html"), "Valencia")
    assert len(torneos) == 22
    noveles = next(t for t in torneos if t.nombre == "Torneo Noveles")
    assert noveles.fecha == "2026-12-12"
    assert noveles.club == "El Bosque"
    assert noveles.provincia == "Valencia"
    assert noveles.modalidad == "Individual Stableford"
    assert noveles.enlace.startswith("https://www.tornegolf.com/torneos/")
    assert noveles.enlace_inscripcion.startswith("https://www.golfdirecto.com/")
    assert noveles.id.startswith("tornegolf-")


def test_tornegolf_rango_de_fechas_en_el_nombre():
    torneos = tornegolf.parse_list(leer("tornegolf_valencia.html"), "Valencia")
    msc = next(t for t in torneos if "MSC" in t.nombre.upper())
    assert msc.fecha == "2026-11-20"
    assert msc.fecha_fin == "2026-11-21"
    assert "20/11" not in msc.nombre


def test_tornegolf_republicados_de_golfcv_comparten_id():
    torneos = tornegolf.parse_list(leer("tornegolf_alicante.html"), "Alicante")
    absoluto = next(t for t in torneos if "ABSOLUTO" in t.nombre.upper() and "NO LV" not in t.nombre.upper())
    assert absoluto.id.startswith("golfcv-")
    assert absoluto.origen == "golfcv"


def test_tornegolf_castellon_rfeg():
    torneos = tornegolf.parse_list(leer("tornegolf_castellon.html"), "Castellón")
    assert len(torneos) == 8
    rfeg = [t for t in torneos if t.origen == "rfeg"]
    assert len(rfeg) == 2
    assert all(t.provincia == "Castellón" and t.club == "Mediterráneo Golf" for t in rfeg)


def test_golfcv_parse_filtra_juveniles_profesionales_y_resto():
    torneos = golfcv.parse_json(leer("golfcv_2026.json"), today=HOY)
    assert torneos
    assert all(t.provincia in ("Alicante", "Valencia", "Castellón") for t in torneos)
    assert not any("profesional" in t.nombre.lower() for t in torneos)
    assert not any("infantil" in t.nombre.lower() for t in torneos)
    absoluto = next(t for t in torneos if t.nombre == "CTO ABSOLUTO DE LA CV")
    assert absoluto.fecha == "2026-11-27" and absoluto.fecha_fin == "2026-11-29"
    assert absoluto.club == "Font del Llop"
    assert absoluto.precio == "100 €"
    assert absoluto.cierre_inscripcion == "2026-11-23"
    assert absoluto.inscripcion.startswith("Inscripción del 23 oct al 23 nov")
    assert absoluto.enlace.endswith("torneoid=" + absoluto.id.split("-")[1])
    assert absoluto.tipo == "Federación"


def test_mediterraneo_parse():
    torneos = mediterraneo.parse_html(leer("mediterraneo_calendar.html"))
    assert len(torneos) == 3
    navidad = next(t for t in torneos if "NAVIDAD" in t.nombre)
    assert navidad.fecha == "2026-12-20"
    assert navidad.club == "Mediterráneo Golf" and navidad.provincia == "Castellón"
    liguilla = next(t for t in torneos if "LIGUILLA" in t.nombre)
    assert liguilla.id == "golfcv-2717"
    circuito = next(t for t in torneos if "CIRCUITO" in t.nombre)
    assert circuito.tipo == "Circuito"
