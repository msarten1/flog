import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/push_service.dart';
import 'services/torneos_repository.dart';
import 'state/perfil_state.dart';
import 'state/torneos_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES');
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light),
  );

  final push = PushService();
  final state = TorneosState(TorneosRepository());
  final perfil = PerfilState();
  perfil.addListener(() => state.setInscritos(perfil.inscritos));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<TorneosState>.value(value: state),
        ChangeNotifierProvider<PushService>.value(value: push),
        ChangeNotifierProvider<PerfilState>.value(value: perfil),
      ],
      child: const FlogApp(),
    ),
  );

  // Sin bloquear el primer frame.
  state.iniciar();
  push.init();
  perfil.cargar();
}
