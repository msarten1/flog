import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/dates.dart';
import '../../core/theme.dart';
import '../../models/torneo.dart';
import '../../state/perfil_state.dart';
import '../../state/torneos_state.dart';
import '../../widgets/agenda_row.dart';
import '../../widgets/comunes.dart';

/// Pantalla principal: agenda de torneos con buscador y filtros en un panel.
class TorneosPage extends StatefulWidget {
  const TorneosPage({super.key});

  @override
  State<TorneosPage> createState() => _TorneosPageState();
}

class _TorneosPageState extends State<TorneosPage> {
  final _busqueda = TextEditingController();
  bool _buscando = false;

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  void _toggleBusqueda(TorneosState s) {
    setState(() => _buscando = !_buscando);
    if (!_buscando) {
      _busqueda.clear();
      s.setQuery('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<TorneosState>();
    final perfil = context.watch<PerfilState>();
    final tokens = context.flog;
    final text = Theme.of(context).textTheme;
    final secciones = _agrupar(s.filtrados);
    final nFiltros = s.numFiltrosActivos;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: tokens.fondo,
        foregroundColor: tokens.texto,
        titleSpacing: 20,
        title: _buscando
            ? TextField(
                controller: _busqueda,
                autofocus: true,
                onChanged: s.setQuery,
                textInputAction: TextInputAction.search,
                style: text.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Torneo, club o modalidad',
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintStyle: text.bodyLarge?.copyWith(color: tokens.textoSuave),
                ),
              )
            : Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset('assets/branding/icon-192.png', width: 28, height: 28),
                  ),
                  const SizedBox(width: 10),
                  Text(FlogConfig.appName, style: text.headlineSmall?.copyWith(color: tokens.texto)),
                ],
              ),
        actions: [
          IconButton(
            tooltip: _buscando ? 'Cerrar búsqueda' : 'Buscar',
            icon: Icon(_buscando ? Icons.close : Icons.search),
            onPressed: () => _toggleBusqueda(s),
          ),
          Badge(
            isLabelVisible: nFiltros > 0,
            label: Text('$nFiltros'),
            backgroundColor: FlogColors.verde700,
            offset: const Offset(-6, 6),
            child: IconButton(
              tooltip: 'Filtros',
              icon: Icon(nFiltros > 0 ? Icons.filter_alt : Icons.filter_alt_outlined),
              onPressed: () => _abrirFiltros(context, s),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        color: FlogColors.verde900,
        onRefresh: s.refrescar,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            if (s.sinConexion)
              const SliverToBoxAdapter(child: Franja(texto: 'Sin conexión · se muestran los últimos datos guardados')),
            if (nFiltros > 0) SliverToBoxAdapter(child: _ResumenFiltros(state: s)),
            if (s.catalogo == null)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (secciones.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EstadoVacio(
                  titulo: s.hayFiltros ? 'Nada con esos filtros' : 'No hay torneos próximos',
                  texto: s.hayFiltros ? 'Prueba a quitar algún filtro o cambiar la búsqueda.' : 'Cada mañana se revisan las webs de la Federación y de los clubes.',
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
              for (final sec in secciones) ...[
                SliverToBoxAdapter(child: CabeceraAgenda(sec.titulo, detalle: sec.detalle)),
                SliverList.separated(
                  itemCount: sec.torneos.length,
                  separatorBuilder: (_, _) => Divider(indent: 83, endIndent: 20, color: tokens.linea),
                  itemBuilder: (_, i) {
                    final t = sec.torneos[i];
                    return AgendaRow(torneo: t, esNuevo: s.esNuevo(t), inscrito: perfil.estaInscrito(t.id));
                  },
                ),
              ],
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  /// Esta semana · Próximamente (30 días) · después, por mes.
  List<_Seccion> _agrupar(List<Torneo> torneos) {
    final hoy = Fechas.hoy();
    final finSemana = hoy.add(Duration(days: 7 - hoy.weekday)); // domingo
    final en30 = hoy.add(const Duration(days: 30));
    final semana = <Torneo>[];
    final proximos = <Torneo>[];
    final porMes = <String, List<Torneo>>{};
    for (final t in torneos) {
      if (!t.inicio.isAfter(finSemana)) {
        semana.add(t);
      } else if (!t.inicio.isAfter(en30)) {
        proximos.add(t);
      } else {
        porMes.putIfAbsent(t.fecha.substring(0, 7), () => []).add(t);
      }
    }
    return [
      if (semana.isNotEmpty) _Seccion('Esta semana', semana, detalle: '${semana.length}'),
      if (proximos.isNotEmpty) _Seccion('Próximamente', proximos, detalle: 'hasta el ${Fechas.corta(en30)}'),
      for (final e in porMes.entries) _Seccion(Fechas.mesAnio(Fechas.parse('${e.key}-01')), e.value),
    ];
  }

  Future<void> _abrirFiltros(BuildContext context, TorneosState s) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: context.flog.superficie,
      builder: (_) => ChangeNotifierProvider.value(value: s, child: const _PanelFiltros()),
    );
  }
}

class _Seccion {
  _Seccion(this.titulo, this.torneos, {this.detalle});
  final String titulo;
  final List<Torneo> torneos;
  final String? detalle;
}

class _ResumenFiltros extends StatelessWidget {
  const _ResumenFiltros({required this.state});
  final TorneosState state;

  @override
  Widget build(BuildContext context) {
    final chips = <String>[
      if (state.provincia != 'Todas') state.provincia,
      if (state.tipo != 'Todos') state.tipo == 'Nacional en la CV' ? 'Nacional' : state.tipo,
      if (state.soloNuevos) 'Nuevos',
      if (state.soloInscritos) 'Inscrito',
      if (state.query.isNotEmpty) '"${state.query}"',
    ];
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
        children: [
          for (final c in chips)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(label: Text(c), visualDensity: VisualDensity.compact),
            ),
          TextButton(onPressed: state.limpiarFiltros, child: const Text('Quitar')),
        ],
      ),
    );
  }
}

class _PanelFiltros extends StatelessWidget {
  const _PanelFiltros();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<TorneosState>();
    final text = Theme.of(context).textTheme;
    final tokens = context.flog;

    Widget grupo(String titulo, List<String> opciones, bool Function(String) sel, void Function(String) onTap, {Color? Function(String)? colorDe}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: text.labelMedium?.copyWith(color: tokens.textoSuave)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in opciones)
                FilterChip(
                  label: Text(o == 'Nacional en la CV' ? 'Nacional' : o),
                  selected: sel(o),
                  onSelected: (_) => onTap(o),
                  selectedColor: colorDe?.call(o) ?? FlogColors.verde900,
                ),
            ],
          ),
          const SizedBox(height: 18),
        ],
      );
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Filtros', style: text.titleLarge),
                const Spacer(),
                if (s.hayFiltros) TextButton(onPressed: s.limpiarFiltros, child: const Text('Quitar todos')),
              ],
            ),
            const SizedBox(height: 12),
            grupo('Provincia', ['Todas', ...FlogConfig.provincias], (o) => o == s.provincia, s.setProvincia),
            grupo(
              'Tipo',
              ['Todos', ...s.tiposDisponibles],
              (o) => o == s.tipo,
              s.setTipo,
              colorDe: (o) => o == 'Todos' ? null : FlogColors.tipo(o),
            ),
            Text('Mostrar solo', style: text.labelMedium?.copyWith(color: tokens.textoSuave)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Nuevos esta semana'),
                  selected: s.soloNuevos,
                  onSelected: (_) => s.toggleSoloNuevos(),
                  selectedColor: FlogColors.verde900,
                ),
                FilterChip(
                  label: const Text('Donde estoy inscrito'),
                  selected: s.soloInscritos,
                  onSelected: (_) => s.toggleSoloInscritos(),
                  selectedColor: FlogColors.verde900,
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Ver ${s.filtrados.length} torneos'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista de filas de agenda reutilizada por el calendario y el perfil.
class ListaTorneos extends StatelessWidget {
  const ListaTorneos({super.key, required this.torneos, this.mostrarFecha = true});
  final List<Torneo> torneos;
  final bool mostrarFecha;

  @override
  Widget build(BuildContext context) {
    final s = context.read<TorneosState>();
    final perfil = context.watch<PerfilState>();
    final tokens = context.flog;
    return Column(
      children: [
        for (var i = 0; i < torneos.length; i++) ...[
          AgendaRow(
            torneo: torneos[i],
            esNuevo: s.esNuevo(torneos[i]),
            inscrito: perfil.estaInscrito(torneos[i].id),
            mostrarFecha: mostrarFecha,
          ),
          if (i < torneos.length - 1) Divider(indent: mostrarFecha ? 83 : 35, endIndent: 20, color: tokens.linea),
        ],
      ],
    );
  }
}
