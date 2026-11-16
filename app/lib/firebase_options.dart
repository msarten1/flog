// Marcador de posición. Sustituir ejecutando en app/:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=<id-del-proyecto-firebase> --platforms=android
//
// Eso genera este fichero con las claves reales y android/app/google-services.json.
// Mientras tanto la app arranca sin notificaciones push.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform =>
      throw UnsupportedError('Firebase no configurado: ejecuta `flutterfire configure` (ver app/README.md)');
}
