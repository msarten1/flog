# Golf CV · Guía de puesta en marcha

Hazlo desde un ordenador. Se tarda unos 20 minutos y solo hay que hacerlo una vez.

**Qué contiene la carpeta**

| Archivo | Para qué sirve |
|---|---|
| `index.html`, `manifest.webmanifest`, `sw.js`, `icons/` | La app: lista de torneos, calendario mensual y pestaña de avisos. Se puede instalar y funciona sin conexión. |
| `torneos.json` | Los datos de los torneos. Claude lo actualiza cada lunes. |
| `config.js` | La dirección del servicio de avisos (la rellenas en el paso 4). |
| `apps-script/Codigo.gs` | El script que guarda los suscriptores y envía el correo semanal desde tu Gmail. |

---

## 1. Publicar la app en GitHub (gratis)

1. Crea una cuenta en **github.com** (botón *Sign up*) si todavía no la tienes.
2. Arriba a la derecha pulsa **+ → New repository**.
   - *Repository name*: `golf-cv`
   - Marca **Public**.
   - Pulsa **Create repository**.
3. En la página del repositorio nuevo pulsa **uploading an existing file**.
4. Arrastra **todo el contenido** de la carpeta descomprimida, incluidas las carpetas `icons` y `apps-script`. No arrastres la carpeta entera, sino lo que hay dentro.
5. Abajo pulsa **Commit changes**.
6. Ve a **Settings → Pages**.
   - En *Source* elige **Deploy from a branch**.
   - En *Branch* elige **main** y **/(root)**.
   - Pulsa **Save**.
7. Espera 1 o 2 minutos y recarga la página. Arriba aparecerá la dirección de tu app, por ejemplo `https://tu-usuario.github.io/golf-cv/`. **Apúntala.**

## 2. Crear la hoja de suscriptores y el envío de correos (con tu Gmail)

1. Con tu cuenta de Gmail, abre **sheets.new**. Se crea una hoja nueva; ponle de nombre *Golf CV – suscriptores*.
2. Menú **Extensiones → Apps Script**.
3. Borra lo que aparece y pega todo el contenido de `apps-script/Codigo.gs`.
4. En la línea `const APP_URL = "https://TU-USUARIO.github.io/golf-cv/";` pon la dirección del paso 1.7, terminada en `/`.
5. Pulsa el icono del disquete (Guardar).
6. Arriba, en el desplegable de funciones, elige **configurar** y pulsa **Ejecutar**.
   - Google pedirá permisos. Pulsa *Revisar permisos*, elige tu cuenta y luego *Configuración avanzada → Ir a … (no seguro)*. Sale este aviso porque es un script tuyo y Google no lo ha revisado. Acepta.
   - Esto crea las pestañas *Suscriptores* y *Envíos* y programa el envío para **cada lunes a las 10:00**.
7. Elige la función **probarEnvio** y pulsa **Ejecutar**. Te llegará un correo de prueba con el resumen actual.

## 3. Activar las altas desde la app

1. En Apps Script pulsa **Implementar → Nueva implementación**.
2. En el engranaje de *Seleccionar tipo* elige **Aplicación web**.
   - *Ejecutar como*: **Yo**.
   - *Quién tiene acceso*: **Cualquier usuario**.
3. Pulsa **Implementar** y **copia la URL** que termina en `/exec`.

## 4. Conectar la app con el servicio de avisos

1. En GitHub, abre tu repositorio, entra en `config.js` y pulsa el lápiz (*Edit*).
2. Pega la URL `/exec` entre las comillas de `SUSCRIPCION_URL: ""`.
3. Pulsa **Commit changes**. En un minuto la app estará actualizada.
4. Prueba a apuntarte desde la pestaña **Avisos**. Te llegará un correo de confirmación y verás tu dirección en la hoja *Suscriptores*.

## 5. Instalarla en el móvil y compartirla

- **Android (Chrome):** abre la dirección de la app y pulsa **Instalar**, o *menú ⋮ → Instalar aplicación*.
- **iPhone (Safari):** abre la dirección y pulsa **Compartir → Añadir a pantalla de inicio**.
- Para compartirla, manda la dirección a tus compañeros. Cada uno la instala y se apunta en *Avisos*.

## 6. Actualización semanal de los torneos

Dile a Claude tu **usuario de GitHub**. Claude conectará el repositorio a la revisión de los lunes y escribirá allí `torneos.json` cada semana. El correo de las 10:00 sale ya con los datos nuevos.

---

### Bueno saber

- **Bajas:** cada correo lleva un enlace personal *Darme de baja*. También puedes borrar o cambiar filas directamente en la hoja.
- **Límite de Gmail:** una cuenta gratuita puede enviar unos 100 correos al día, de sobra para un grupo de amigos.
- **Historial:** la pestaña *Envíos* registra cada lunes cuántos correos salieron y si hubo algún error.
- **Si cambias el código de Apps Script**, vuelve a publicarlo en *Implementar → Gestionar implementaciones → editar → Versión nueva*. Así la URL `/exec` sigue siendo la misma.
