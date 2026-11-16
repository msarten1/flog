# Tarea programada de Claude: «Calendario golf amateur CV – revisión semanal»

- **ID:** trig_01RKaE5B9F1tYr44RzsUyaAv
- **Cuándo:** cada lunes a las 07:52 (hora de Madrid). Cron: `CRON_TZ=Europe/Madrid 52 7 * * 1`
- **Aviso:** por correo, al email de la cuenta de Claude.
- **Estado (14/11/2026):** activa. La ejecución del lunes 9/11 terminó bien y la próxima es el lunes 16/11.
- **Qué actualiza ahora:** el `torneos.json` del calendario antiguo en Claude (https://claude.ai/artifact/19q46HLNMG62cgjheoKUoP). Todavía no escribe en GitHub.

## Pendiente
Pasar la tarea a GitHub. Para eso:
1. Vincular la cuenta de GitHub en claude.ai, en **Configuración → Conectores → GitHub**, y dar acceso con escritura al repositorio `ivanchaconcampos123-tech/golf-cv`.
2. Cambiar los pasos 1 y 5 del prompt: en lugar de leer y publicar el artifact, la tarea clona el repositorio, edita `torneos.json`, hace commit y push a `main`. GitHub Pages lo publica solo.
3. Cambiar el enlace del resumen a https://ivanchaconcampos123-tech.github.io/golf-cv/.
4. Quitar el aviso por correo de la tarea, porque el correo ya lo envía el Apps Script, para que no llegue duplicado.

## Prompt actual (literal)

```
Eres el encargado de mantener el calendario de torneos de golf AMATEUR de la Comunitat Valenciana (provincias de Alicante, Valencia y Castellón) para Iván, golfista amateur que vive en Monóvar (Alicante). Escribe todo en español.

CALENDARIO: es un artifact publicado con slug 013b9065-e42c-4365-a038-181a661ca11e (https://claude.ai/artifact/19q46HLNMG62cgjheoKUoP). Tiene dos archivos: index.html (la página; NO la modifiques) y torneos.json (los datos). Solo actualizas torneos.json.

PASOS
1. Con las herramientas mcp__claude-artifacts__ (cárgalas con ToolSearch si están diferidas): list_files del artifact y read_file de torneos.json. Guarda una copia del JSON actual en el directorio de trabajo.
2. Investiga con WebSearch/WebFetch los torneos de las próximas 10-12 semanas y los anuncios nuevos. Fuentes principales:
   - https://www.tornegolf.com/torneos/provincia/alicante y https://www.tornegolf.com/torneos/provincia/valencia (agregador; la mejor fuente)
   - https://golfcv.com/ y https://golfcv.com/category/actualidad/ (Federación de Golf de la CV: campeonatos, circuitos, plazos de inscripción)
   - https://mediterraneo.golf/en/calendar/ y búsquedas para Castellón (Panorámica, Costa de Azahar, Mediterráneo)
   - Webs de clubes: La Sella, Oliva Nova, Font del Llop, Alicante Golf, El Plantío, Bonalba, Villaitana, Las Colinas, La Marquesa, El Saler, El Bosque, Escorpión, RCG Manises, Foressos
   - AESGOLF (sénior) y Asociación de Campos de Golf de la Costa Blanca (circuito IPT)
3. Criterios: incluir campeonatos y circuitos federativos amateur, torneos abiertos de club, circuitos amateur (Locos por el Golf, Yoingolf, Mediterráneo, etc.) y pruebas nacionales RFEG amateur que se jueguen en la CV. EXCLUIR: profesionales (salvo pro-am), juveniles/infantiles/benjamines, y competiciones semanales de sociedades o socios (Golf Holanda, Teigur Golf Society, Monday/Tuesday/Sunday Competition, Tuesday Duel, SAS, ligas internas, "Wednesday afternoon", etc.). Evita duplicados (mismo torneo, fecha y club).
4. Actualiza torneos.json manteniendo exactamente la estructura actual:
   - "actualizado": fecha de hoy (AAAA-MM-DD). No cambies "primera".
   - Torneos nuevos: añádelos con un "id" único y estable, "anadido" = fecha de hoy, y rellena fecha, fecha_fin (si dura varios días), nombre, club, provincia, tipo ("Federación", "Club", "Circuito" o "Nacional en la CV"), modalidad, inscripcion (plazo, precio o requisitos si aparecen) y enlace (la URL real que hayas visto).
   - Cambios en torneos existentes (fecha, sede, cancelación, nuevo plazo de inscripción): actualiza el registro y pon "cambio" con un texto breve, p. ej. "Cambio de fecha" o "Cancelado". Quita el "cambio" de la semana anterior si ya no aplica.
   - Borra los torneos que terminaron hace más de 14 días.
   - No inventes nada: si no lo has visto en una fuente, no lo pongas.
5. Valida que el JSON parsea (python3 -c "import json;json.load(open('torneos.json'))") y publícalo con mcp__claude-artifacts__publish_files en modo "patch", con slug 013b9065-e42c-4365-a038-181a661ca11e, base_version = la versión que te dio list_files, y files = [{"as":"torneos.json","path":"<ruta absoluta de tu archivo>"}]. No envíes index.html. Si hay conflicto de versión, vuelve a listar y reintenta.
6. Tu respuesta final es el resumen que le llegará a Iván por correo. Escríbelo SIEMPRE, aunque no haya novedades, con este formato breve:
   - Asunto/primera línea: "Golf CV – semana del <fecha>"
   - "Nuevos anunciados esta semana": lista (fecha · torneo · club) o "ninguno".
   - "Cambios": lista o "ninguno".
   - "Próximos 14 días": lista de los torneos.
   - "Inscripciones que cierran pronto": las que tengan plazo en los próximos 10 días, si las conoces.
   - Enlace al calendario: https://claude.ai/artifact/19q46HLNMG62cgjheoKUoP
   Breve y fácil de leer en el móvil. No pidas confirmación ni hagas preguntas: nadie responderá.
```
