import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/dates.dart';
import '../core/theme.dart';
import '../models/torneo.dart';

/// Fila de agenda: fecha a la izquierda, torneo a la derecha. Sin tarjeta.
///
/// Normal: nombre · "club · provincia" · una etiqueta de estado.
/// Compacta: nombre y "club · provincia" en una línea cada uno, sin estado.
class AgendaRow extends StatelessWidget {
  const AgendaRow({
    super.key,
    required this.torneo,
    this.esNuevo = false,
    this.inscrito = false,
    this.mostrarFecha = true,
    this.compacta = false,
    this.cierre,
  });

  final Torneo torneo;
  final bool esNuevo;
  final bool inscrito;
  final bool mostrarFecha;
  final bool compacta;

  /// Fecha de cierre de inscripción (AAAA-MM-DD) para mostrar "cierra el …".
  final String? cierre;

  @override
  Widget build(BuildContext context) {
    final t = torneo;
    final text = Theme.of(context).textTheme;
    final tokens = context.flog;
    final color = FlogColors.tipo(t.tipo);
    final esHoy = Fechas.mismoDia(t.inicio, Fechas.hoy());

    // Una sola etiqueta de estado, por prioridad.
    String? estado;
    Color? estadoColor;
    if (t.cambio != null) {
      estado = t.cambio;
      estadoColor = FlogColors.aviso;
    } else if (cierre != null) {
      estado = 'Inscripción hasta el ${Fechas.corta(Fechas.parse(cierre!))}';
      estadoColor = FlogColors.dorado;
    } else if (inscrito) {
      estado = 'Inscrito';
      estadoColor = FlogColors.verde500;
    } else if (esNuevo) {
      estado = 'Nuevo';
      estadoColor = FlogColors.limaOscuro;
    } else if (t.inscripcionAbierta) {
      estado = 'Inscripción abierta';
      estadoColor = FlogColors.verde700;
    }

    return InkWell(
      onTap: () => context.push('/torneo/${t.id}'),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: compacta ? 9 : 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (mostrarFecha)
              SizedBox(
                width: 48,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Fechas.diaSemana(t.inicio),
                      style: text.labelSmall?.copyWith(
                        color: esHoy ? FlogColors.verde700 : tokens.textoSuave,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      '${t.inicio.day}',
                      style: text.headlineSmall?.copyWith(
                        color: esHoy ? FlogColors.verde700 : tokens.texto,
                        height: 1.05,
                        fontSize: compacta ? 20 : 24,
                      ),
                    ),
                    if (t.esMultidia && !compacta)
                      Text('–${t.fin.day}', style: text.labelSmall?.copyWith(color: tokens.textoSuave)),
                  ],
                ),
              ),
            Container(
              width: 3,
              height: compacta ? 36 : 42,
              margin: const EdgeInsets.only(right: 12, top: 2),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          t.nombre,
                          style: text.titleMedium?.copyWith(
                            decoration: t.cancelado ? TextDecoration.lineThrough : null,
                            height: 1.25,
                          ),
                          maxLines: compacta ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (inscrito)
                        const Padding(
                          padding: EdgeInsets.only(left: 8, top: 2),
                          child: Icon(Icons.check_circle, size: 18, color: FlogColors.verde500),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${t.club} · ${t.provincia}',
                    style: text.bodyMedium?.copyWith(color: tokens.textoSuave),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!compacta && estado != null) ...[
                    const SizedBox(height: 3),
                    Text(estado, style: text.labelSmall?.copyWith(color: estadoColor, fontWeight: FontWeight.w700)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cabecera de sección en mayúsculas pequeñas ("ESTA SEMANA").
class CabeceraAgenda extends StatelessWidget {
  const CabeceraAgenda(this.texto, {super.key, this.detalle, this.accion});
  final String texto;
  final String? detalle;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tokens = context.flog;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 12, 6),
      child: Row(
        children: [
          Text(
            texto.toUpperCase(),
            style: text.labelMedium?.copyWith(color: FlogColors.verde700, fontWeight: FontWeight.w800, letterSpacing: 1.1),
          ),
          if (detalle != null) ...[
            const SizedBox(width: 8),
            Text(detalle!, style: text.labelMedium?.copyWith(color: tokens.textoSuave)),
          ],
          const Spacer(),
          ?accion,
        ],
      ),
    );
  }
}
