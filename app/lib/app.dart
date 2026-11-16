import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'core/config.dart';
import 'core/theme.dart';
import 'features/avisos/avisos_page.dart';
import 'features/calendario/calendario_page.dart';
import 'features/perfil/perfil_page.dart';
import 'features/torneos/detalle_page.dart';
import 'features/torneos/torneos_page.dart';
import 'services/push_service.dart';

final _rootKey = GlobalKey<NavigatorState>();

final GoRouter flogRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/torneos',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _Shell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/torneos', builder: (_, _) => const TorneosPage())]),
        StatefulShellBranch(routes: [GoRoute(path: '/calendario', builder: (_, _) => const CalendarioPage())]),
        StatefulShellBranch(routes: [GoRoute(path: '/avisos', builder: (_, _) => const AvisosPage())]),
        StatefulShellBranch(routes: [GoRoute(path: '/perfil', builder: (_, _) => const PerfilPage())]),
      ],
    ),
    GoRoute(
      path: '/torneo/:id',
      parentNavigatorKey: _rootKey,
      builder: (_, state) => DetallePage(id: state.pathParameters['id']!),
    ),
  ],
);

class FlogApp extends StatefulWidget {
  const FlogApp({super.key});

  @override
  State<FlogApp> createState() => _FlogAppState();
}

class _FlogAppState extends State<FlogApp> {
  StreamSubscription<String?>? _sub;

  @override
  void initState() {
    super.initState();
    // Al tocar una notificación: abrir el torneo o la pestaña de avisos.
    _sub = context.read<PushService>().alAbrir.listen((id) {
      if (id != null && id.isNotEmpty) {
        flogRouter.push('/torneo/$id');
      } else {
        flogRouter.go('/avisos');
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: FlogConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: FlogTheme.claro,
      darkTheme: FlogTheme.oscuro,
      themeMode: ThemeMode.system,
      routerConfig: flogRouter,
      locale: const Locale('es', 'ES'),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.sports_golf_outlined), selectedIcon: Icon(Icons.sports_golf), label: 'Torneos'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Calendario'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Avisos'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
