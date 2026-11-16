import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Datos personales y torneos marcados, guardados solo en el móvil.
class Perfil {
  const Perfil({
    this.nombre = '',
    this.club = '',
    this.licencia = '',
    this.handicap,
    this.handicapActualizado,
  });

  final String nombre;
  final String club;
  final String licencia;
  final double? handicap;
  final String? handicapActualizado; // AAAA-MM-DD de la última consulta/edición

  Perfil copyWith({String? nombre, String? club, String? licencia, double? handicap, String? handicapActualizado, bool borrarHandicap = false}) =>
      Perfil(
        nombre: nombre ?? this.nombre,
        club: club ?? this.club,
        licencia: licencia ?? this.licencia,
        handicap: borrarHandicap ? null : (handicap ?? this.handicap),
        handicapActualizado: borrarHandicap ? null : (handicapActualizado ?? this.handicapActualizado),
      );

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'club': club,
        'licencia': licencia,
        if (handicap != null) 'handicap': handicap,
        if (handicapActualizado != null) 'handicap_actualizado': handicapActualizado,
      };

  factory Perfil.fromJson(Map<String, dynamic> j) => Perfil(
        nombre: j['nombre'] as String? ?? '',
        club: j['club'] as String? ?? '',
        licencia: j['licencia'] as String? ?? '',
        handicap: (j['handicap'] as num?)?.toDouble(),
        handicapActualizado: j['handicap_actualizado'] as String?,
      );

  bool get vacio => nombre.isEmpty && club.isEmpty && licencia.isEmpty && handicap == null;

  /// Iniciales para el avatar.
  String get iniciales {
    final partes = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first.substring(0, 1) + partes.last.substring(0, 1)).toUpperCase();
  }
}

class PerfilState extends ChangeNotifier {
  static const _kPerfil = 'perfil';
  static const _kInscritos = 'inscritos';

  Perfil _perfil = const Perfil();
  Set<String> _inscritos = {};
  bool _cargado = false;

  Perfil get perfil => _perfil;
  Set<String> get inscritos => Set.unmodifiable(_inscritos);
  bool get cargado => _cargado;

  bool estaInscrito(String id) => _inscritos.contains(id);

  Future<void> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPerfil);
    if (raw != null) {
      try {
        _perfil = Perfil.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (e) {
        debugPrint('perfil ilegible: $e');
      }
    }
    _inscritos = (prefs.getStringList(_kInscritos) ?? const []).toSet();
    _cargado = true;
    notifyListeners();
  }

  Future<void> guardar(Perfil p) async {
    _perfil = p;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPerfil, jsonEncode(p.toJson()));
  }

  Future<void> setInscrito(String id, bool inscrito) async {
    if (inscrito) {
      _inscritos.add(id);
    } else {
      _inscritos.remove(id);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kInscritos, _inscritos.toList()..sort());
  }

  Future<void> toggleInscrito(String id) => setInscrito(id, !_inscritos.contains(id));
}
