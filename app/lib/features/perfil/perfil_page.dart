import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/dates.dart';
import '../../core/theme.dart';
import '../../models/torneo.dart';
import '../../state/perfil_state.dart';
import '../../state/torneos_state.dart';
import '../../widgets/comunes.dart';
import '../../widgets/buscador_rfeg.dart';
import '../../widgets/lista_torneos.dart';

class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ps = context.watch<PerfilState>();
    final s = context.watch<TorneosState>();
    final p = ps.perfil;
    final text = Theme.of(context).textTheme;
    final tokens = context.flog;

    final inscritos = s.vigentes.where((t) => ps.estaInscrito(t.id)).toList();
    final pasados = (s.catalogo?.torneos ?? const <Torneo>[])
        .where((t) => ps.estaInscrito(t.id) && !t.vigente)
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            tooltip: 'Editar datos',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editar(context, ps),
          ),
          IconButton(
            tooltip: 'Configuración',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/configuracion'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // Cabecera con avatar y datos
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            decoration: const BoxDecoration(
              color: FlogColors.verde900,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: FlogColors.lima,
                  child: Text(p.iniciales, style: text.headlineSmall?.copyWith(color: FlogColors.verde900)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nombre.isEmpty ? 'Tu nombre' : p.nombre,
                        style: text.titleLarge?.copyWith(color: Colors.white),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [if (p.club.isNotEmpty) p.club, if (p.licencia.isNotEmpty) 'Lic. ${p.licencia}', if (p.email.isNotEmpty) p.email].join(' · '),
                        style: text.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.75)),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      p.handicap == null ? '—' : p.handicap!.toStringAsFixed(1),
                      style: text.headlineMedium?.copyWith(color: FlogColors.lima),
                    ),
                    Text('hándicap', style: text.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.75))),
                  ],
                ),
              ],
            ),
          ),
          if (p.vacio)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.person_search_outlined, color: FlogColors.verde700),
                  title: const Text('Completa tu ficha'),
                  subtitle: const Text('Busca tu licencia en la RFEG para rellenar nombre, club y hándicap.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => mostrarBuscadorRfeg(context, ps),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => mostrarBuscadorRfeg(context, ps),
                      icon: const Icon(Icons.sync),
                      label: Text(p.handicapActualizado == null ? 'Hándicap RFEG' : 'Actualizar (${Fechas.corta(Fechas.parse(p.handicapActualizado!))})'),
                    ),
                  ),
                ],
              ),
            ),

          // Mis torneos
          TituloSeccion('Mis torneos', derecha: Text('${inscritos.length}', style: text.titleMedium?.copyWith(color: tokens.textoSuave))),
          if (inscritos.isEmpty)
            const EstadoVacio(
              titulo: 'Aún no has marcado ninguno',
              texto: 'En la ficha de un torneo, pulsa "Me he inscrito" y aparecerá aquí y en el calendario.',
              icono: Icons.how_to_reg_outlined,
            )
          else
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListaTorneos(torneos: inscritos),
            ),
          if (pasados.isNotEmpty) ...[
            TituloSeccion('Ya jugados', derecha: Text('${pasados.length}', style: text.titleMedium?.copyWith(color: tokens.textoSuave))),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListaTorneos(torneos: pasados),
            ),
          ],
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Tus datos se guardan solo en este móvil. El hándicap se consulta en el buscador público de la RFEG.',
              style: text.labelMedium?.copyWith(color: tokens.textoSuave, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editar(BuildContext context, PerfilState ps) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.flog.superficie,
      builder: (_) => _FormularioPerfil(inicial: ps.perfil, onGuardar: ps.guardar),
    );
  }
}

class _FormularioPerfil extends StatefulWidget {
  const _FormularioPerfil({required this.inicial, required this.onGuardar});
  final Perfil inicial;
  final Future<void> Function(Perfil) onGuardar;

  @override
  State<_FormularioPerfil> createState() => _FormularioPerfilState();
}

class _FormularioPerfilState extends State<_FormularioPerfil> {
  late final _nombre = TextEditingController(text: widget.inicial.nombre);
  late final _club = TextEditingController(text: widget.inicial.club);
  late final _licencia = TextEditingController(text: widget.inicial.licencia);
  late final _email = TextEditingController(text: widget.inicial.email);
  late final _hcp = TextEditingController(text: widget.inicial.handicap?.toStringAsFixed(1) ?? '');

  @override
  void dispose() {
    for (final c in [_nombre, _club, _licencia, _email, _hcp]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mis datos', style: text.titleLarge),
          const SizedBox(height: 14),
          TextField(controller: _nombre, decoration: const InputDecoration(labelText: 'Nombre'), textCapitalization: TextCapitalization.words),
          const SizedBox(height: 10),
          TextField(controller: _club, decoration: const InputDecoration(labelText: 'Club habitual'), textCapitalization: TextCapitalization.words),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: TextField(controller: _licencia, decoration: const InputDecoration(labelText: 'Licencia'), keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _hcp,
                  decoration: const InputDecoration(labelText: 'Hándicap'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email (para las inscripciones)'), keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () async {
              final hcp = double.tryParse(_hcp.text.trim().replaceAll(',', '.'));
              await widget.onGuardar(
                widget.inicial.copyWith(
                  nombre: _nombre.text.trim(),
                  club: _club.text.trim(),
                  licencia: _licencia.text.trim(),
                  email: _email.text.trim(),
                  handicap: hcp,
                  borrarHandicap: _hcp.text.trim().isEmpty,
                  handicapActualizado: hcp != null && hcp != widget.inicial.handicap ? Fechas.iso(Fechas.hoy()) : null,
                ),
              );
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
