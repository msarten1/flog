import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/config.dart';
import '../core/theme.dart';
import '../state/torneos_state.dart';

/// Abre el panel inferior de filtros.
Future<void> abrirFiltros(BuildContext context, TorneosState s) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: context.flog.superficie,
    builder: (_) => ChangeNotifierProvider.value(value: s, child: const PanelFiltros()),
  );
}

/// Chips con los filtros activos y botón para quitarlos.
class ResumenFiltros extends StatelessWidget {
  const ResumenFiltros({super.key, required this.state});
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
    if (chips.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 12, 0),
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

class PanelFiltros extends StatelessWidget {
  const PanelFiltros({super.key});

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
