# Flog · app Flutter

Calendario de torneos de golf amateur de la Comunitat Valenciana con avisos push.

## Requisitos

- Flutter stable (3.50 o superior) y Android SDK con `platforms;android-35` y `build-tools;35.0.0`.
  En este Mac: `brew install --cask flutter android-commandlinetools`, luego
  `sdkmanager --sdk_root=/opt/homebrew/share/android-commandlinetools "platform-tools" "platforms;android-35" "build-tools;35.0.0"`
  y `flutter config --android-sdk /opt/homebrew/share/android-commandlinetools`.
- Java 17 o superior (Homebrew `openjdk@21` vale).

## Desarrollo

```bash
flutter pub get
flutter analyze && flutter test
flutter run                      # en un emulador o un móvil con depuración USB
```

Estructura de `lib/`:

```
main.dart                 arranque: Provider, Firebase (si está configurado), locale
app.dart                  go_router con NavigationBar (Hoy · Calendario · Avisos · Perfil), /torneo/:id y /inscribir/:id
core/                     config (URLs, temas FCM), tema (paleta Flog), fechas en español
models/                   Torneo, Catalogo, Cambios (espejo de data/*.json)
services/                 TorneosRepository (caché + ETag), PushService (FCM + locales), Acciones,
                          RfegService (hándicap público), AutofillJs (relleno de formularios)
state/                    TorneosState (filtros, novedades, consultas de Hoy), PerfilState (datos e inscritos)
features/                 pantallas: hoy, calendario, torneos/detalle, inscripcion (WebView asistida), avisos, perfil
widgets/                  fila de agenda, lista, panel de filtros, etiquetas, estados vacíos
```

Tipografía: Fraunces (títulos) e Inter (cuerpo), empaquetadas en `assets/fonts/`.

Los datos se leen de `https://raw.githubusercontent.com/msarten1/flog/main/data/torneos.json`
(constante en `lib/core/config.dart`). La app lleva una copia en `assets/data/torneos.json`
para el primer arranque: actualízala con `cp ../data/torneos.json assets/data/` antes de cada release.

## Notificaciones push (Firebase)

1. Crea un proyecto en https://console.firebase.google.com (por ejemplo "flog").
2. `npm i -g firebase-tools && firebase login` y `dart pub global activate flutterfire_cli`.
3. En `app/`: `flutterfire configure --project=<id> --platforms=android`.
   Genera `lib/firebase_options.dart` (sustituye al marcador) y `android/app/google-services.json`.
4. En Firebase → Configuración del proyecto → Cuentas de servicio → generar clave privada.
   Guarda el JSON como secreto `FCM_SERVICE_ACCOUNT_JSON` del repositorio:
   `gh secret set FCM_SERVICE_ACCOUNT_JSON < clave.json`.
5. Prueba: activa una provincia en la pestaña Avisos y ejecuta en `scraper/`
   `FCM_SERVICE_ACCOUNT_FILE=clave.json .venv/bin/python -m flog_scraper notify --test --topic prov-alicante`.

Sin estos pasos la app compila y funciona; la pestaña Avisos guarda las preferencias
y avisa de que el push llegará en la siguiente versión.

## Icono y splash

Los PNG salen de `branding/*.svg` (`rsvg-convert`, ver `branding/paleta.md`). Para regenerarlos:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## APK para probar

```bash
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

Sin `android/key.properties` el APK va firmado con la clave de debug (suficiente para
instalarlo por enlace o `adb install -r`). Para una firma propia:

```bash
keytool -genkey -v -keystore ~/keys/flog-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias flog
cat > android/key.properties <<EOF
storeFile=/Users/<usuario>/keys/flog-upload.jks
storePassword=...
keyAlias=flog
keyPassword=...
EOF
```

Para Google Play: `flutter build appbundle --release`.
