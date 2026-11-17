import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../core/dates.dart';
import '../core/theme.dart';
import '../services/rfeg_service.dart';
import '../state/perfil_state.dart';


/// Abre el buscador de la RFEG y guarda en el perfil el jugador elegido.
Future<void> mostrarBuscadorRfeg(BuildContext context, PerfilState ps) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: context.flog.superficie,
    builder: (_) => BuscadorRfeg(
      inicial: ps.perfil.licencia.isNotEmpty ? ps.perfil.licencia : ps.perfil.nombre,
      onElegir: (j) => ps.guardar(
        ps.perfil.copyWith(
          nombre: j.nombre,
          club: j.club,
          licencia: j.licencia,
          handicap: j.handicap,
          handicapActualizado: Fechas.iso(Fechas.hoy()),
          borrarHandicap: j.handicap == null,
        ),
      ),
    ),
  );
}

class BuscadorRfeg extends StatefulWidget {
  const BuscadorRfeg({super.key, required this.inicial, required this.onElegir});
  final String inicial;
  final Future<void> Function(JugadorRfeg) onElegir;

  @override
  State<BuscadorRfeg> createState() => BuscadorRfegState();
}

class BuscadorRfegState extends State<BuscadorRfeg> {
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
