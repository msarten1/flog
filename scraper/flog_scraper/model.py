"""Modelo de torneo y utilidades de normalización."""

from __future__ import annotations

import re
import unicodedata
from dataclasses import dataclass, field, fields
from datetime import date

from . import config

# Orden de los campos en el JSON publicado (los que no existen se omiten).
JSON_FIELDS = (
    "id",
    "fecha",
    "fecha_fin",
    "nombre",
    "club",
    "provincia",
    "tipo",
    "modalidad",
    "inscripcion",
    "precio",
    "estado_inscripcion",
    "enlace",
    "enlace_inscripcion",
    "fuente",
    "anadido",
    "cambio",
    "revisar",
    "sin_fuente_desde",
)


@dataclass
class Torneo:
    id: str
    fecha: str  # AAAA-MM-DD
    nombre: str
    club: str
    provincia: str
    tipo: str
    fuente: str  # tornegolf | golfcv | mediterraneo
    fecha_fin: str | None = None
    modalidad: str | None = None
    inscripcion: str | None = None
    precio: str | None = None
    estado_inscripcion: str | None = None  # abierta | cerrada
    enlace: str | None = None
    enlace_inscripcion: str | None = None
    anadido: str | None = None
    cambio: str | None = None
    revisar: bool = False
    sin_fuente_desde: str | None = None
    # Contexto adicional para el clasificador; no se publica.
    descripcion: str | None = field(default=None, repr=False)
    # Origen real cuando un agregador republica datos de otra fuente.
    origen: str | None = field(default=None, repr=False)
    # Fecha de cierre de inscripción (AAAA-MM-DD) si se conoce; no se publica.
    cierre_inscripcion: str | None = field(default=None, repr=False)

    # ----- serialización -----
    def to_json(self) -> dict:
        out: dict = {}
        for name in JSON_FIELDS:
            value = getattr(self, name)
            if value is None or value is False:
                continue
            out[name] = value
        return out

    @classmethod
    def from_json(cls, data: dict) -> "Torneo":
        known = {f.name for f in fields(cls)}
        kwargs = {k: v for k, v in data.items() if k in known}
        kwargs.setdefault("fuente", "legacy")
        return cls(**kwargs)

    # ----- helpers -----
    @property
    def fecha_final(self) -> str:
        return self.fecha_fin or self.fecha

    @property
    def club_norm(self) -> str:
        return club_canonico(self.club)

    @property
    def nombre_norm(self) -> str:
        """Forma comparable del nombre: sin numeraciones de prueba (1/5), sin tokens de un carácter."""
        s = norm_text(self.nombre)
        s = re.sub(r"\b\d+\s*/\s*\d+\b", " ", s)
        s = " ".join(w for w in s.split() if len(w) > 1)
        return s


# ---------------------------------------------------------------------------
# Normalización de texto
# ---------------------------------------------------------------------------

def strip_accents(s: str) -> str:
    return "".join(
        c for c in unicodedata.normalize("NFKD", s) if not unicodedata.combining(c)
    )


def norm_text(s: str | None) -> str:
    """Minúsculas, sin acentos, sin signos y con espacios colapsados."""
    if not s:
        return ""
    s = strip_accents(s.replace("­", "")).lower()
    s = re.sub(r"[^a-z0-9ñ&/ ]+", " ", s)
    s = s.replace("&", " & ").replace("/", " / ")
    return re.sub(r"\s+", " ", s).strip()


_SIGLAS = {"cv", "fgcv", "rfeg", "aesgolf", "wagr", "rcg", "ege", "msc", "pp", "om", "bcg", "mvgt", "alc", "vlc", "cs", "lv", "ka", "agfcb", "bml"}
_MINUSCULAS = {"de", "del", "la", "las", "el", "los", "y", "e", "o", "u", "a", "en", "por", "con", "para", "al", "the", "of", "and", "in"}
_ROMANO = re.compile(r"^(?=[ivxlcdm]+$)m{0,3}(cm|cd|d?c{0,3})(xc|xl|l?x{0,3})(ix|iv|v?i{0,3})$")


def titulo_bonito(nombre: str) -> str:
    """Convierte nombres en MAYÚSCULAS a Título, respetando siglas y numerales."""
    letras = [c for c in nombre if c.isalpha()]
    if not letras or sum(c.isupper() for c in letras) / len(letras) < 0.7:
        return nombre
    def palabra(w: str, primera: bool) -> str:
        core = re.sub(r"[^\wñáéíóúü]", "", w.lower())
        if not core:
            return w
        if core in _SIGLAS or _ROMANO.match(core) or re.fullmatch(r"\d+(div|h|ª|º)?", core):
            return w.upper()
        if core in _MINUSCULAS and not primera:
            return w.lower()
        return w[:1].upper() + w[1:].lower()

    out = []
    for i, w in enumerate(nombre.split()):
        out.append("/".join(palabra(p, i == 0 and j == 0) for j, p in enumerate(w.split("/"))))
    return " ".join(out)


def slug(s: str, max_len: int = 40) -> str:
    return norm_text(s).replace("&", "y").replace("/", " ").replace(" ", "-")[:max_len].strip("-")


# Alias de clubes: clave normalizada → nombre canónico.
_CLUB_ALIAS: dict[str, str] = {
    "el bosque": "El Bosque",
    "club de golf el bosque": "El Bosque",
    "la sella": "La Sella Golf",
    "la sella golf": "La Sella Golf",
    "campo la sella": "La Sella Golf",
    "mediterraneo": "Mediterráneo Golf",
    "mediterraneo golf": "Mediterráneo Golf",
    "club de campo mediterraneo": "Mediterráneo Golf",
    "villaitana": "Meliá Villaitana Golf",
    "villaitana golf": "Meliá Villaitana Golf",
    "melia villaitana golf": "Meliá Villaitana Golf",
    "melia villaitana": "Meliá Villaitana Golf",
    "escorpion": "Escorpión",
    "club de golf escorpion": "Escorpión",
    "font del llop": "Font del Llop",
    "club de golf font del llop": "Font del Llop",
    "font de llop golf": "Font del Llop",
    "manises": "RCG Manises",
    "rcg manises": "RCG Manises",
    "real club de golf manises": "RCG Manises",
    "bonalba": "Bonalba",
    "bonalba golf resort": "Bonalba",
    "bonalba golf": "Bonalba",
    "foressos": "Foressos Golf",
    "foressos golf": "Foressos Golf",
    "foressos club de golf": "Foressos Golf",
    "el saler": "El Saler",
    "parador el saler": "El Saler",
    "campo de golf parador el saler": "El Saler",
    "campo de golf el saler": "El Saler",
    "escuela elche": "Escuela de Golf de Elche",
    "escuela de golf de elche": "Escuela de Golf de Elche",
    "escuela de golf elche": "Escuela de Golf de Elche",
    "la marquesa": "La Marquesa",
    "la marquesa golf": "La Marquesa",
    "la galiana": "La Galiana Golf",
    "la galiana golf": "La Galiana Golf",
    "las colinas golf": "Las Colinas Golf & Country Club",
    "las colinas golf & country club": "Las Colinas Golf & Country Club",
    "las colinas": "Las Colinas Golf & Country Club",
    "alicante golf": "Alicante Golf",
    "villamartin": "Villamartín",
    "vistabella": "Vistabella Golf",
    "vistabella golf": "Vistabella Golf",
    "oliva nova": "Oliva Nova",
    "oliva golf": "Oliva Nova",
    "oliva nova golf": "Oliva Nova",
    "el plantio": "El Plantío",
    "club de golf el plantio": "El Plantío",
    "lo romero": "Lo Romero Golf",
    "lo romero golf": "Lo Romero Golf",
    "altea club de golf": "Altea Club de Golf",
    "altea golf": "Altea Club de Golf",
    "alenda": "Alenda Golf",
    "alenda golf": "Alenda Golf",
    "la finca": "La Finca Golf",
    "la finca golf": "La Finca Golf",
    "campo de golf la finca": "La Finca Golf",
    "panoramica": "Panorámica Golf",
    "panoramica golf": "Panorámica Golf",
    "panoramica club": "Panorámica Golf",
    "costa de azahar": "Costa de Azahar",
    "club de golf costa de azahar": "Costa de Azahar",
    "las rejas": "Las Rejas Open Club",
    "el saler golf": "El Saler",
    "golf ifach": "Golf Ifach",
    "club de golf ifach": "Golf Ifach",
    "don cayo": "Golf Don Cayo",
    "club de golf don cayo": "Golf Don Cayo",
    "jávea": "Club de Golf Jávea",
    "javea": "Club de Golf Jávea",
    "club de golf javea": "Club de Golf Jávea",
    "la manga club": "La Manga Club",
    "las pinaillas": "Las Pinaillas",
    "el valle": "El Valle Golf",
    "real club de golf campoamor": "Real Club de Golf Campoamor",
    "campoamor": "Real Club de Golf Campoamor",
    "torre pacheco": "Torre Pacheco",
    "golf gandia": "Club de Golf Gandía",
    "club de golf gandia": "Club de Golf Gandía",
    "gandia": "Club de Golf Gandía",
    "la galiana campo de golf": "La Galiana Golf",
    "masia de las estrellas": "Masía de las Estrellas",
    "golf masia de las estrellas": "Masía de las Estrellas",
    "club de golf las pinaillas": "Las Pinaillas",
    "club de golf oliva nova": "Oliva Nova",
    "escuela de golf de elche fgcv": "Escuela de Golf de Elche",
    "escuela de golf elche fgcv": "Escuela de Golf de Elche",
    "panoramica golf sports & resort": "Panorámica Golf",
    "las rejas benidorm golf": "Las Rejas Benidorm Golf",
    "las rejas benidorm": "Las Rejas Benidorm Golf",
    "las ramblas campo de golf": "Las Ramblas Golf",
    "las ramblas": "Las Ramblas Golf",
    "las ramblas golf": "Las Ramblas Golf",
    "puig campana golf": "Puig Campana Golf",
    "puig campana": "Puig Campana Golf",
    "golf ifach": "Golf Ifach",
    "ifach": "Golf Ifach",
    "el bosque golf": "El Bosque",
    "sella golf": "La Sella Golf",
}

_CLUB_STOPWORDS = re.compile(
    r"\b(club de campo|campo de golf|club de golf|real club de golf|golf resort|golf club|"
    r"golf & country club|country club|sports & resort|c\.?g\.?|resort|golf|fgcv|campo)\b"
)


def _clave_reducida(key: str) -> str:
    key = re.sub(r"\s+", " ", _CLUB_STOPWORDS.sub(" ", key)).strip()
    key = re.sub(r"\b(de|del|la|el)\b(?=\s*(de|del|la|el)\b)", " ", key)  # "de de" → "de"
    key = re.sub(r"^(de|del)\s+", "", key)
    return re.sub(r"\s+", " ", key).strip()


_CLUB_ALIAS_REDUCIDO: dict[str, str] = {}
for _k, _v in _CLUB_ALIAS.items():
    _CLUB_ALIAS_REDUCIDO.setdefault(_clave_reducida(_k), _v)
    _CLUB_ALIAS_REDUCIDO.setdefault(_clave_reducida(norm_text(_v)), _v)


def club_canonico(raw: str | None) -> str:
    """Devuelve el nombre canónico de un club a partir de cualquier variante.

    Tornegolf usa "CAMPO - Recorrido" (p. ej. "VILLAITANA GOLF - Levante"):
    se toma la parte anterior al guion.
    """
    if not raw:
        return ""
    base = raw.replace("­", "").split(" - ")[0].strip()
    key = norm_text(base)
    if key in _CLUB_ALIAS:
        return _CLUB_ALIAS[key]
    key2 = _clave_reducida(key)
    if key2 in _CLUB_ALIAS:
        return _CLUB_ALIAS[key2]
    if key2 in _CLUB_ALIAS_REDUCIDO:
        return _CLUB_ALIAS_REDUCIDO[key2]
    # Sin alias: Title Case del nombre original (respetando siglas de 3 letras o menos).
    words = []
    for w in base.split():
        if w.isupper() and len(w) <= 3 and w.lower() not in _MINUSCULAS and w.lower() not in ("un", "una"):
            words.append(w)
        else:
            words.append(w.capitalize())
    return " ".join(words)


_PROV_ALIAS = {
    "alicante": "Alicante",
    "alacant": "Alicante",
    "valencia": "Valencia",
    "valència": "Valencia",
    "castellon": "Castellón",
    "castello": "Castellón",
}


def provincia_canonica(raw: str | None) -> str | None:
    key = norm_text(raw)
    for k, v in _PROV_ALIAS.items():
        if norm_text(k) == key:
            return v
    return None


def hoy() -> str:
    return date.today().isoformat()


def fecha_corta(iso: str) -> str:
    """'2026-12-19' → '19 dic'."""
    meses = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"]
    y, m, d = iso.split("-")
    return f"{int(d)} {meses[int(m) - 1]}"


def es_tipo_valido(tipo: str) -> bool:
    return tipo in config.TIPOS
