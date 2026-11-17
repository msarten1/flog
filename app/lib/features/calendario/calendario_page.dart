import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/dates.dart';
import '../../core/theme.dart';
import '../../models/torneo.dart';
import '../../state/perfil_state.dart';
import '../../state/torneos_state.dart';
import '../../widgets/comunes.dart';
import '../../widgets/filtros_sheet.dart';
import '../../widgets/lista_torneos.dart';

class CalendarioPage extends StatefulWidget {
  const CalendarioPage({super.key});

  @override
  State<CalendarioPage> createState() => _CalendarioPageState();
}

class _CalendarioPageState extends State<CalendarioPage> {
  DateTime _foco = Fechas.hoy();
  DateTime? _seleccion;
  final _busqueda = TextEditingController();
  bool _buscando = false;

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<TorneosState>();
    final perfil = context.watch<PerfilState>();
    final hoy = Fechas.hoy();
    final sel = _seleccion;
    final filtrados = s.filtrados;
    final delDia = sel == null ? const <Torneo>[] : filtrados.where((t) => t.cubre(DateTime(sel.year, sel.month, sel.day))).toList();
    final delMes = filtrados.where((t) => t.inicio.year == _foco.year && t.inicio.month == _foco.month).toList();
    final nFiltros = s.numFiltrosActivos;
    final tokens = context.flog;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: _buscando
            ? TextField(
                controller: _busqueda,
                autofocus: true,
                onChanged: s.setQuery,
                textInputAction: TextInputAction.search,
                style: text.bodyLarge?.copyWith(color: Colors.white),
                cursorColor: FlogColors.lima,
                decoration: InputDecoration(
                  hintText: 'Torneo, club o modalidad',
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintStyle: text.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.6)),
                ),
              )
            : const Text('Calendario'),
        actions: [
          IconButton(
            tooltip: _buscando ? 'Cerrar búsqueda' : 'Buscar',
            icon: Icon(_buscando ? Icons.close : Icons.search),
            onPressed: () {
              setState(() => _buscando = !_buscando);
              if (!_buscando) {
                _busqueda.clear();
                s.setQuery('');
              }
            },
          ),
          Badge(
            isLabelVisible: nFiltros > 0,
            label: Text('$nFiltros'),
            backgroundColor: FlogColors.lima,
            textColor: FlogColors.verde900,
            offset: const Offset(-6, 6),
            child: IconButton(
              tooltip: 'Filtros',
              icon: Icon(nFiltros > 0 ? Icons.filter_alt : Icons.filter_alt_outlined),
              onPressed: () => abrirFiltros(context, s),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (nFiltros > 0) ResumenFiltros(state: s),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: tokens.superficie,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: tokens.linea),
            ),
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
            child: TableCalendar<Torneo>(
              locale: 'es_ES',
              firstDay: DateTime(hoy.year - 1, 1, 1),
              lastDay: DateTime(hoy.year + 2, 12, 31),
              focusedDay: _foco,
              startingDayOfWeek: StartingDayOfWeek.monday,
              availableCalendarFormats: const {CalendarFormat.month: 'Mes'},
              selectedDayPredicate: (d) => sel != null && Fechas.mismoDia(d, sel),
              eventLoader: (d) => filtrados.where((t) => t.cubre(DateTime(d.year, d.month, d.day))).toList(),
              onDaySelected: (d, f) => setState(() {
                _seleccion = Fechas.mismoDia(d, sel ?? DateTime(0)) ? null : d;
                _foco = f;
              }),
              onPageChanged: (f) => setState(() => _foco = f),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: text.titleLarge!,
                leftChevronIcon: Icon(Icons.chevron_left, color: tokens.textoSuave),
                rightChevronIcon: Icon(Icons.chevron_right, color: tokens.textoSuave),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: text.labelSmall!.copyWith(color: tokens.textoSuave),
                weekendStyle: text.labelSmall!.copyWith(color: tokens.textoSuave),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle: text.bodyMedium!,
                weekendTextStyle: text.bodyMedium!,
                todayDecoration: BoxDecoration(
                  color: FlogColors.lima.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: text.bodyMedium!.copyWith(fontWeight: FontWeight.w700, color: FlogColors.verde900),
                selectedDecoration: const BoxDecoration(color: FlogColors.verde900, shape: BoxShape.circle),
                selectedTextStyle: text.bodyMedium!.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                markersMaxCount: 3,
                markerMargin: const EdgeInsets.symmetric(horizontal: 1.2),
                markerSize: 6,
              ),
              calendarBuilders: CalendarBuilders<Torneo>(
                // Día con un torneo en el que estoy inscrito: anillo lima.
                defaultBuilder: (context, day, focused) {
                  final dia = DateTime(day.year, day.month, day.day);
                  if (!filtrados.any((t) => t.cubre(dia) && perfil.estaInscrito(t.id))) return null;
                  return Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: FlogColors.lima.withValues(alpha: context.esOscuro ? 0.25 : 0.55),
                        border: Border.all(color: FlogColors.verde500, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text('${day.day}', style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w700, color: FlogColors.verde900)),
                    ),
                  );
                },
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return null;
                  final inscrito = events.any((t) => perfil.estaInscrito(t.id));
                  return Positioned(
                    bottom: 4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (inscrito)
                          const Icon(Icons.check, size: 10, color: FlogColors.verde900)
                        else
                        for (final e in events.take(3))
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 1.2),
                            decoration: BoxDecoration(color: FlogColors.tipo(e.tipo), shape: BoxShape.circle),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          _Leyenda(),
          if (sel != null) ...[
            TituloSeccion(
              Fechas.larga(sel),
              derecha: TextButton(onPressed: () => setState(() => _seleccion = null), child: const Text('Ver todo el mes')),
            ),
            if (delDia.isEmpty)
              EstadoVacio(titulo: nFiltros > 0 ? 'Nada ese día con esos filtros' : 'Sin torneos ese día', icono: Icons.event_busy_outlined)
            else
              Card(margin: const EdgeInsets.symmetric(horizontal: 16), child: ListaTorneos(torneos: delDia, mostrarFecha: false)),
          ] else if (s.query.isNotEmpty) ...[
            TituloSeccion('Resultados', derecha: Text('${filtrados.length}', style: text.titleMedium?.copyWith(color: tokens.textoSuave))),
            if (filtrados.isEmpty)
              const EstadoVacio(titulo: 'Sin resultados', texto: 'Prueba con otro nombre, club o modalidad.', icono: Icons.search_off)
            else
              Card(margin: const EdgeInsets.symmetric(horizontal: 16), child: ListaTorneos(torneos: filtrados)),
          ] else ...[
            TituloSeccion('Torneos de ${Fechas.mesAnio(_foco).toLowerCase()}'),
            if (delMes.isEmpty)
              EstadoVacio(titulo: nFiltros > 0 ? 'Nada este mes con esos filtros' : 'Sin torneos este mes', texto: 'Toca un día o cambia de mes.', icono: Icons.event_busy_outlined)
            else
              Card(margin: const EdgeInsets.symmetric(horizontal: 16), child: ListaTorneos(torneos: delMes)),
          ],
        ],
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme.labelSmall?.copyWith(color: context.flog.textoSuave);
    Widget punto(String nombre) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: FlogColors.tipo(nombre), shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(nombre == 'Nacional en la CV' ? 'Nacional' : nombre, style: t),
          ],
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 14,
        runSpacing: 4,
        children: [
          punto('Federación'),
          punto('Club'),
          punto('Circuito'),
          punto('Nacional en la CV'),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(shape: BoxShape.circle, color: FlogColors.lima.withValues(alpha: 0.55), border: Border.all(color: FlogColors.verde500, width: 1.5)),
              ),
              const SizedBox(width: 5),
              Text('Inscrito', style: t),
            ],
          ),
        ],
      ),
    );
  }
}
