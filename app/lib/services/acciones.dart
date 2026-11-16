import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/dates.dart';
import '../models/torneo.dart';

/// Acciones sobre un torneo: abrir ficha, añadir al calendario, compartir.
class Acciones {
  Acciones._();

  static Future<void> abrirEnlace(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el enlace')));
    }
  }

  static Future<void> anadirAlCalendario(BuildContext context, Torneo t) async {
    final detalles = [
      if (t.modalidad != null) 'Modalidad: ${t.modalidad}',
      if (t.inscripcion != null) t.inscripcion!,
      if (t.precio != null) 'Precio: ${t.precio}',
      if (t.enlacePrincipal != null) t.enlacePrincipal!,
      'Añadido desde Flog',
    ].join('\n');
    final event = Event(
      title: t.nombre,
      description: detalles,
      location: '${t.club} (${t.provincia})',
      startDate: t.inicio,
      endDate: t.fin.add(const Duration(days: 1)),
      allDay: true,
    );
    final ok = await Add2Calendar.addEvent2Cal(event);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el calendario')));
    }
  }

  static Future<void> compartir(Torneo t) async {
    final texto = [
      '⛳ ${t.nombre}',
      '${Fechas.larga(t.inicio)}${t.esMultidia ? ' – ${Fechas.larga(t.fin)}' : ''}',
      '${t.club} · ${t.provincia}',
      if (t.modalidad != null) t.modalidad!,
      if (t.enlacePrincipal != null) t.enlacePrincipal!,
      '',
      'Vía Flog, el calendario de torneos de golf amateur de la Comunitat Valenciana',
    ].join('\n');
    await SharePlus.instance.share(ShareParams(text: texto, subject: t.nombre));
  }
}
