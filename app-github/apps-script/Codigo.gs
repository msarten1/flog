/**
 * Golf CV · suscriptores y correo semanal
 * ---------------------------------------
 * Este script vive dentro de una hoja de Google tuya (Extensiones > Apps Script).
 *  - Recibe las altas que la gente hace desde la app y las guarda en la pestaña "Suscriptores".
 *  - Cada lunes a las 10:00 envía desde tu Gmail el resumen de novedades a cada suscriptor.
 *  - Cada correo lleva un enlace personal para darse de baja.
 *
 * Única cosa que tienes que cambiar: APP_URL (la dirección de tu app en GitHub Pages).
 */

const APP_URL = "https://TU-USUARIO.github.io/golf-cv/"; // <-- CAMBIA ESTO (termina en /)

const HOJA_SUSCRIPTORES = "Suscriptores";
const HOJA_ENVIOS = "Envíos";
const PROVINCIAS = ["Alicante", "Valencia", "Castellón"];
const MESES = ["enero","febrero","marzo","abril","mayo","junio","julio","agosto","septiembre","octubre","noviembre","diciembre"];
const DIAS = ["dom","lun","mar","mié","jue","vie","sáb"];

/* ============ 1. CONFIGURACIÓN (ejecútala una vez) ============ */

function configurar() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let hs = ss.getSheetByName(HOJA_SUSCRIPTORES);
  if (!hs) {
    hs = ss.insertSheet(HOJA_SUSCRIPTORES);
    hs.appendRow(["Fecha alta", "Email", "Nombre", "Provincias", "Estado", "Fecha baja"]);
    hs.setFrozenRows(1);
  }
  let he = ss.getSheetByName(HOJA_ENVIOS);
  if (!he) {
    he = ss.insertSheet(HOJA_ENVIOS);
    he.appendRow(["Fecha", "Destinatarios", "Nuevos", "Cambios", "Próximos 14 días", "Notas"]);
    he.setFrozenRows(1);
  }
  const props = PropertiesService.getScriptProperties();
  if (!props.getProperty("SECRETO")) props.setProperty("SECRETO", Utilities.getUuid());

  ScriptApp.getProjectTriggers()
    .filter(t => t.getHandlerFunction() === "enviarResumenSemanal")
    .forEach(t => ScriptApp.deleteTrigger(t));
  ScriptApp.newTrigger("enviarResumenSemanal")
    .timeBased().onWeekDay(ScriptApp.WeekDay.MONDAY).atHour(10).inTimezone("Europe/Madrid").create();

  Logger.log("Listo: hojas creadas y envío programado cada lunes a las 10:00.");
}

/* ============ 2. ALTAS DESDE LA APP ============ */

function doPost(e) {
  try {
    const datos = JSON.parse((e && e.postData && e.postData.contents) || "{}");
    if (datos.accion !== "alta") return texto("ignorado");
    const email = String(datos.email || "").trim().toLowerCase();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || email.length > 120) return texto("email no válido");
    const nombre = String(datos.nombre || "").trim().slice(0, 60);
    let provs = Array.isArray(datos.provincias) ? datos.provincias.filter(p => PROVINCIAS.indexOf(p) >= 0) : [];
    if (!provs.length) provs = PROVINCIAS.slice();

    const lock = LockService.getScriptLock();
    lock.waitLock(10000);
    try {
      const hs = hoja(HOJA_SUSCRIPTORES);
      const fila = buscarFila(hs, email);
      const yaActivo = fila && hs.getRange(fila, 5).getValue() === "activo";
      if (fila) {
        hs.getRange(fila, 3, 1, 4).setValues([[nombre || hs.getRange(fila, 3).getValue(), provs.join(", "), "activo", ""]]);
      } else {
        hs.appendRow([new Date(), email, nombre, provs.join(", "), "activo", ""]);
      }
      if (!yaActivo) enviarConfirmacion(email, nombre, provs);
    } finally {
      lock.releaseLock();
    }
    return texto("ok");
  } catch (err) {
    console.error(err);
    return texto("error");
  }
}

/* ============ 3. BAJAS (enlace del correo) ============ */

function doGet(e) {
  const p = (e && e.parameter) || {};
  if (p.baja && p.t) {
    const email = String(p.baja).toLowerCase();
    if (p.t !== firma(email)) return pagina("Enlace no válido", "Este enlace de baja no es correcto o ha caducado.");
    const hs = hoja(HOJA_SUSCRIPTORES);
    const fila = buscarFila(hs, email);
    if (fila) hs.getRange(fila, 5, 1, 2).setValues([["baja", new Date()]]);
    return pagina("Te has dado de baja", "No recibirás más correos de Golf CV. Si cambias de idea, vuelve a apuntarte desde la app.");
  }
  return pagina("Golf CV", "Servicio de avisos activo.");
}

/* ============ 4. CORREO SEMANAL ============ */

function enviarResumenSemanal() {
  const datos = cargarTorneos();
  const hs = hoja(HOJA_SUSCRIPTORES);
  const filas = hs.getLastRow() > 1 ? hs.getRange(2, 1, hs.getLastRow() - 1, 5).getValues() : [];
  const activos = filas.filter(r => r[4] === "activo" && r[1]);
  let enviados = 0, notas = [];
  const resumenGlobal = construirResumen(datos, PROVINCIAS);

  activos.forEach(r => {
    const email = String(r[1]), nombre = String(r[2] || ""), provs = String(r[3] || "").split(",").map(s => s.trim()).filter(Boolean);
    const res = construirResumen(datos, provs.length ? provs : PROVINCIAS);
    try {
      MailApp.sendEmail({
        to: email,
        subject: "⛳ Golf CV · semana del " + fechaLarga(hoy()) + (res.nuevos.length ? " · " + res.nuevos.length + " nuevo" + (res.nuevos.length === 1 ? "" : "s") : ""),
        htmlBody: htmlResumen(res, datos, nombre, email),
        name: "Golf CV"
      });
      enviados++;
    } catch (err) {
      notas.push(email + ": " + err.message);
    }
  });
  if (MailApp.getRemainingDailyQuota() < 10) notas.push("Cuota diaria de Gmail casi agotada");
  hoja(HOJA_ENVIOS).appendRow([new Date(), enviados, resumenGlobal.nuevos.length, resumenGlobal.cambios.length, resumenGlobal.proximos.length, notas.join(" | ")]);
}

/** Envía el resumen solo a ti, para ver cómo queda. */
function probarEnvio() {
  const yo = Session.getEffectiveUser().getEmail();
  const datos = cargarTorneos();
  const res = construirResumen(datos, PROVINCIAS);
  MailApp.sendEmail({ to: yo, subject: "⛳ Golf CV · PRUEBA", htmlBody: htmlResumen(res, datos, "", yo), name: "Golf CV" });
  Logger.log("Prueba enviada a " + yo);
}

/* ============ utilidades ============ */

function cargarTorneos() {
  const r = UrlFetchApp.fetch(APP_URL + "torneos.json?nocache=" + Date.now(), { muteHttpExceptions: true });
  if (r.getResponseCode() !== 200) throw new Error("No se pudo leer torneos.json (" + r.getResponseCode() + "). Revisa APP_URL.");
  return JSON.parse(r.getContentText());
}

function construirResumen(datos, provs) {
  const h = hoy(), en14 = new Date(h.getTime() + 14 * 864e5), hace7 = new Date(h.getTime() - 7 * 864e5);
  const primera = datos.primera || "";
  const ts = (datos.torneos || [])
    .filter(t => provs.indexOf(t.provincia) >= 0)
    .filter(t => fecha(t.fecha_fin || t.fecha) >= h)
    .sort((a, b) => a.fecha < b.fecha ? -1 : 1);
  return {
    nuevos: ts.filter(t => t.anadido && t.anadido !== primera && fecha(t.anadido) >= hace7),
    cambios: ts.filter(t => t.cambio),
    proximos: ts.filter(t => fecha(t.fecha) <= en14),
    total: ts.length
  };
}

function htmlResumen(res, datos, nombre, email) {
  const verde = "#1f5b3a", gris = "#66706a";
  const fila = t => {
    const d = fecha(t.fecha);
    const fin = t.fecha_fin ? " – " + fechaCorta(fecha(t.fecha_fin)) : "";
    return '<tr><td style="padding:8px 10px 8px 0;vertical-align:top;white-space:nowrap;width:130px;color:' + verde + ';font-weight:600">' +
      DIAS[d.getDay()] + " " + fechaCorta(d) + fin + '</td><td style="padding:8px 0;vertical-align:top">' +
      (t.enlace ? '<a href="' + esc(t.enlace) + '" style="color:#1c2420;font-weight:600;text-decoration:none">' + esc(t.nombre) + "</a>" : "<b>" + esc(t.nombre) + "</b>") +
      (t.cambio ? ' <span style="background:#d4572a;color:#fff;border-radius:8px;padding:1px 6px;font-size:11px">' + esc(t.cambio) + "</span>" : "") +
      '<br><span style="color:' + gris + ';font-size:13px">' + esc(t.club) + " · " + esc(t.provincia) + (t.inscripcion ? " · " + esc(t.inscripcion) : "") + "</span></td></tr>";
  };
  const bloque = (titulo, lista, vacio) =>
    '<h3 style="font-size:15px;margin:22px 0 4px;color:#1c2420">' + titulo + "</h3>" +
    (lista.length ? '<table style="border-collapse:collapse;font-size:14px;width:100%">' + lista.map(fila).join("") + "</table>"
      : '<p style="color:' + gris + ';margin:4px 0;font-size:14px">' + vacio + "</p>");
  const baja = ScriptApp.getService().getUrl() + "?baja=" + encodeURIComponent(email) + "&t=" + firma(email);
  return '<div style="font-family:Arial,Helvetica,sans-serif;max-width:600px;color:#1c2420">' +
    '<div style="background:' + verde + ';color:#fff;padding:16px 18px;border-radius:12px 12px 0 0"><div style="font-size:20px;font-weight:700">⛳ Golf CV</div>' +
    '<div style="opacity:.85;font-size:13px">Torneos amateur de la Comunitat Valenciana · ' + fechaLarga(hoy()) + "</div></div>" +
    '<div style="border:1px solid #e3e2da;border-top:0;padding:4px 18px 18px;border-radius:0 0 12px 12px">' +
    (nombre ? '<p style="margin:16px 0 0">Hola, ' + esc(nombre) + ":</p>" : "") +
    bloque("🆕 Nuevos anunciados esta semana", res.nuevos, "Esta semana no se han anunciado torneos nuevos.") +
    bloque("✏️ Cambios", res.cambios, "Sin cambios.") +
    bloque("📅 Próximos 14 días", res.proximos, "No hay torneos en las próximas dos semanas.") +
    '<p style="margin:22px 0 0"><a href="' + APP_URL + '" style="background:' + verde + ';color:#fff;text-decoration:none;padding:10px 16px;border-radius:8px;font-weight:600;display:inline-block">Ver el calendario completo (' + res.total + " torneos)</a></p>" +
    '<p style="color:' + gris + ';font-size:12px;margin-top:22px">Confirma fecha e inscripción en la ficha del club o de la federación antes de apuntarte. ' +
    '<a href="' + baja + '" style="color:' + gris + '">Darme de baja</a></p></div></div>';
}

function enviarConfirmacion(email, nombre, provs) {
  const baja = ScriptApp.getService().getUrl() + "?baja=" + encodeURIComponent(email) + "&t=" + firma(email);
  MailApp.sendEmail({
    to: email,
    subject: "⛳ Te has apuntado a Golf CV",
    name: "Golf CV",
    htmlBody: '<div style="font-family:Arial,Helvetica,sans-serif;max-width:560px;color:#1c2420">' +
      "<p>" + (nombre ? "Hola, " + esc(nombre) + ":" : "Hola:") + "</p>" +
      "<p>Desde ahora recibirás cada lunes el resumen de torneos de golf amateur de: <b>" + esc(provs.join(", ")) + "</b>.</p>" +
      '<p><a href="' + APP_URL + '" style="color:#1f5b3a;font-weight:600">Abrir la app</a></p>' +
      '<p style="color:#66706a;font-size:12px">¿No has sido tú? <a href="' + baja + '" style="color:#66706a">Darme de baja</a></p></div>'
  });
}

function hoja(n) { const h = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(n); if (!h) throw new Error("Falta la pestaña " + n + ": ejecuta configurar()"); return h; }
function buscarFila(hs, email) {
  if (hs.getLastRow() < 2) return 0;
  const col = hs.getRange(2, 2, hs.getLastRow() - 1, 1).getValues();
  for (let i = 0; i < col.length; i++) if (String(col[i][0]).toLowerCase() === email) return i + 2;
  return 0;
}
function firma(email) {
  const s = PropertiesService.getScriptProperties().getProperty("SECRETO") || "";
  return Utilities.base64EncodeWebSafe(Utilities.computeHmacSha256Signature(email, s)).slice(0, 22);
}
function hoy() { const d = new Date(); d.setHours(0, 0, 0, 0); return d; }
function fecha(s) { const p = String(s).split("-").map(Number); return new Date(p[0], p[1] - 1, p[2]); }
function fechaCorta(d) { return d.getDate() + " " + MESES[d.getMonth()].slice(0, 3); }
function fechaLarga(d) { return d.getDate() + " de " + MESES[d.getMonth()] + " de " + d.getFullYear(); }
function esc(s) { return String(s == null ? "" : s).replace(/[&<>"]/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c])); }
function texto(s) { return ContentService.createTextOutput(s).setMimeType(ContentService.MimeType.TEXT); }
function pagina(t, m) {
  return HtmlService.createHtmlOutput('<div style="font-family:Arial,sans-serif;max-width:480px;margin:40px auto;padding:0 16px"><h2 style="color:#1f5b3a">⛳ ' + esc(t) + "</h2><p>" + esc(m) + "</p></div>")
    .setTitle("Golf CV").addMetaTag("viewport", "width=device-width, initial-scale=1");
}
