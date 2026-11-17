import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/torneo.dart';
import '../state/perfil_state.dart';
import '../state/torneos_state.dart';
import 'agenda_row.dart';

/// Lista de filas de agenda separadas por líneas finas.
class ListaTorneos extends StatelessWidget {
  const ListaTorneos({super.key, required this.torneos, this.mostrarFecha = true, this.compacta = false});
  final List<Torneo> torneos;
  final bool mostrarFecha;
  final bool compacta;

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
            compacta: compacta,
          ),
          if (i < torneos.length - 1) Divider(indent: mostrarFecha ? 83 : 35, endIndent: 20, color: tokens.linea),
        ],
      ],
    );
  }
}
