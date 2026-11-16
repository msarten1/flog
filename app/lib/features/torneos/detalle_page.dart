import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/dates.dart';
import '../../core/theme.dart';
import '../../models/torneo.dart';
import '../../services/acciones.dart';
import '../../state/torneos_state.dart';
import '../../widgets/comunes.dart';

class DetallePage extends StatelessWidget {
  const DetallePage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<TorneosState>();
    final t = s.porId(id);
    if (t == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EstadoVacio(
          titulo: 'Torneo no encontrado',
          texto: 'Puede que ya no esté en el calendario.',
          icono: Icons.search_off,
        ),
      );
    }
    return _Detalle(t: t, esNuevo: s.esNuevo(t));
  }
}

class _Detalle extends StatelessWidget {
  const _Detalle({required this.t, required this.esNuevo});
  final Torneo t;
  final bool esNuevo;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final suave = context.flog.textoSuave;
    final enlace = t.enlacePrincipal;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            backgroundColor: FlogColors.verde900,
            actions: [
              IconButton(
                tooltip: 'Compartir',
                icon: const Icon(Icons.ios_share),
                onPressed: () => Acciones.compartir(t),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF15523D), FlogColors.verde900],
                  ),
                ),
                padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 56, 20, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Hero(
                      tag: 'fecha-${t.id}',
                      child: CajaFecha(fecha: t.inicio, fin: t.esMultidia ? t.fin : null, claro: true, tamano: 72),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              TipoBadge(t.tipo, enVerde: true),
                              if (esNuevo) const EtiquetaNuevo(),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t.nombre,
                            style: text.headlineSmall?.copyWith(color: Colors.white),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverList.list(
              children: [
                if (t.cambio != null) ...[
                  _Aviso(texto: t.cambio!),
                  const SizedBox(height: 12),
                ],
                _Bloque(
                  titulo: 'Cuándo y dónde',
                  filas: [
                    _Fila(Icons.event, t.esMultidia ? 'Del ${Fechas.larga(t.inicio)} al ${Fechas.larga(t.fin)}' : Fechas.larga(t.inicio), sub: Fechas.relativo(t.inicio)),
                    _Fila(Icons.golf_course, t.club, sub: t.provincia),
                    if (t.modalidad != null) _Fila(Icons.sports_golf, t.modalidad!),
                  ],
                ),
                const SizedBox(height: 12),
                _Bloque(
                  titulo: 'Inscripción',
                  filas: [
                    if (t.estadoInscripcion != null)
                      _Fila(
                        t.inscripcionAbierta ? Icons.how_to_reg : Icons.lock_clock,
                        t.inscripcionAbierta ? 'Inscripción abierta' : 'Inscripción cerrada o no publicada',
                        color: t.inscripcionAbierta ? FlogColors.verde700 : null,
                      ),
                    if (t.inscripcion != null) _Fila(Icons.calendar_today_outlined, t.inscripcion!),
                    if (t.precio != null) _Fila(Icons.euro, t.precio!),
                    if (t.estadoInscripcion == null && t.inscripcion == null && t.precio == null)
                      _Fila(Icons.info_outline, 'Consulta la ficha del torneo para inscribirte.'),
                  ],
                ),
                const SizedBox(height: 20),
                if (enlace != null)
                  FilledButton.icon(
                    onPressed: () => Acciones.abrirEnlace(context, enlace),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Ver ficha e inscripción'),
                  ),
                if (enlace != null) const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Acciones.anadirAlCalendario(context, t),
                  icon: const Icon(Icons.event_available_outlined),
                  label: const Text('Añadir a mi calendario'),
                ),
                if (t.enlace != null && t.enlaceInscripcion != null && t.enlace != t.enlaceInscripcion) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Acciones.abrirEnlace(context, t.enlace),
                    child: const Text('Ver también en la fuente original'),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Fuente: ${_fuente(t.fuente)}${t.anadido != null ? ' · en Flog desde el ${Fechas.corta(Fechas.parse(t.anadido!))}' : ''}',
                  style: text.labelMedium?.copyWith(color: suave, fontWeight: FontWeight.w500),
                ),
                if (t.revisar)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Pendiente de confirmar que sea un torneo abierto.',
                      style: text.labelMedium?.copyWith(color: FlogColors.dorado, fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fuente(String? f) {
    switch (f) {
      case 'golfcv':
        return 'Federación de Golf de la CV';
      case 'tornegolf':
        return 'Tornegolf';
      case 'mediterraneo':
        return 'Mediterráneo Golf';
      default:
        return 'web del club';
    }
  }
}

class _Bloque extends StatelessWidget {
  const _Bloque({required this.titulo, required this.filas});
  final String titulo;
  final List<Widget> filas;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            ...filas,
          ],
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila(this.icono, this.texto, {this.sub, this.color});
  final IconData icono;
  final String texto;
  final String? sub;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final suave = context.flog.textoSuave;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: color ?? suave),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(texto, style: t.bodyLarge?.copyWith(color: color, fontWeight: color != null ? FontWeight.w600 : null)),
                if (sub != null) Text(sub!, style: t.bodyMedium?.copyWith(color: suave)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FlogColors.aviso.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.info, color: FlogColors.aviso),
          const SizedBox(width: 10),
          Expanded(child: Text(texto, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: FlogColors.aviso))),
        ],
      ),
    );
  }
}
