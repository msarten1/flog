import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../models/torneo.dart';
import '../../services/autofill_js.dart';
import '../../state/perfil_state.dart';
import '../../state/torneos_state.dart';
import '../../widgets/comunes.dart';

/// Inscripción asistida: la web de inscripción dentro de Flog, con la sesión
/// recordada y los datos del perfil rellenados automáticamente.
class InscripcionPage extends StatelessWidget {
  const InscripcionPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<TorneosState>();
    final t = s.porId(id);
    if (t == null) {
      return Scaffold(appBar: AppBar(), body: const EstadoVacio(titulo: 'Torneo no encontrado', icono: Icons.search_off));
    }
    final url = t.enlacePrincipal;
    if (url == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inscripción')),
        body: const EstadoVacio(titulo: 'Este torneo no tiene enlace de inscripción', texto: 'Consulta con el club.', icono: Icons.link_off),
      );
    }
    final host = Uri.tryParse(url)?.host ?? '';
    if (FlogConfig.hostsAppFederacion.any((h) => host.endsWith(h))) {
      return _InscripcionFederacion(torneo: t, url: url);
    }
    return _WebInscripcion(torneo: t, url: url);
  }
}

/// La Federación inscribe desde su app Mi LV: no hay formulario web.
class _InscripcionFederacion extends StatelessWidget {
  const _InscripcionFederacion({required this.torneo, required this.url});
  final Torneo torneo;
  final String url;

  @override
  Widget build(BuildContext context) {
    final ps = context.watch<PerfilState>();
    final text = Theme.of(context).textTheme;
    final suave = context.flog.textoSuave;
    return Scaffold(
      appBar: AppBar(title: const Text('Inscripción')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(torneo.nombre, style: text.headlineSmall),
          const SizedBox(height: 6),
          Text('${torneo.club} · ${torneo.provincia}', style: text.bodyMedium?.copyWith(color: suave)),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.phone_android, color: FlogColors.verde700),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Se inscribe desde la app Mi LV de la Federación', style: text.titleMedium)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Las competiciones federativas solo admiten inscripción con tu usuario de la Federación en la app Mi LV. Abre la app, busca el torneo y, cuando termines, vuelve aquí y márcalo como inscrito.',
                    style: text.bodyMedium?.copyWith(color: suave),
                  ),
                  if (torneo.inscripcion != null) ...[
                    const SizedBox(height: 10),
                    Text(torneo.inscripcion!, style: text.bodyMedium),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => launchUrl(Uri.parse(FlogConfig.miLvPlayStore), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Abrir Mi LV'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.description_outlined),
            label: const Text('Ver ficha en golfcv.com'),
          ),
          if (ps.perfil.licencia.isNotEmpty) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: ps.perfil.licencia));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Licencia ${ps.perfil.licencia} copiada')));
                }
              },
              icon: const Icon(Icons.copy),
              label: Text('Copiar licencia ${ps.perfil.licencia}'),
            ),
          ],
          const SizedBox(height: 24),
          _BarraInscrito(torneo: torneo),
        ],
      ),
    );
  }
}

class _WebInscripcion extends StatefulWidget {
  const _WebInscripcion({required this.torneo, required this.url});
  final Torneo torneo;
  final String url;

  @override
  State<_WebInscripcion> createState() => _WebInscripcionState();
}

class _WebInscripcionState extends State<_WebInscripcion> {
  late final WebViewController _web;
  double _progreso = 0;
  String? _rellenado;
  bool _avisoPerfil = false;

  @override
  void initState() {
    super.initState();
    final perfil = context.read<PerfilState>().perfil;
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(null)
      ..addJavaScriptChannel(
        AutofillJs.canal,
        onMessageReceived: (m) {
          if (!mounted) return;
          setState(() => _rellenado = m.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progreso = p / 100),
          onPageFinished: (_) {
            setState(() => _progreso = 1);
            if (perfil.listoParaInscribir) {
              _web.runJavaScript(AutofillJs.script(perfil));
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
    _avisoPerfil = !perfil.listoParaInscribir;
  }

  @override
  Widget build(BuildContext context) {
    final ps = context.watch<PerfilState>();
    final text = Theme.of(context).textTheme;
    final tokens = context.flog;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.torneo.nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleMedium?.copyWith(color: Colors.white)),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              switch (v) {
                case 'licencia':
                  await Clipboard.setData(ClipboardData(text: ps.perfil.licencia));
                  _aviso('Licencia copiada');
                case 'nombre':
                  await Clipboard.setData(ClipboardData(text: ps.perfil.nombre));
                  _aviso('Nombre copiado');
                case 'email':
                  await Clipboard.setData(ClipboardData(text: ps.perfil.email));
                  _aviso('Email copiado');
                case 'rellenar':
                  await _web.runJavaScript(AutofillJs.script(ps.perfil));
                case 'navegador':
                  final actual = await _web.currentUrl() ?? widget.url;
                  await launchUrl(Uri.parse(actual), mode: LaunchMode.externalApplication);
                case 'recargar':
                  await _web.reload();
              }
            },
            itemBuilder: (_) => [
              if (ps.perfil.licencia.isNotEmpty) const PopupMenuItem(value: 'licencia', child: Text('Copiar licencia')),
              if (ps.perfil.nombre.isNotEmpty) const PopupMenuItem(value: 'nombre', child: Text('Copiar nombre')),
              if (ps.perfil.email.isNotEmpty) const PopupMenuItem(value: 'email', child: Text('Copiar email')),
              if (ps.perfil.listoParaInscribir) const PopupMenuItem(value: 'rellenar', child: Text('Rellenar con mis datos')),
              const PopupMenuItem(value: 'navegador', child: Text('Abrir en el navegador')),
              const PopupMenuItem(value: 'recargar', child: Text('Recargar')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: _progreso < 1
              ? LinearProgressIndicator(value: _progreso, minHeight: 3, color: FlogColors.lima, backgroundColor: Colors.transparent)
              : const SizedBox(height: 3),
        ),
      ),
      body: Column(
        children: [
          if (_avisoPerfil)
            Material(
              color: FlogColors.dorado.withValues(alpha: 0.14),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.person_outline, color: FlogColors.dorado),
                title: const Text('Sin perfil no puedo rellenar el formulario por ti.'),
                trailing: TextButton(onPressed: () => context.go('/perfil'), child: const Text('Completar')),
              ),
            ),
          if (_rellenado != null)
            Container(
              width: double.infinity,
              color: FlogColors.lima.withValues(alpha: 0.35),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                'Rellenado con tu perfil: ${_rellenado!.split(',').toSet().join(', ')}',
                style: text.labelMedium?.copyWith(color: FlogColors.verde900),
              ),
            ),
          Expanded(child: WebViewWidget(controller: _web)),
          Container(
            decoration: BoxDecoration(color: tokens.superficie, border: Border(top: BorderSide(color: tokens.linea))),
            padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + MediaQuery.paddingOf(context).bottom),
            child: _BarraInscrito(torneo: widget.torneo),
          ),
        ],
      ),
    );
  }

  void _aviso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

/// "Ya me he inscrito" / "Lo haré después".
class _BarraInscrito extends StatelessWidget {
  const _BarraInscrito({required this.torneo});
  final Torneo torneo;

  @override
  Widget build(BuildContext context) {
    final ps = context.watch<PerfilState>();
    final inscrito = ps.estaInscrito(torneo.id);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
            child: const Text('Después'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: () async {
              await ps.setInscrito(torneo.id, true);
              if (context.mounted) {
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${torneo.nombre}: marcado como inscrito')),
                );
              }
            },
            style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
            icon: Icon(inscrito ? Icons.check_circle : Icons.how_to_reg_outlined),
            label: Text(inscrito ? 'Ya está marcado' : 'Ya me he inscrito'),
          ),
        ),
      ],
    );
  }
}
