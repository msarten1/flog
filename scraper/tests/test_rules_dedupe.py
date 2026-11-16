from __future__ import annotations

import pytest

from flog_scraper.dedupe import deduplicar, mismo_torneo
from flog_scraper.model import Torneo, club_canonico, titulo_bonito
from flog_scraper.rules import Decision, clasificar_tipo, decidir


def t(nombre: str, fuente: str = "tornegolf", club: str = "El Bosque", fecha: str = "2026-12-01", **kw) -> Torneo:
    return Torneo(
        id=kw.pop("id", f"{fuente}-{abs(hash(nombre)) % 10000}"),
        fecha=fecha,
        nombre=nombre,
        club=club,
        provincia="Valencia",
        tipo="Club",
        fuente=fuente,
        **kw,
    )


@pytest.mark.parametrize(
    "nombre",
    [
        "MONDAY COMPETITION",
        "Tuesday Duel Eclectic 2026 - Round 46",
        "GOLF HOLANDA 18 HOYOS",
        "TEIGUR GOLF SOCIETY",
        "SAS Stableford Eclectic",
        "Wednesday Afternoon Golf",
        "LIGA SENIOR DE BONALBA 2026 (DICIEMBRE)",
        "Ladies Golf League 2026 - 8",
        "The 12 - Round 12 - Las Colinas",
        "Rencontre AGFCB 30 - Lo Romero",
        "TORNEO BENEFICO 2026 LIGAS GOLF (BENJAMINES)",
        "18H Torneo Mensual Infantil",
        "CTO DOBLES DE PROFESIONALES DE LA CV",
        "ALTEA GOLF SOCIETY NOVIEMBRE 2026",
        "BENIDORM MASTERS LEAGUE - BML -J1",
    ],
)
def test_excluidos(nombre):
    assert decidir(t(nombre))[0] is Decision.EXCLUIR


@pytest.mark.parametrize(
    "nombre",
    [
        "V TORNEO DE GOLF MUTXAMEL",
        "Christmas Scramble",
        "Texas Scramble Champion Of Champions",
        "Circuito Locos por el Golf",
        "PRO-AM - 125 Aniversario CAMARA ORIHUELA",
        "Torneo Fin de Año",
        "LAS COLINAS TROPHY - V EDICIÓN",
        "COPA DE OTOÑO 2026",
    ],
)
def test_incluidos(nombre):
    assert decidir(t(nombre))[0] is Decision.INCLUIR


def test_dudosos_van_al_clasificador():
    assert decidir(t("V MY LAWYER IN SPAIN"))[0] is Decision.DUDOSO
    assert decidir(t("9 & Tapas"))[0] is Decision.DUDOSO


def test_federativo_incluye_liguillas_pero_no_profesionales():
    assert decidir(t("LIGUILLA SENIOR MASCULINA ZONA ALC 1DIV 9/9", fuente="golfcv"))[0] is Decision.INCLUIR
    assert decidir(t("CTO DOBLES DE PROFESIONALES DE LA CV", fuente="golfcv"))[0] is Decision.EXCLUIR
    assert decidir(t("GALA PRO-AM FGCV 2026", fuente="golfcv"))[0] is Decision.INCLUIR


def test_tipos():
    assert clasificar_tipo(t("Campeonato de España Dobles Senior Masculino 2027")) == "Nacional en la CV"
    assert clasificar_tipo(t("Circuito Locos por el Golf")) == "Circuito"
    assert clasificar_tipo(t("CIRCUITO SENIOR CV CAIXA POPULAR 1/4", fuente="golfcv")) == "Federación"
    assert clasificar_tipo(t("Torneo de Navidad")) == "Club"


def test_club_canonico():
    assert club_canonico("VILLAITANA GOLF - Levante") == "Meliá Villaitana Golf"
    assert club_canonico("Meliá Villaitana Golf") == "Meliá Villaitana Golf"
    assert club_canonico("CAMPO LA SELLA - Llebeig+Gregal") == "La Sella Golf"
    assert club_canonico("El Bosque Golf") == "El Bosque"
    assert club_canonico("Campo de Golf Parador El Saler") == "El Saler"
    assert club_canonico("Escuela De Golf De Elche Fgcv") == "Escuela de Golf de Elche"
    assert club_canonico("Panorámica Golf, Sports & Resort") == "Panorámica Golf"
    assert club_canonico("Campo De Golf Villamartí­n") == "Villamartín"
    assert club_canonico("UN CLUB DESCONOCIDO") == "Un Club Desconocido"


def test_titulo_bonito():
    assert titulo_bonito("CTO ABSOLUTO DE LA CV") == "Cto Absoluto de la CV"
    assert titulo_bonito("LIGUILLA SENIOR MASCULINA ZONA VLC/CS 1DIV 2DIV 8/9") == "Liguilla Senior Masculina Zona VLC/CS 1DIV 2DIV 8/9"
    assert titulo_bonito("XIX TORNEO DE GOLF SÍNDROME DOWN") == "XIX Torneo de Golf Síndrome Down"
    assert titulo_bonito("Torneo de Navidad") == "Torneo de Navidad"


def test_mismo_torneo_y_fusion():
    a = t("CTO ABSOLUTO DE LA CV", fuente="golfcv", club="Font del Llop", id="golfcv-1")
    b = t("JUGADORES NO LV CTO ABSOLUTO DE LA CV", fuente="golfcv", club="Club de Golf Font del Llop", id="golfcv-2")
    assert mismo_torneo(a, b)
    c = t("Copa Levante Summum Golf", club="Meliá Villaitana Golf", fecha="2026-11-21", id="tornegolf-1")
    d = t("VILLAITANA COPA LEVANTE 2026", club="VILLAITANA GOLF - Levante", fecha="2026-11-21", id="tornegolf-2")
    assert mismo_torneo(c, d)
    e = t("CIRCUITO 9 HOYOS EXECUTIVE (1/5)", fuente="golfcv", club="Golf Ifach", id="golfcv-3")
    f = t("CIRCUITO DE 5 CAT (1/5)", fuente="golfcv", club="Golf Ifach", id="golfcv-4")
    assert not mismo_torneo(e, f)

    g = t("Torneo Navidad Vistabella Golf", club="VISTABELLA - Vistabella", fecha="2026-12-06", id="tornegolf-5", modalidad="Fourball Stableford")
    h = t("Torneo de Navidad", club="Vistabella Golf", fecha="2026-12-06", id="tornegolf-6", precio="40 €")
    res = deduplicar([g, h])
    assert len(res) == 1
    assert res[0].modalidad == "Fourball Stableford" and res[0].precio == "40 €"
