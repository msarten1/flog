import '../core/dates.dart';

/// Un torneo del calendario (espejo de `data/torneos.json`).
class Torneo {
  const Torneo({
    required this.id,
    required this.fecha,
    required this.nombre,
    required this.club,
    required this.provincia,
    required this.tipo,
    this.fechaFin,
    this.modalidad,
    this.inscripcion,
    this.precio,
    this.estadoInscripcion,
    this.enlace,
    this.enlaceInscripcion,
    this.fuente,
    this.anadido,
    this.cambio,
    this.revisar = false,
  });

  final String id;
  final String fecha;
  final String? fechaFin;
  final String nombre;
  final String club;
  final String provincia;
  final String tipo;
  final String? modalidad;
  final String? inscripcion;
  final String? precio;
  final String? estadoInscripcion;
  final String? enlace;
  final String? enlaceInscripcion;
  final String? fuente;
  final String? anadido;
  final String? cambio;
  final bool revisar;

  factory Torneo.fromJson(Map<String, dynamic> j) => Torneo(
        id: j['id'] as String,
        fecha: j['fecha'] as String,
        fechaFin: j['fecha_fin'] as String?,
        nombre: j['nombre'] as String,
        club: j['club'] as String? ?? '',
        provincia: j['provincia'] as String? ?? '',
        tipo: j['tipo'] as String? ?? 'Club',
        modalidad: j['modalidad'] as String?,
        inscripcion: j['inscripcion'] as String?,
        precio: j['precio'] as String?,
        estadoInscripcion: j['estado_inscripcion'] as String?,
        enlace: j['enlace'] as String?,
        enlaceInscripcion: j['enlace_inscripcion'] as String?,
        fuente: j['fuente'] as String?,
        anadido: j['anadido'] as String?,
        cambio: j['cambio'] as String?,
        revisar: j['revisar'] == true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fecha': fecha,
        if (fechaFin != null) 'fecha_fin': fechaFin,
        'nombre': nombre,
        'club': club,
        'provincia': provincia,
        'tipo': tipo,
        if (modalidad != null) 'modalidad': modalidad,
        if (inscripcion != null) 'inscripcion': inscripcion,
        if (precio != null) 'precio': precio,
        if (estadoInscripcion != null) 'estado_inscripcion': estadoInscripcion,
        if (enlace != null) 'enlace': enlace,
        if (enlaceInscripcion != null) 'enlace_inscripcion': enlaceInscripcion,
        if (fuente != null) 'fuente': fuente,
        if (anadido != null) 'anadido': anadido,
        if (cambio != null) 'cambio': cambio,
        if (revisar) 'revisar': true,
      };

  DateTime get inicio => Fechas.parse(fecha);
  DateTime get fin => Fechas.parse(fechaFin ?? fecha);
  bool get esMultidia => fechaFin != null && fechaFin != fecha;
  bool get inscripcionAbierta => estadoInscripcion == 'abierta';
  bool get cancelado => (cambio ?? '').toLowerCase().contains('cancel');

  /// Cubre el día `d` (inclusive).
  bool cubre(DateTime d) => !d.isBefore(inicio) && !d.isAfter(fin);

  /// Aún no ha terminado.
  bool get vigente => !fin.isBefore(Fechas.hoy());

  /// Añadido hace menos de [dias] días respecto a la fecha de actualización del catálogo.
  bool esNuevo(DateTime actualizado, {int dias = 7}) {
    if (anadido == null) return false;
    return actualizado.difference(Fechas.parse(anadido!)).inDays < dias;
  }

  /// Enlace preferente para inscribirse / ver la ficha.
  String? get enlacePrincipal => enlaceInscripcion ?? enlace;

  /// Texto de rango de fechas: "19 dic" o "27–29 nov".
  String get fechasTexto {
    if (!esMultidia) return Fechas.corta(inicio);
    if (inicio.month == fin.month) return '${inicio.day}–${Fechas.corta(fin)}';
    return '${Fechas.corta(inicio)} – ${Fechas.corta(fin)}';
  }

  bool coincide(String query) {
    final q = _norm(query);
    if (q.isEmpty) return true;
    return _norm('$nombre $club $provincia ${modalidad ?? ''} $tipo').contains(q);
  }

  static String _norm(String s) {
    const from = 'áéíóúüñÁÉÍÓÚÜÑ';
    const to = 'aeiouunAEIOUUN';
    final b = StringBuffer();
    for (final r in s.runes) {
      final c = String.fromCharCode(r);
      final i = from.indexOf(c);
      b.write(i >= 0 ? to[i] : c);
    }
    return b.toString().toLowerCase().trim();
  }
}
