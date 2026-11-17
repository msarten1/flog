import 'dart:convert';

import '../state/perfil_state.dart';

/// Genera el script que rellena formularios de inscripción con los datos del
/// perfil. Solo toca campos vacíos y nunca contraseñas. Se reinyecta cuando la
/// página cambia (las webs de golfdirecto o de los clubes pintan el formulario
/// con JavaScript después de cargar).
class AutofillJs {
  AutofillJs._();

  /// Nombre del canal JavaScript → Dart por el que la página avisa de qué rellenó.
  static const canal = 'FlogAutofill';

  static Map<String, String> datos(Perfil p) {
    final partes = p.nombre.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    final nombre = partes.isEmpty ? '' : partes.first;
    final apellidos = partes.length > 1 ? partes.sublist(1).join(' ') : '';
    return {
      'licencia': p.licencia.trim(),
      'email': p.email.trim(),
      'nombreCompleto': p.nombre.trim(),
      'nombre': nombre,
      'apellidos': apellidos,
      'club': p.club.trim(),
      'handicap': p.handicap?.toStringAsFixed(1) ?? '',
    };
  }

  static String script(Perfil p) {
    final d = jsonEncode(datos(p));
    return '''
(function(){
  if (window.__flogAutofillInstalled) { window.__flogAutofill && window.__flogAutofill(); return; }
  window.__flogAutofillInstalled = true;
  var D = $d;
  var reglas = [
    ['licencia', /licen|license|federad|n[uú]m(ero)?\\s*fed/i],
    ['email', /e-?mail|correo/i],
    ['apellidos', /apellid|surname|last\\s*-?name|lastname|cognom/i],
    ['nombre', /^(nombre|name|first\\s*-?name|firstname|nom)\$|\\bnombre\\b|first/i],
    ['club', /\\bclub\\b/i],
    ['handicap', /h[aá]ndicap|\\bhcp\\b/i]
  ];
  function texto(el){
    var t = [el.name, el.id, el.placeholder, el.getAttribute('aria-label'), el.getAttribute('autocomplete')].join(' ');
    if (el.id) { var l = document.querySelector('label[for="' + el.id + '"]'); if (l) t += ' ' + l.textContent; }
    var p = el.closest('label'); if (p) t += ' ' + p.textContent;
    return t;
  }
  function visible(el){ var r = el.getBoundingClientRect(); return r.width > 0 && r.height > 0; }
  function rellenar(){
    var hechos = [];
    var campos = document.querySelectorAll('input, textarea');
    for (var i = 0; i < campos.length; i++) {
      var el = campos[i];
      var tipo = (el.type || 'text').toLowerCase();
      if (['password','hidden','checkbox','radio','submit','button','file','date'].indexOf(tipo) >= 0) continue;
      if (el.value || el.readOnly || el.disabled || !visible(el) || el.dataset.flogDone) continue;
      var t = texto(el);
      if (tipo === 'email' && D.email) { poner(el, D.email); hechos.push('email'); continue; }
      for (var r = 0; r < reglas.length; r++) {
        var clave = reglas[r][0], re = reglas[r][1];
        if (!D[clave]) continue;
        if (re.test(t)) {
          // "nombre" completo cuando no hay campo de apellidos aparte
          var valor = D[clave];
          if (clave === 'nombre' && D.apellidos && !hayCampoApellidos()) valor = D.nombreCompleto;
          poner(el, valor); hechos.push(clave); break;
        }
      }
    }
    if (hechos.length && window.$canal) { window.$canal.postMessage(hechos.join(',')); }
  }
  function hayCampoApellidos(){
    var campos = document.querySelectorAll('input');
    for (var i = 0; i < campos.length; i++) if (/apellid|surname|last\\s*-?name|lastname/i.test(texto(campos[i]))) return true;
    return false;
  }
  function poner(el, valor){
    var setter = Object.getOwnPropertyDescriptor(el.__proto__, 'value') || Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value');
    if (setter && setter.set) setter.set.call(el, valor); else el.value = valor;
    el.dataset.flogDone = '1';
    el.dispatchEvent(new Event('input', {bubbles: true}));
    el.dispatchEvent(new Event('change', {bubbles: true}));
  }
  window.__flogAutofill = rellenar;
  rellenar();
  var pendiente = null;
  new MutationObserver(function(){ clearTimeout(pendiente); pendiente = setTimeout(rellenar, 400); })
    .observe(document.documentElement, {childList: true, subtree: true});
})();
''';
  }
}
