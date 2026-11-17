import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/dates.dart';
import '../../core/theme.dart';
import '../../models/torneo.dart';
import '../../services/rfeg_service.dart';
import '../../state/perfil_state.dart';
import '../../state/torneos_state.dart';
import '../../widgets/comunes.dart';
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
                  onTap: () => _buscarRfeg(context, ps),
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
                      onPressed: () => _buscarRfeg(context, ps),
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

  Future<void> _buscarRfeg(BuildContext context, PerfilState ps) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.flog.superficie,
      builder: (_) => _BuscadorRfeg(inicial: ps.perfil.licencia.isNotEmpty ? ps.perfil.licencia : ps.perfil.nombre, onElegir: (j) => ps.guardar(
            ps.perfil.copyWith(
              nombre: j.nombre,
              club: j.club,
              licencia: j.licencia,
              handicap: j.handicap,
              handicapActualizado: Fechas.iso(Fechas.hoy()),
              borrarHandicap: j.handicap == null,
            ),
          )),
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

class _BuscadorRfeg extends StatefulWidget {
  const _BuscadorRfeg({required this.inicial, required this.onElegir});
  final String inicial;
  final Future<void> Function(JugadorRfeg) onElegir;

  @override
  State<_BuscadorRfeg> createState() => _BuscadorRfegState();
}

class _BuscadorRfegState extends State<_BuscadorRfeg> {
  final _rfeg = RfegService();
  late final _q = TextEditingController(text: widget.inicial);
  List<JugadorRfeg> _resultados = const [];
  bool _cargando = false;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.inicial.trim().length >= 5) _buscar(widget.inicial);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () => _buscar(v));
  }

  Future<void> _buscar(String q) async {
    if (q.trim().length < 5) {
      setState(() => _resultados = const []);
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final r = await _rfeg.buscar(q);
      if (mounted) setState(() => _resultados = r);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo consultar la RFEG. Comprueba la conexión.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tokens = context.flog;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hándicap RFEG', style: text.titleLarge),
          const SizedBox(height: 4),
          Text('Busca por número de licencia o por nombre y apellidos.', style: text.bodyMedium?.copyWith(color: tokens.textoSuave)),
          const SizedBox(height: 12),
          TextField(
            controller: _q,
            autofocus: widget.inicial.isEmpty,
            onChanged: _onChanged,
            decoration: InputDecoration(
              hintText: 'Licencia o nombre',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _cargando ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))) : null,
            ),
          ),
          const SizedBox(height: 10),
          if (_error != null) Text(_error!, style: text.bodyMedium?.copyWith(color: FlogColors.aviso)),
          if (_resultados.isEmpty && !_cargando && _error == null && _q.text.trim().length >= 5)
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('Sin resultados.', style: text.bodyMedium?.copyWith(color: tokens.textoSuave))),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.45),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _resultados.length,
              separatorBuilder: (_, _) => Divider(color: tokens.linea),
              itemBuilder: (_, i) {
                final j = _resultados[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(j.nombre, style: text.titleMedium),
                  subtitle: Text('${j.club} · Lic. ${j.licencia}', maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Text(
                    j.handicap == null ? (j.profesional ? 'PRO' : '—') : j.handicap!.toStringAsFixed(1),
                    style: text.titleLarge?.copyWith(color: FlogColors.verde700),
                  ),
                  onTap: () async {
                    await widget.onElegir(j);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
