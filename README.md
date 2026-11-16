# Flog · torneos de golf amateur de la Comunitat Valenciana

Flog es una app móvil (Flutter) con el calendario de torneos de golf amateur de
Alicante, Valencia y Castellón, y avisos push cuando se anuncian torneos nuevos.
Los datos los mantiene un scraper propio que se ejecuta cada lunes en GitHub Actions.

```
data/        torneos.json (lo que consume la app) · changes.json (novedades de la última ejecución)
             clasificaciones.json (decisiones del clasificador; editable a mano)
scraper/     paquete Python flog_scraper (fuentes, reglas, clasificador, dedupe, push)
app/         proyecto Flutter
branding/    logo e icono
.github/     workflows: scraper (lunes 06:00 UTC), ci (tests)
```

## Fuentes

| Fuente | Qué aporta | Cómo se lee |
|---|---|---|
| [Tornegolf](https://www.tornegolf.com/torneos/provincia/alicante) | Torneos de club y circuitos (agrega golfdirecto, radargolf, RFEG y FGCV) | JSON incrustado en la página de cada provincia |
| [Federación de Golf de la CV](https://golfcv.com/torneo_seek/) | Competiciones federativas con plazo de inscripción y precio | Endpoint JSON `wp-json/bt_ws/v1/torneos_lt` |
| [Mediterráneo Golf](https://mediterraneo.golf/en/calendar/) | Calendario del club (Castellón) | Microdatos schema.org |

Criterio: se incluyen campeonatos y circuitos federativos amateur, torneos abiertos
de club, circuitos amateur y pruebas nacionales RFEG en la CV. Se excluyen
profesionales (salvo pro-am), juveniles y competiciones internas de sociedades o
socios. Lo que las reglas no resuelven se clasifica con la API de OpenAI y queda
cacheado en `data/clasificaciones.json` (si quieres forzar una decisión, edita ahí).

## Scraper

```bash
cd scraper
python3 -m venv .venv && .venv/bin/pip install -e ".[dev]"
.venv/bin/pytest                                   # tests con fixtures guardadas
.venv/bin/python -m flog_scraper run --dry-run     # muestra novedades sin escribir
.venv/bin/python -m flog_scraper run               # escribe data/torneos.json y data/changes.json
.venv/bin/python -m flog_scraper notify --dry-run  # qué notificaciones se enviarían
.venv/bin/python -m flog_scraper notify --test     # notificación de prueba al tema "todos"
```

Variables de entorno:

- `OPENAI_API_KEY`: clasificador de torneos dudosos (sin ella se marcan `revisar: true`).
- `FCM_SERVICE_ACCOUNT_JSON` o `FCM_SERVICE_ACCOUNT_FILE`: cuenta de servicio de Firebase para las notificaciones.
- `FLOG_REQUEST_DELAY`: pausa entre peticiones (1 s por defecto).

En GitHub, los secretos se cargan con `gh secret set OPENAI_API_KEY` y
`gh secret set FCM_SERVICE_ACCOUNT_JSON < service-account.json`.

## App

Flutter (Android primero; iOS cuando haya Xcode). Tres pestañas: **Torneos** (lista por
meses con buscador y filtros de provincia y tipo), **Calendario** (vista mensual con puntos
por tipo) y **Avisos** (provincias para recibir push y novedades de la última revisión).
Cada torneo tiene ficha con enlace de inscripción, "Añadir a mi calendario" y compartir.

```bash
cd app
flutter pub get && flutter analyze && flutter test
flutter run                        # emulador o móvil
flutter build apk --release        # build/app/outputs/flutter-apk/app-release.apk
```

Detalles (Firebase, icono, firma del APK) en `app/README.md`.

## Esquema de `data/torneos.json`

```json
{
 "actualizado": "2026-11-16",
 "primera": "2026-11-08",
 "torneos": [
  {
   "id": "golfcv-2731",
   "fecha": "2026-11-27", "fecha_fin": "2026-11-29",
   "nombre": "Cto Absoluto de la CV",
   "club": "Font del Llop", "provincia": "Alicante",
   "tipo": "Federación",
   "modalidad": "Individual · Stroke Play",
   "inscripcion": "Inscripción del 23 oct al 23 nov", "precio": "100 €", "estado_inscripcion": "cerrada",
   "enlace": "https://golfcv.com/torneo_seek/ver-torneo/?torneoid=2731",
   "enlace_inscripcion": "https://www.tornegolf.com/torneos/...",
   "fuente": "golfcv",
   "anadido": "2026-11-08",
   "cambio": "Cambio de fecha (antes 26 nov)"
  }
 ]
}
```

`tipo` ∈ Federación · Club · Circuito · Nacional en la CV. `cambio`, `revisar` y
`sin_fuente_desde` solo aparecen cuando aplican.

## Pendiente de la etapa anterior

La primera versión vivía en la cuenta de Claude de Iván: una PWA en GitHub Pages
(`ivanchaconcampos123-tech/golf-cv`) y una tarea programada semanal
(`trig_01RKaE5B9F1tYr44RzsUyaAv`). Cuando el scraper esté en marcha hay que
desactivar ambas desde esa cuenta. Todo ese material está en el primer commit
de este repositorio.
