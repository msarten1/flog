/// Configuración de la app.
class FlogConfig {
  FlogConfig._();

  static const String appName = 'Flog';

  /// Repositorio con los datos. Se publica desde GitHub Actions.
  static const String repo = 'msarten1/flog';

  static const String torneosUrl =
      'https://raw.githubusercontent.com/$repo/main/data/torneos.json';
  static const String cambiosUrl =
      'https://raw.githubusercontent.com/$repo/main/data/changes.json';

  static const List<String> provincias = ['Alicante', 'Valencia', 'Castellón'];

  /// Temas de Firebase Cloud Messaging (deben coincidir con el scraper).
  static const Map<String, String> topics = {
    'Alicante': 'prov-alicante',
    'Valencia': 'prov-valencia',
    'Castellón': 'prov-castellon',
  };
  static const String topicGlobal = 'todos';

  static const String canalNotificaciones = 'flog_torneos';
}
