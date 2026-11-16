/// Utilidades de fechas en español sin depender de la inicialización de intl.
class Fechas {
  Fechas._();

  static const List<String> meses = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];
  static const List<String> mesesCortos = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];
  static const List<String> dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
  static const List<String> diasLargos = [
    'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo',
  ];

  /// 'AAAA-MM-DD' → DateTime (local, a medianoche).
  static DateTime parse(String iso) {
    final p = iso.split('-').map(int.parse).toList();
    return DateTime(p[0], p[1], p[2]);
  }

  static String iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime hoy() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// 19 dic
  static String corta(DateTime d) => '${d.day} ${mesesCortos[d.month - 1]}';

  /// sábado 19 de diciembre
  static String larga(DateTime d) =>
      '${diasLargos[d.weekday - 1]} ${d.day} de ${meses[d.month - 1]}';

  /// 19 de diciembre de 2026
  static String completa(DateTime d) => '${d.day} de ${meses[d.month - 1]} de ${d.year}';

  /// Diciembre 2026
  static String mesAnio(DateTime d) {
    final m = meses[d.month - 1];
    return '${m[0].toUpperCase()}${m.substring(1)} ${d.year}';
  }

  static String diaSemana(DateTime d) => dias[d.weekday - 1];

  static bool mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// "hoy", "mañana", "en 5 días", "en 3 semanas"
  static String relativo(DateTime d) {
    final diff = d.difference(hoy()).inDays;
    if (diff < 0) return 'pasado';
    if (diff == 0) return 'hoy';
    if (diff == 1) return 'mañana';
    if (diff < 14) return 'en $diff días';
    if (diff < 60) return 'en ${(diff / 7).round()} semanas';
    return 'en ${(diff / 30).round()} meses';
  }
}
