import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/dates.dart';
import '../../core/theme.dart';
import '../../services/acciones.dart';
import '../../services/push_service.dart';
import '../../state/torneos_state.dart';

class AvisosPage extends StatelessWidget {
  const AvisosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final push = context.watch<PushService>();
    final s = context.watch<TorneosState>();
    final text = Theme.of(context).textTheme;
    final suave = context.flog.textoSuave;
    final cambios = s.cambios;

    return Scaffold(
      appBar: AppBar(title: const Text('Avisos')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Avísame de torneos nuevos', style: text.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Cada mañana se revisan las webs de la Federación y de los clubes. Si hay torneos nuevos o cambios en las provincias que elijas, recibirás una notificación.',
                    style: text.bodyMedium?.copyWith(color: suave),
                  ),
                  const SizedBox(height: 8),
                  for (final p in FlogConfig.provincias)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(p, style: text.titleMedium),
                      value: push.provincias.contains(p),
                      onChanged: (v) => push.setProvincia(p, v),
                    ),
                  if (!push.configurado)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Las notificaciones push se activarán en la próxima versión de la app. Tus preferencias quedan guardadas.',
                        style: text.labelMedium?.copyWith(color: FlogColors.dorado),
                      ),
                    )
                  else if (push.preguntado && !push.permiso)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Las notificaciones están desactivadas para Flog en los ajustes del móvil. Actívalas para recibir los avisos.',
                        style: text.labelMedium?.copyWith(color: FlogColors.aviso),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () async {
                        await push.probar();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notificación de prueba enviada')),
                          );
                        }
                      },
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: const Text('Probar notificación'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (cambios != null) _Novedades(cambios: cambios) else const SizedBox.shrink(),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fuentes', style: text.titleMedium),
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

class _Novedades extends StatelessWidget {
  const _Novedades({required this.cambios});
  final dynamic cambios;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final suave = context.flog.textoSuave;
    final nuevos = cambios.nuevos as List<Map<String, dynamic>>;
    final cambiados = cambios.cambios as List<Map<String, dynamic>>;
    final cierran = cambios.inscripcionesCierran as List<Map<String, dynamic>>;
    final fecha = Fechas.parse(cambios.fecha as String);

    Widget fila(Map<String, dynamic> t, {String? extra}) => InkWell(
          onTap: () => context.push('/torneo/${t['id']}'),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 52,
                  child: Text(Fechas.corta(Fechas.parse(t['fecha'] as String)), style: text.labelMedium?.copyWith(color: FlogColors.verde700)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t['nombre'] as String, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      Text('${t['club']} · ${t['provincia']}${extra != null ? ' · $extra' : ''}', style: text.labelMedium?.copyWith(color: suave, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Última revisión · ${Fechas.corta(fecha)}', style: text.titleMedium),
            const SizedBox(height: 8),
            if (nuevos.isEmpty && cambiados.isEmpty)
              Text('Sin torneos nuevos ni cambios.', style: text.bodyMedium?.copyWith(color: suave)),
            if (nuevos.isNotEmpty) ...[
              Text('Nuevos', style: text.labelMedium?.copyWith(color: suave)),
              for (final t in nuevos) fila(t),
            ],
            if (cambiados.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Cambios', style: text.labelMedium?.copyWith(color: suave)),
              for (final t in cambiados) fila(t, extra: t['cambio'] as String?),
            ],
            if (cierran.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Inscripciones que cierran pronto', style: text.labelMedium?.copyWith(color: suave)),
              for (final t in cierran)
                fila(t, extra: t['cierre'] != null ? 'cierra el ${Fechas.corta(Fechas.parse(t['cierre'] as String))}' : null),
            ],
          ],
        ),
      ),
    );
  }
}
