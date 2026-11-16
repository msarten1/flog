import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/dates.dart';
import '../../core/theme.dart';
import '../../models/torneo.dart';
import '../../state/torneos_state.dart';
import '../../widgets/comunes.dart';
import '../../widgets/torneo_card.dart';

class TorneosPage extends StatefulWidget {
  const TorneosPage({super.key});

  @override
  State<TorneosPage> createState() => _TorneosPageState();
}

class _TorneosPageState extends State<TorneosPage> {
  final _busqueda = TextEditingController();

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<TorneosState>();
    final porMes = s.filtradosPorMes;
    final meses = porMes.keys.toList();

    return Scaffold(
      body: RefreshIndicator(
        color: FlogColors.verde900,
        onRefresh: s.refrescar,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(child: _Cabecera(state: s)),
            if (s.sinConexion)
              const SliverToBoxAdapter(child: Franja(texto: 'Sin conexión · se muestran los últimos datos guardados')),
            SliverToBoxAdapter(child: _Filtros(state: s, controller: _busqueda)),
            if (s.catalogo == null)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (meses.isEmpty)
              SliverToBoxAdapter(
                child: EstadoVacio(
                  titulo: s.hayFiltros ? 'Nada con esos filtros' : 'No hay torneos próximos',
                  texto: s.hayFiltros ? 'Prueba a quitar algún filtro o cambiar la búsqueda.' : 'Cada lunes se revisan las webs de la Federación y de los clubes.',
                  accion: s.hayFiltros
                      ? OutlinedButton.icon(
                          onPressed: () {
                            _busqueda.clear();
                            s.limpiarFiltros();
                          },
                          icon: const Icon(Icons.filter_alt_off_outlined),
                          label: const Text('Quitar filtros'),
                        )
                      : null,
                ),
              )
            else
              for (final mes in meses) ...[
                SliverToBoxAdapter(child: TituloSeccion(Fechas.mesAnio(Fechas.parse('$mes-01')))),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: porMes[mes]!.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final t = porMes[mes]![i];
                      return TorneoCard(torneo: t, esNuevo: s.esNuevo(t));
                    },
                  ),
                ),
              ],
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.state});
  final TorneosState state;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final top = MediaQuery.paddingOf(context).top;
    final proximo = state.proximo;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF15523D), FlogColors.verde900],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset('assets/branding/icon-192.png', width: 36, height: 36),
              ),
              const SizedBox(width: 10),
              Text(FlogConfig.appName, style: t.headlineMedium?.copyWith(color: Colors.white)),
              const Spacer(),
              if (state.cargando)
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: FlogColors.lima)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Torneos de golf amateur · Comunitat Valenciana',
            style: t.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Cifra(valor: '${state.vigentes.length}', titulo: 'próximos'),
              const SizedBox(width: 10),
              Cifra(valor: '${state.nuevosEstaSemana}', titulo: 'nuevos esta semana'),
              const SizedBox(width: 10),
              Cifra(valor: proximo == null ? '—' : Fechas.relativo(proximo.inicio), titulo: 'siguiente torneo'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Filtros extends StatelessWidget {
  const _Filtros({required this.state, required this.controller});
  final TorneosState state;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final tipos = state.tiposDisponibles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: TextField(
            controller: controller,
            onChanged: state.setQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar torneo, club o modalidad',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: state.query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        controller.clear();
                        state.setQuery('');
                      },
                    ),
            ),
          ),
        ),
        _FilaChips(
          opciones: ['Todas', ...FlogConfig.provincias],
          seleccionada: (o) => o == state.provincia,
          onTap: state.setProvincia,
        ),
        const SizedBox(height: 8),
        _FilaChips(
          opciones: ['Todos', ...tipos, 'Solo nuevos'],
          seleccionada: (o) => o == 'Solo nuevos' ? state.soloNuevos : o == state.tipo,
          onTap: (o) => o == 'Solo nuevos' ? state.toggleSoloNuevos() : state.setTipo(o),
          colorDe: (o) => o == 'Solo nuevos' || o == 'Todos' ? null : FlogColors.tipo(o),
        ),
      ],
    );
  }
}

class _FilaChips extends StatelessWidget {
  const _FilaChips({required this.opciones, required this.seleccionada, required this.onTap, this.colorDe});
  final List<String> opciones;
  final bool Function(String) seleccionada;
  final void Function(String) onTap;
  final Color? Function(String)? colorDe;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: opciones.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final o = opciones[i];
          final sel = seleccionada(o);
          final color = colorDe?.call(o);
          return FilterChip(
            label: Text(o == 'Nacional en la CV' ? 'Nacional' : o),
            selected: sel,
            onSelected: (_) => onTap(o),
            selectedColor: color ?? FlogColors.verde900,
            avatar: color != null && !sel
                ? Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle))
                : null,
          );
        },
      ),
    );
  }
}

/// Lista sencilla reutilizada por el calendario.
class ListaTorneos extends StatelessWidget {
  const ListaTorneos({super.key, required this.torneos, this.compacta = true});
  final List<Torneo> torneos;
  final bool compacta;

  @override
  Widget build(BuildContext context) {
    final s = context.read<TorneosState>();
    return Column(
      children: [
        for (final t in torneos) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TorneoCard(torneo: t, esNuevo: s.esNuevo(t), compacta: compacta),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
