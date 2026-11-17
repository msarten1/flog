import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/dates.dart';
import '../../core/theme.dart';
import '../../models/torneo.dart';
import '../../services/push_service.dart';
import '../../state/perfil_state.dart';
import '../../state/torneos_state.dart';
import '../../widgets/agenda_row.dart';
import '../../widgets/comunes.dart';
import '../../widgets/lista_torneos.dart';

/// Pantalla de inicio: lo que te importa hoy.
class HoyPage extends StatelessWidget {
  const HoyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<TorneosState>();
    final ps = context.watch<PerfilState>();
    final push = context.watch<PushService>();
    final tokens = context.flog;
    final text = Theme.of(context).textTheme;
    final p = ps.perfil;

    final provincias = push.provincias;
    final proximoInscrito = s.proximoInscrito(ps.inscritos);
    final destacado = proximoInscrito ?? s.proximoEn(provincias);
    final cierran = s.cierranPronto.where((e) => !ps.estaInscrito(e.torneo.id)).take(4).toList();
    final nuevos = s.nuevosEn(provincias).take(5).toList();
    final semana = s.estaSemana;

    return Scaffold(
      body: RefreshIndicator(
        color: FlogColors.verde900,
        onRefresh: s.refrescar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            _Cabecera(perfil: p, cargando: s.cargando),
            if (s.sinConexion) const Franja(texto: 'Sin conexión · se muestran los últimos datos guardados'),
            if (s.catalogo == null)
              const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: destacado == null
                    ? const EstadoVacio(titulo: 'No hay torneos próximos', icono: Icons.event_busy_outlined)
                    : _TarjetaDestacada(
                        torneo: destacado,
                        inscrito: proximoInscrito != null,
                        provincias: provincias,
                      ),
              ),
              if (cierran.isNotEmpty) ...[
                const CabeceraAgenda('Cierran pronto'),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      for (var i = 0; i < cierran.length; i++) ...[
                        AgendaRow(
                          torneo: cierran[i].torneo,
                          cierre: cierran[i].cierre,
                          inscrito: ps.estaInscrito(cierran[i].torneo.id),
                        ),
                        if (i < cierran.length - 1) Divider(indent: 83, endIndent: 20, color: tokens.linea),
                      ],
                    ],
                  ),
                ),
              ],
              CabeceraAgenda(
                provincias.isEmpty ? 'Nuevos esta semana' : 'Nuevos en ${provincias.join(', ')}',
                detalle: nuevos.isEmpty ? null : '${s.nuevosEn(provincias).length}',
                accion: nuevos.isEmpty
                    ? null
                    : TextButton(
                        onPressed: () {
                          s.limpiarFiltros();
                          s.toggleSoloNuevos();
                          context.go('/calendario');
                        },
                        child: const Text('Ver todos'),
                      ),
              ),
              if (nuevos.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Nada nuevo desde la última revisión.', style: text.bodyMedium?.copyWith(color: tokens.textoSuave)),
                )
              else
                Card(margin: const EdgeInsets.symmetric(horizontal: 16), child: ListaTorneos(torneos: nuevos, compacta: true)),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _AccesoCalendario(semana: semana.length, total: s.vigentes.length),
              ),
              if (provincias.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.notifications_active_outlined, color: FlogColors.verde700),
                      title: const Text('Activa los avisos'),
                      subtitle: const Text('Elige tus provincias y te avisaremos de los torneos nuevos.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/configuracion'),
                    ),
                  ),
                ),
              if (p.vacio)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.person_outline, color: FlogColors.verde700),
                      title: const Text('Completa tu perfil'),
                      subtitle: const Text('Con tu licencia, Flog rellena las inscripciones por ti.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/perfil'),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.perfil, required this.cargando});
  final Perfil perfil;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tokens = context.flog;
    final top = MediaQuery.paddingOf(context).top;
    final hoy = Fechas.hoy();
    final nombre = perfil.nombre.trim().isEmpty ? 'golfista' : perfil.nombre.trim().split(RegExp(r'\s+')).first;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, top + 18, 20, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${Fechas.diasLargos[hoy.weekday - 1]} ${hoy.day} de ${Fechas.meses[hoy.month - 1]}',
                  style: text.labelMedium?.copyWith(color: tokens.textoSuave),
                ),
                const SizedBox(height: 2),
                Text('Hola, $nombre', style: text.headlineMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (cargando)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          IconButton(
            tooltip: 'Configuración',
            icon: Icon(Icons.settings_outlined, color: tokens.textoSuave),
            onPressed: () => context.push('/configuracion'),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => context.go('/perfil'),
            borderRadius: BorderRadius.circular(999),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: FlogColors.lima,
                  child: Text(perfil.iniciales, style: text.titleMedium?.copyWith(color: FlogColors.verde900)),
                ),
                if (perfil.handicap != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text('hcp ${perfil.handicap!.toStringAsFixed(1)}',
                        style: text.labelSmall?.copyWith(color: FlogColors.verde700, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaDestacada extends StatelessWidget {
  const _TarjetaDestacada({required this.torneo, required this.inscrito, required this.provincias});
  final Torneo torneo;
  final bool inscrito;
  final Set<String> provincias;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final t = torneo;
    final color = FlogColors.tipo(t.tipo);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/torneo/${t.id}'),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF17573F), FlogColors.verde900],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(inscrito ? Icons.check_circle : Icons.flag_outlined, size: 16, color: FlogColors.lima),
                  const SizedBox(width: 6),
                  Text(
                    inscrito ? 'TU PRÓXIMO TORNEO' : (provincias.isEmpty ? 'PRÓXIMO TORNEO' : 'PRÓXIMO EN TU ZONA'),
                    style: text.labelSmall?.copyWith(color: FlogColors.lima, fontWeight: FontWeight.w800, letterSpacing: 1.1),
                  ),
                  const Spacer(),
                  Text(Fechas.relativo(t.inicio), style: text.labelMedium?.copyWith(color: Colors.white.withValues(alpha: 0.8))),
                ],
              ),
              const SizedBox(height: 10),
              Text(t.nombre, style: text.headlineSmall?.copyWith(color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('${t.club} · ${t.provincia}', style: text.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.8))),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(Fechas.larga(t.inicio), style: text.labelMedium?.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (!inscrito)
                    FilledButton.tonal(
                      onPressed: () => context.push('/inscribir/${t.id}'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        backgroundColor: FlogColors.lima,
                        foregroundColor: FlogColors.verde900,
                      ),
                      child: const Text('Inscribirme'),
                    ),
                ],
              ),
              if (!inscrito) ...[
                const SizedBox(height: 12),
                Text(
                  'Marca los torneos en los que te inscribas y aparecerán aquí.',
                  style: text.labelMedium?.copyWith(color: Colors.white.withValues(alpha: 0.65), fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AccesoCalendario extends StatelessWidget {
  const _AccesoCalendario({required this.semana, required this.total});
  final int semana;
  final int total;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tokens = context.flog;
    return Card(
      child: InkWell(
        onTap: () => context.go('/calendario'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_outlined, color: FlogColors.verde700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Calendario', style: text.titleMedium),
                    Text(
                      '$semana ${semana == 1 ? 'torneo' : 'torneos'} esta semana · $total próximos',
                      style: text.bodyMedium?.copyWith(color: tokens.textoSuave),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: tokens.textoSuave),
            ],
          ),
        ),
      ),
    );
  }
}
