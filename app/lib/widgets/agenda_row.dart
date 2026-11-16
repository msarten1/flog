import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/dates.dart';
import '../core/theme.dart';
import '../models/torneo.dart';

/// Fila de agenda: fecha a la izquierda, torneo a la derecha. Sin tarjeta.
class AgendaRow extends StatelessWidget {
  const AgendaRow({
    super.key,
    required this.torneo,
    this.esNuevo = false,
    this.inscrito = false,
    this.mostrarFecha = true,
  });

  final Torneo torneo;
  final bool esNuevo;
  final bool inscrito;
  final bool mostrarFecha;

  @override
  Widget build(BuildContext context) {
    final t = torneo;
    final text = Theme.of(context).textTheme;
    final tokens = context.flog;
    final color = FlogColors.tipo(t.tipo);
    final hoy = Fechas.hoy();
    final esHoy = Fechas.mismoDia(t.inicio, hoy);

    return InkWell(
      onTap: () => context.push('/torneo/${t.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 48,
              child: mostrarFecha
                  ? Column(
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
                          ),
                        ),
                        if (t.esMultidia)
                          Text('–${t.fin.day}', style: text.labelSmall?.copyWith(color: tokens.textoSuave)),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            Container(
              width: 3,
              height: 44,
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (inscrito)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2),
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
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 10,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        t.tipo == 'Nacional en la CV' ? 'Nacional' : t.tipo,
                        style: text.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
                      ),
                      if (t.modalidad != null)
                        Text(t.modalidad!, style: text.labelSmall?.copyWith(color: tokens.textoSuave)),
                      if (t.precio != null)
                        Text(t.precio!, style: text.labelSmall?.copyWith(color: tokens.textoSuave)),
                      if (esNuevo)
                        Text('Nuevo', style: text.labelSmall?.copyWith(color: FlogColors.limaOscuro, fontWeight: FontWeight.w700)),
                      if (t.inscripcionAbierta && t.cambio == null)
                        Text('Inscripción abierta', style: text.labelSmall?.copyWith(color: FlogColors.verde700, fontWeight: FontWeight.w600)),
                      if (t.cambio != null)
                        Text(t.cambio!, style: text.labelSmall?.copyWith(color: FlogColors.aviso, fontWeight: FontWeight.w700)),
                    ],
                  ),
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
  const CabeceraAgenda(this.texto, {super.key, this.detalle});
  final String texto;
  final String? detalle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tokens = context.flog;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 6),
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
        ],
      ),
    );
  }
}
