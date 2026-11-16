import '../core/dates.dart';
import 'torneo.dart';

class Fuente {
  const Fuente({required this.nombre, required this.url});
  final String nombre;
  final String url;
}

/// El fichero `torneos.json` completo.
class Catalogo {
  const Catalogo({
    required this.actualizado,
    required this.primera,
    required this.torneos,
    this.nota = '',
    this.fuentes = const [],
  });

  final String actualizado;
  final String primera;
  final List<Torneo> torneos;
  final String nota;
  final List<Fuente> fuentes;

  factory Catalogo.fromJson(Map<String, dynamic> j) => Catalogo(
        actualizado: j['actualizado'] as String,
        primera: j['primera'] as String? ?? j['actualizado'] as String,
        nota: j['nota'] as String? ?? '',
        fuentes: ((j['fuentes'] as List?) ?? const [])
            .map((f) => Fuente(nombre: f['nombre'] as String, url: f['url'] as String))
            .toList(),
        torneos: ((j['torneos'] as List?) ?? const [])
            .map((t) => Torneo.fromJson(t as Map<String, dynamic>))
            .toList(),
      );

  DateTime get fechaActualizado => Fechas.parse(actualizado);

  List<Torneo> get vigentes {
    final l = torneos.where((t) => t.vigente).toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));
    return l;
  }

  Torneo? porId(String id) {
    for (final t in torneos) {
      if (t.id == id) return t;
    }
    return null;
  }
}

/// El fichero `changes.json`.
class Cambios {
  const Cambios({
    required this.fecha,
    this.nuevos = const [],
    this.cambios = const [],
    this.eliminados = const [],
    this.proximos14Dias = const [],
    this.inscripcionesCierran = const [],
  });

  final String fecha;
  final List<Map<String, dynamic>> nuevos;
  final List<Map<String, dynamic>> cambios;
  final List<Map<String, dynamic>> eliminados;
  final List<Map<String, dynamic>> proximos14Dias;
  final List<Map<String, dynamic>> inscripcionesCierran;

  factory Cambios.fromJson(Map<String, dynamic> j) {
    List<Map<String, dynamic>> l(String k) =>
        ((j[k] as List?) ?? const []).cast<Map<String, dynamic>>();
    return Cambios(
      fecha: j['fecha'] as String,
      nuevos: l('nuevos'),
      cambios: l('cambios'),
      eliminados: l('eliminados'),
      proximos14Dias: l('proximos_14_dias'),
      inscripcionesCierran: l('inscripciones_cierran'),
    );
  }
}

/// El fichero `novedades.json`: historial de los últimos días.
class Novedades {
  const Novedades({required this.dias});

  /// [{fecha, nuevos, cambios, eliminados}], más reciente primero.
  final List<Map<String, dynamic>> dias;

  factory Novedades.fromJson(Map<String, dynamic> j) =>
      Novedades(dias: ((j['dias'] as List?) ?? const []).cast<Map<String, dynamic>>());

  /// Nuevos y cambios de los últimos [dias] días, sin repetir ids.
  ({List<Map<String, dynamic>> nuevos, List<Map<String, dynamic>> cambios}) ultimos(int dias) {
    final desde = Fechas.iso(Fechas.hoy().subtract(Duration(days: dias)));
    final nuevos = <String, Map<String, dynamic>>{};
    final cambios = <String, Map<String, dynamic>>{};
    final ordenados = [...this.dias]..sort((a, b) => (a['fecha'] as String).compareTo(b['fecha'] as String));
    for (final d in ordenados) {
      if ((d['fecha'] as String).compareTo(desde) < 0) continue;
      for (final t in ((d['nuevos'] as List?) ?? const []).cast<Map<String, dynamic>>()) {
        nuevos[t['id'] as String] = t;
      }
      for (final t in ((d['cambios'] as List?) ?? const []).cast<Map<String, dynamic>>()) {
        if (!nuevos.containsKey(t['id'])) cambios[t['id'] as String] = t;
      }
    }
    int porFecha(Map<String, dynamic> a, Map<String, dynamic> b) => (a['fecha'] as String).compareTo(b['fecha'] as String);
    return (nuevos: nuevos.values.toList()..sort(porFecha), cambios: cambios.values.toList()..sort(porFecha));
  }
}
