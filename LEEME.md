# Proyecto Golf CV · paquete para continuar en otro PC

Exportado el 14/11/2026.

## Qué hay en esta carpeta

| Carpeta / archivo | Contenido |
|---|---|
| `app-github/` | La app web instalable que está publicada en **https://ivanchaconcampos123-tech.github.io/golf-cv/** (repositorio `ivanchaconcampos123-tech/golf-cv`). Incluye `GUIA.md`, la guía de puesta en marcha, y `apps-script/Codigo.gs`, el script de Google para los suscriptores y el correo semanal. |
| `app-github/torneos.json` | Los **datos más recientes**: la versión que actualizó la tarea del lunes 9/11, con 42 torneos. Es más nueva que la que subiste a GitHub, que tiene 37. Puedes subirla al repositorio para sustituir la antigua. |
| `calendario-claude/` | El primer calendario, que sigue publicado en Claude (https://claude.ai/artifact/19q46HLNMG62cgjheoKUoP) y es el que actualiza la tarea semanal por ahora. |
| `tarea-programada/` | La configuración y el prompt literal de la tarea de los lunes, más los cambios pendientes para pasarla a GitHub. |
| `conversacion.md` | El registro de la conversación: tus mensajes, mis respuestas, las decisiones tomadas y el estado de cada cosa. |

**Importante:** tu `config.js` de GitHub puede llevar ya tu URL `/exec` de Google. La copia de este paquete la tiene vacía. Si vuelves a subir archivos, no sobrescribas el `config.js` del repositorio.

## Estado actual

- ✅ App publicada en GitHub Pages; carga correctamente.
- ✅ Tarea semanal de Claude activa. Funcionó el lunes 9/11 y la próxima es el lunes 16/11 a las 07:52.
- ⏳ **Google Apps Script** (hoja de suscriptores, URL `/exec` en `config.js`, `probarEnvio`): no sé si está terminado. Sigue los pasos 2 a 4 de `app-github/GUIA.md`.
- ⏳ **Conectar GitHub a Claude** (Configuración → Conectores → GitHub, con acceso de escritura a `golf-cv`). Después hay que pedirle a Claude que cambie la tarea semanal para que escriba `torneos.json` en el repositorio. Los detalles están en `tarea-programada/prompt-tarea-semanal.md`.

## Cómo seguir en una conversación nueva con Claude

Adjunta este zip y escribe algo así: *«Continúo el proyecto Golf CV. Lee LEEME.md y conversacion.md. Ya he vinculado GitHub; conecta el repositorio ivanchaconcampos123-tech/golf-cv y cambia la tarea semanal (ID trig_01RKaE5B9F1tYr44RzsUyaAv) para que actualice torneos.json en el repositorio.»*
