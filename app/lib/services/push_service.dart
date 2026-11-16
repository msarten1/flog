import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config.dart';
import '../firebase_options.dart';

/// Manejador de mensajes en segundo plano (debe ser una función de nivel superior).
@pragma('vm:entry-point')
Future<void> flogBackgroundHandler(RemoteMessage message) async {
  // FCM ya muestra la notificación del sistema; no hay nada que hacer aquí.
}

/// Notificaciones push por provincia (temas de FCM) + notificaciones locales.
class PushService extends ChangeNotifier {
  static const _kProvincias = 'push_provincias';
  static const _kPreguntado = 'push_preguntado';
  static const _kSemanal = 'push_semanal';

  final _local = FlutterLocalNotificationsPlugin();
  final _abrir = StreamController<String?>.broadcast();

  bool _configurado = false;
  bool _permiso = false;
  bool _preguntado = false;
  Set<String> _provincias = {};
  bool _semanal = false;
  String? _token;
  String? _errorConfig;

  /// Firebase está inicializado (hay `firebase_options.dart` real).
  bool get configurado => _configurado;
  bool get permiso => _permiso;
  bool get preguntado => _preguntado;
  Set<String> get provincias => Set.unmodifiable(_provincias);

  /// true = resumen los lunes; false = aviso el mismo día.
  bool get semanal => _semanal;
  String? get token => _token;
  String? get errorConfig => _errorConfig;

  /// Emite el id de torneo (o null) cuando el usuario toca una notificación.
  Stream<String?> get alAbrir => _abrir.stream;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _provincias = (prefs.getStringList(_kProvincias) ?? const []).toSet();
    _preguntado = prefs.getBool(_kPreguntado) ?? false;
    _semanal = prefs.getBool(_kSemanal) ?? false;

    await _initLocal();

    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      _configurado = true;
    } catch (e) {
      _configurado = false;
      _errorConfig = e.toString();
      debugPrint('Firebase no inicializado: $e');
      notifyListeners();
      return;
    }

    FirebaseMessaging.onBackgroundMessage(flogBackgroundHandler);
    final fm = FirebaseMessaging.instance;
    final settings = await fm.getNotificationSettings();
    _permiso = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    FirebaseMessaging.onMessage.listen(_mostrarEnPrimerPlano);
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _abrir.add(_idDe(m.data)));
    final inicial = await fm.getInitialMessage();
    if (inicial != null) _abrir.add(_idDe(inicial.data));

    fm.onRegistered.listen((token) {
      _token = token;
      debugPrint('FCM token: $_token');
      notifyListeners();
    });
    try {
      await fm.register();
    } catch (e) {
      debugPrint('registro FCM: $e');
    }

    // Reaplica las suscripciones guardadas (es idempotente).
    unawaited(_sincronizarTemas());
    notifyListeners();
  }

  Future<void> _initLocal() async {
    const android = AndroidInitializationSettings('ic_notification');
    const ios = DarwinInitializationSettings();
    await _local.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (r) => _abrir.add(r.payload?.isEmpty == true ? null : r.payload),
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            FlogConfig.canalNotificaciones,
            'Torneos nuevos y cambios',
            description: 'Avisos semanales de torneos de golf amateur',
            importance: Importance.high,
          ),
        );
  }

  String? _idDe(Map<String, dynamic> data) {
    final ids = data['ids'] as String?;
    if (ids == null || ids.isEmpty) return null;
    return ids.split(',').first;
  }

  Future<void> _mostrarEnPrimerPlano(RemoteMessage m) async {
    final n = m.notification;
    if (n == null) return;
    await _local.show(
      id: m.hashCode & 0x7fffffff,
      title: n.title,
      body: n.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          FlogConfig.canalNotificaciones,
          'Torneos nuevos y cambios',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
          styleInformation: BigTextStyleInformation(''),
        ),
      ),
      payload: _idDe(m.data) ?? '',
    );
  }

  /// Pide permiso de notificaciones (Android 13+ / iOS). Devuelve si se concedió.
  Future<bool> pedirPermiso() async {
    final prefs = await SharedPreferences.getInstance();
    _preguntado = true;
    await prefs.setBool(_kPreguntado, true);
    if (_configurado) {
      final s = await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
      _permiso = s.authorizationStatus == AuthorizationStatus.authorized ||
          s.authorizationStatus == AuthorizationStatus.provisional;
    } else {
      final android = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      _permiso = await android?.requestNotificationsPermission() ?? false;
    }
    notifyListeners();
    return _permiso;
  }

  String _tema(String base) => _semanal ? '$base${FlogConfig.sufijoSemanal}' : base;

  /// Deja suscritos exactamente los temas que tocan (provincias elegidas y frecuencia)
  /// y da de baja la variante contraria.
  Future<void> _sincronizarTemas() async {
    if (!_configurado) return;
    final fm = FirebaseMessaging.instance;
    final bases = [for (final p in _provincias) FlogConfig.topics[p]!, if (_provincias.isNotEmpty) FlogConfig.topicGlobal];
    final todas = [...FlogConfig.topics.values, FlogConfig.topicGlobal];
    try {
      for (final base in todas) {
        final diario = base;
        final semanal = '$base${FlogConfig.sufijoSemanal}';
        final activo = bases.contains(base) ? _tema(base) : null;
        for (final t in [diario, semanal]) {
          if (t == activo) {
            await fm.subscribeToTopic(t);
          } else {
            await fm.unsubscribeFromTopic(t);
          }
        }
      }
    } catch (e) {
      debugPrint('sincronizar temas: $e');
    }
  }

  Future<void> setProvincia(String provincia, bool activa) async {
    if (!FlogConfig.topics.containsKey(provincia)) return;
    if (activa && !_permiso) {
      await pedirPermiso();
    }
    if (activa) {
      _provincias.add(provincia);
    } else {
      _provincias.remove(provincia);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kProvincias, _provincias.toList()..sort());
    notifyListeners();
    await _sincronizarTemas();
  }

  Future<void> setSemanal(bool semanal) async {
    if (_semanal == semanal) return;
    _semanal = semanal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSemanal, semanal);
    notifyListeners();
    await _sincronizarTemas();
  }

  /// Notificación local de prueba.
  Future<void> probar() async {
    if (!_permiso) await pedirPermiso();
    await _local.show(
      id: 1,
      title: 'Flog · prueba',
      body: 'Así te avisaremos cuando se anuncien torneos nuevos.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          FlogConfig.canalNotificaciones,
          'Torneos nuevos y cambios',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
        ),
      ),
      payload: '',
    );
  }

  @override
  void dispose() {
    _abrir.close();
    super.dispose();
  }
}
