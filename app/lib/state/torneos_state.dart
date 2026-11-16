import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/dates.dart';
import '../models/catalogo.dart';
import '../models/torneo.dart';
import '../services/torneos_repository.dart';

/// Estado global: catálogo cargado, filtros y novedades.
class TorneosState extends ChangeNotifier {
  TorneosState(this._repo);

  final TorneosRepository _repo;

  Catalogo? _catalogo;
  Cambios? _cambios;
  Novedades? _novedades;
  OrigenDatos _origen = OrigenDatos.semilla;
  bool _cargando = false;
  bool _sinConexion = false;
  String? _error;

  // Filtros
  String _query = '';
  String _provincia = 'Todas';
  String _tipo = 'Todos';
  bool _soloNuevos = false;

  Catalogo? get catalogo => _catalogo;
  Cambios? get cambios => _cambios;
  Novedades? get novedades => _novedades;
  OrigenDatos get origen => _origen;
  bool get cargando => _cargando;
  bool get sinConexion => _sinConexion;
  String? get error => _error;
  String get query => _query;
  String get provincia => _provincia;
  String get tipo => _tipo;
  bool get soloNuevos => _soloNuevos;
  bool get hayFiltros => _query.isNotEmpty || _provincia != 'Todas' || _tipo != 'Todos' || _soloNuevos;

  /// Carga inicial: local al instante y red después.
  Future<void> iniciar() async {
    final offline = await _repo.cargarOffline();
    _catalogo = offline.catalogo;
    _origen = offline.origen;
    notifyListeners();
    await refrescar();
  }

  Future<void> refrescar() async {
    if (_cargando) return;
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final remoto = await _repo.descargar();
      if (remoto != null) {
        _catalogo = remoto;
        _origen = OrigenDatos.red;
      } else if (_origen == OrigenDatos.semilla) {
        // 304 pero sin copia local (p. ej. tras borrar datos): releer caché.
        final local = await _repo.leerLocal();
        if (local != null) {
          _catalogo = local;
          _origen = OrigenDatos.cache;
        }
      }
      _sinConexion = false;
      _cambios = await _repo.descargarCambios() ?? _cambios;
      _novedades = await _repo.descargarNovedades() ?? _novedades;
    } catch (e) {
      // Un error HTTP (p. ej. 404) no es falta de conexión: se usa la copia local sin avisar.
      _sinConexion = e is! HttpException;
      _error = e.toString();
      debugPrint('refrescar: $e');
      _cambios ??= await _repo.leerCambiosLocal();
      _novedades ??= await _repo.leerNovedadesLocal();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  // ----- filtros -----
  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void setProvincia(String p) {
    _provincia = p;
    notifyListeners();
  }

  void setTipo(String t) {
    _tipo = t;
    notifyListeners();
  }

  void toggleSoloNuevos() {
    _soloNuevos = !_soloNuevos;
    notifyListeners();
  }

  void limpiarFiltros() {
    _query = '';
    _provincia = 'Todas';
    _tipo = 'Todos';
    _soloNuevos = false;
    notifyListeners();
  }

  // ----- consultas -----
  List<Torneo> get vigentes => _catalogo?.vigentes ?? const [];

  List<String> get tiposDisponibles {
    final s = <String>{};
    for (final t in vigentes) {
      s.add(t.tipo);
    }
    const orden = ['Federación', 'Club', 'Circuito', 'Nacional en la CV'];
    final l = s.toList()..sort((a, b) => orden.indexOf(a).compareTo(orden.indexOf(b)));
    return l;
  }

  bool esNuevo(Torneo t) {
    final c = _catalogo;
    if (c == null) return false;
    return t.esNuevo(c.fechaActualizado);
  }

  List<Torneo> get filtrados {
    return vigentes.where((t) {
      if (_provincia != 'Todas' && t.provincia != _provincia) return false;
      if (_tipo != 'Todos' && t.tipo != _tipo) return false;
      if (_soloNuevos && !esNuevo(t)) return false;
      if (!t.coincide(_query)) return false;
      return true;
    }).toList();
  }

  /// Filtrados, agrupados por mes (clave "AAAA-MM") en orden.
  Map<String, List<Torneo>> get filtradosPorMes {
    final m = <String, List<Torneo>>{};
    for (final t in filtrados) {
      m.putIfAbsent(t.fecha.substring(0, 7), () => []).add(t);
    }
    return m;
  }

  /// table_calendar entrega los días en UTC: se normalizan a fecha local.
  static DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);

  List<Torneo> torneosDelDia(DateTime d) {
    final dia = _dia(d);
    return vigentes.where((t) => t.cubre(dia)).toList();
  }

  /// Torneos (vigentes o no) que cubren un día cualquiera: para los puntos del calendario.
  List<Torneo> todosDelDia(DateTime d) {
    final dia = _dia(d);
    return (_catalogo?.torneos ?? const []).where((t) => t.cubre(dia)).toList();
  }

  int get nuevosEstaSemana => vigentes.where(esNuevo).length;

  Torneo? get proximo {
    final hoy = Fechas.hoy();
    for (final t in vigentes) {
      if (!t.inicio.isBefore(hoy)) return t;
    }
    return null;
  }

  Torneo? porId(String id) => _catalogo?.porId(id);
}
