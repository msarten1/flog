import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../services/acciones.dart';
import '../../services/push_service.dart';
import '../../state/torneos_state.dart';

/// Configuración: avisos, fuentes de datos y versión.
class ConfiguracionPage extends StatelessWidget {
  const ConfiguracionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final push = context.watch<PushService>();
    final s = context.watch<TorneosState>();
    final text = Theme.of(context).textTheme;
    final suave = context.flog.textoSuave;

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Avisos', style: text.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Elige las provincias de las que quieres enterarte cuando se anuncie un torneo o cambie uno existente.',
                    style: text.bodyMedium?.copyWith(color: suave),
                  ),
                  const SizedBox(height: 6),
                  for (final p in FlogConfig.provincias)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(p, style: text.titleMedium),
                      value: push.provincias.contains(p),
                      onChanged: (v) => push.setProvincia(p, v),
                    ),
                  const SizedBox(height: 8),
                  Text('Frecuencia', style: text.labelMedium?.copyWith(color: suave)),
                  const SizedBox(height: 6),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Cada día'), icon: Icon(Icons.bolt_outlined)),
                      ButtonSegment(value: true, label: Text('Resumen semanal'), icon: Icon(Icons.view_week_outlined)),
                    ],
                    selected: {push.semanal},
                    onSelectionChanged: (sel) => push.setSemanal(sel.first),
                    showSelectedIcon: false,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    push.semanal
                        ? 'Un resumen cada lunes con lo nuevo de la semana, más un aviso si una inscripción cierra en dos días o menos.'
                        : 'Un aviso el mismo día en que hay novedades, solo los días que las haya, más un aviso si una inscripción cierra en dos días o menos.',
                    style: text.labelMedium?.copyWith(color: suave, fontWeight: FontWeight.w500),
                  ),
                  if (!push.configurado)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'Las notificaciones push se activarán en la próxima versión. Tus preferencias quedan guardadas.',
                        style: text.labelMedium?.copyWith(color: FlogColors.dorado),
                      ),
                    )
                  else if (push.preguntado && !push.permiso)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'Las notificaciones están desactivadas para Flog en los ajustes del móvil. Actívalas para recibir los avisos.',
                        style: text.labelMedium?.copyWith(color: FlogColors.aviso),
                      ),
                    ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('De dónde salen los torneos', style: text.titleMedium),
                  const SizedBox(height: 6),
                  if (s.catalogo?.nota.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(s.catalogo!.nota, style: text.bodyMedium?.copyWith(color: suave)),
                    ),
                  for (final f in s.catalogo?.fuentes ?? const [])
                    InkWell(
                      onTap: () => Acciones.abrirEnlace(context, f.url),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.link, size: 18, color: FlogColors.verde500),
                            const SizedBox(width: 8),
                            Expanded(child: Text(f.nombre, style: text.bodyMedium)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Privacidad', style: text.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Tu perfil y los torneos que marcas se guardan solo en este móvil. Flog no tiene cuentas ni servidores propios: los datos de torneos se descargan de un fichero público y los avisos llegan por Firebase sin identificarte. Al inscribirte, tus datos se escriben únicamente en la web del organizador que tú abres.',
                    style: text.bodyMedium?.copyWith(color: suave),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (_, snap) => Text(
                'Flog ${snap.data?.version ?? ''}${snap.data != null ? ' (${snap.data!.buildNumber})' : ''}',
                style: text.labelMedium?.copyWith(color: suave),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
