import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../models/torneo.dart';
import 'comunes.dart';

class TorneoCard extends StatelessWidget {
  const TorneoCard({super.key, required this.torneo, this.esNuevo = false, this.compacta = false});
  final Torneo torneo;
  final bool esNuevo;
  final bool compacta;

  @override
  Widget build(BuildContext context) {
    final t = torneo;
    final text = Theme.of(context).textTheme;
    final suave = context.flog.textoSuave;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/torneo/${t.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'fecha-${t.id}',
                child: CajaFecha(fecha: t.inicio, fin: t.esMultidia ? t.fin : null, tamano: compacta ? 56 : 64),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.nombre,
                      style: text.titleMedium?.copyWith(
                        decoration: t.cancelado ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${t.club} · ${t.provincia}${t.modalidad != null && !compacta ? ' · ${t.modalidad}' : ''}',
                      style: text.bodyMedium?.copyWith(color: suave),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TipoBadge(t.tipo),
                        if (esNuevo) const EtiquetaNuevo(),
                        if (t.cambio != null) EtiquetaCambio(t.cambio!),
                        if (t.inscripcionAbierta && t.cambio == null) const EtiquetaInscripcion(),
                        if (t.precio != null && !compacta)
                          Text(t.precio!, style: text.labelMedium?.copyWith(color: suave)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: suave.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}
