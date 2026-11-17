import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../services/push_service.dart';
import '../../state/perfil_state.dart';
import '../../widgets/buscador_rfeg.dart';

/// Arranque guiado en la primera apertura: bienvenida, avisos y perfil. Sin cuenta.
class BienvenidaPage extends StatefulWidget {
  const BienvenidaPage({super.key});

  @override
  State<BienvenidaPage> createState() => _BienvenidaPageState();
}

class _BienvenidaPageState extends State<BienvenidaPage> {
  final _pages = PageController();
  int _paso = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _ir(int paso) async {
    setState(() => _paso = paso);
    await _pages.animateToPage(paso, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  Future<void> _terminar() async {
    await context.read<PerfilState>().marcarBienvenida();
    if (mounted) context.go('/hoy');
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: FlogColors.verde900,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Paso1(onSeguir: () => _ir(1)),
                  _Paso2(onSeguir: () => _ir(2)),
                  _Paso3(onTerminar: _terminar),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: i == _paso ? 22 : 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: i == _paso ? FlogColors.lima : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  const Spacer(),
                  if (_paso > 0)
                    TextButton(
                      onPressed: _terminar,
                      child: Text('Saltar', style: text.labelLarge?.copyWith(color: Colors.white.withValues(alpha: 0.75))),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Marco extends StatelessWidget {
  const _Marco({required this.titulo, required this.texto, required this.cuerpo, required this.boton});
  final String titulo;
  final String texto;
  final Widget cuerpo;
  final Widget boton;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: cuerpo),
          const SizedBox(height: 20),
          Text(titulo, style: text.displayMedium?.copyWith(color: Colors.white)),
          const SizedBox(height: 10),
          Text(texto, style: text.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.78))),
          const SizedBox(height: 22),
          boton,
        ],
      ),
    );
  }
}

Widget _botonLima(String etiqueta, VoidCallback onPressed, {IconData? icono}) => FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(backgroundColor: FlogColors.lima, foregroundColor: FlogColors.verde900),
      icon: Icon(icono ?? Icons.arrow_forward),
      label: Text(etiqueta),
    );

class _Paso1 extends StatelessWidget {
  const _Paso1({required this.onSeguir});
  final VoidCallback onSeguir;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _Marco(
      titulo: 'Bienvenido a Flog',
      texto: 'Todos los torneos de golf amateur de Alicante, Valencia y Castellón en un calendario que se actualiza cada mañana. Avisos cuando se anuncian y ayuda para inscribirte.',
      cuerpo: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/branding/icon-192.png', width: 200, height: 200),
            const SizedBox(height: 10),
            Text('Flog', style: text.displayLarge?.copyWith(color: Colors.white, fontSize: 56)),
            Text(
              'TORNEOS DE GOLF · COMUNITAT VALENCIANA',
              style: text.labelSmall?.copyWith(color: FlogColors.lima, letterSpacing: 2, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      boton: _botonLima('Empezar', onSeguir),
    );
  }
}

class _Paso2 extends StatelessWidget {
  const _Paso2({required this.onSeguir});
  final VoidCallback onSeguir;

  @override
  Widget build(BuildContext context) {
    final push = context.watch<PushService>();
    final text = Theme.of(context).textTheme;
    return _Marco(
      titulo: '¿De qué zona quieres enterarte?',
      texto: 'Te avisaremos cuando se anuncie un torneo nuevo o cambie uno existente en estas provincias. Se puede cambiar en Configuración.',
      cuerpo: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final p in FlogConfig.provincias)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _Opcion(
                etiqueta: p,
                activa: push.provincias.contains(p),
                onTap: () => push.setProvincia(p, !push.provincias.contains(p)),
              ),
            ),
          const SizedBox(height: 10),
          Text('Frecuencia', style: text.labelMedium?.copyWith(color: Colors.white.withValues(alpha: 0.7))),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Opcion(etiqueta: 'Cada día', activa: !push.semanal, onTap: () => push.setSemanal(false), compacta: true),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Opcion(etiqueta: 'Resumen semanal', activa: push.semanal, onTap: () => push.setSemanal(true), compacta: true),
              ),
            ],
          ),
        ],
      ),
      boton: _botonLima(push.provincias.isEmpty ? 'Sin avisos por ahora' : 'Continuar', onSeguir),
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({required this.etiqueta, required this.activa, required this.onTap, this.compacta = false});
  final String etiqueta;
  final bool activa;
  final VoidCallback onTap;
  final bool compacta;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: activa ? FlogColors.lima : Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: compacta ? 12 : 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  etiqueta,
                  style: (compacta ? text.labelLarge : text.titleMedium)?.copyWith(color: activa ? FlogColors.verde900 : Colors.white),
                ),
              ),
              Icon(activa ? Icons.check_circle : Icons.circle_outlined, color: activa ? FlogColors.verde900 : Colors.white.withValues(alpha: 0.5), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _Paso3 extends StatelessWidget {
  const _Paso3({required this.onTerminar});
  final VoidCallback onTerminar;

  @override
  Widget build(BuildContext context) {
    final ps = context.watch<PerfilState>();
    final text = Theme.of(context).textTheme;
    final p = ps.perfil;
    final listo = !p.vacio;
    return _Marco(
      titulo: listo ? 'Perfecto, ${p.nombre.split(' ').first}' : 'Tu ficha de jugador',
      texto: listo
          ? 'Con tu licencia, Flog rellena por ti los formularios de inscripción y te muestra tu hándicap.'
          : 'Busca tu licencia en la RFEG y Flog rellenará tu nombre, club y hándicap. Lo usa para ayudarte a inscribirte; se guarda solo en tu móvil.',
      cuerpo: Center(
        child: listo
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: FlogColors.lima,
                    child: Text(p.iniciales, style: text.headlineMedium?.copyWith(color: FlogColors.verde900)),
                  ),
                  const SizedBox(height: 14),
                  Text(p.nombre, style: text.titleLarge?.copyWith(color: Colors.white), textAlign: TextAlign.center),
                  Text(
                    [if (p.club.isNotEmpty) p.club, if (p.handicap != null) 'hcp ${p.handicap!.toStringAsFixed(1)}'].join(' · '),
                    style: text.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.75)),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => mostrarBuscadorRfeg(context, ps),
                    child: Text('No soy yo, buscar otra vez', style: TextStyle(color: FlogColors.lima)),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.badge_outlined, size: 96, color: Colors.white.withValues(alpha: 0.85)),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => mostrarBuscadorRfeg(context, ps),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                    icon: const Icon(Icons.person_search_outlined),
                    label: const Text('Buscar mi licencia en la RFEG'),
                  ),
                ],
              ),
      ),
      boton: _botonLima(listo ? 'Entrar en Flog' : 'Ahora no, entrar en Flog', onTerminar, icono: Icons.sports_golf),
    );
  }
}
