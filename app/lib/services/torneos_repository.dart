import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config.dart';
import '../models/catalogo.dart';

/// Resultado de una carga: de dónde salió y si hubo red.
enum OrigenDatos { red, cache, semilla }

class CargaCatalogo {
  const CargaCatalogo(this.catalogo, this.origen, {this.error});
  final Catalogo catalogo;
  final OrigenDatos origen;
  final Object? error;
}

/// Lee `torneos.json`: primero la copia local (o la semilla incluida en la
/// app) y después la red, con ETag para no descargar si no hay cambios.
class TorneosRepository {
  TorneosRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _kEtag = 'torneos_etag';
  static const _kCambiosEtag = 'cambios_etag';
  static const _kNovedadesEtag = 'novedades_etag';

  Future<File> _archivo(String nombre) async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$nombre');
  }

  Future<Catalogo?> leerLocal() async {
    try {
      final f = await _archivo('torneos.json');
      if (await f.exists()) {
        return Catalogo.fromJson(jsonDecode(await f.readAsString()) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('cache torneos ilegible: $e');
    }
    return null;
  }

  Future<Catalogo> leerSemilla() async {
    final raw = await rootBundle.loadString('assets/data/torneos.json');
    return Catalogo.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Devuelve la mejor copia disponible sin red (caché o semilla).
  Future<CargaCatalogo> cargarOffline() async {
    final local = await leerLocal();
    if (local != null) return CargaCatalogo(local, OrigenDatos.cache);
    return CargaCatalogo(await leerSemilla(), OrigenDatos.semilla);
  }

  /// Descarga la versión remota. Devuelve `null` si no ha cambiado (304).
  Future<Catalogo?> descargar() async {
    final prefs = await SharedPreferences.getInstance();
    final etag = prefs.getString(_kEtag);
    final headers = <String, String>{
      'Accept': 'application/json',
      'If-None-Match': ?etag,
    };
    final uri = Uri.parse('${FlogConfig.torneosUrl}?t=${DateTime.now().millisecondsSinceEpoch ~/ 300000}');
    final r = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 20));
    if (r.statusCode == 304) return null;
    if (r.statusCode != 200) {
      throw HttpException('HTTP ${r.statusCode}', uri: uri);
    }
    final body = utf8.decode(r.bodyBytes);
    final cat = Catalogo.fromJson(jsonDecode(body) as Map<String, dynamic>);
    final f = await _archivo('torneos.json');
    await f.writeAsString(body, flush: true);
    final nuevoEtag = r.headers['etag'];
    if (nuevoEtag != null) await prefs.setString(_kEtag, nuevoEtag);
    return cat;
  }

  Future<Cambios?> descargarCambios() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final etag = prefs.getString(_kCambiosEtag);
      final r = await _client
          .get(Uri.parse(FlogConfig.cambiosUrl), headers: {'If-None-Match': ?etag})
          .timeout(const Duration(seconds: 20));
      if (r.statusCode == 304) return await leerCambiosLocal();
      if (r.statusCode != 200) return await leerCambiosLocal();
      final body = utf8.decode(r.bodyBytes);
      final f = await _archivo('changes.json');
      await f.writeAsString(body, flush: true);
      final nuevoEtag = r.headers['etag'];
      if (nuevoEtag != null) await prefs.setString(_kCambiosEtag, nuevoEtag);
      return Cambios.fromJson(jsonDecode(body) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('changes.json no disponible: $e');
      return leerCambiosLocal();
    }
  }

  Future<Novedades?> descargarNovedades() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final etag = prefs.getString(_kNovedadesEtag);
      final r = await _client
          .get(Uri.parse(FlogConfig.novedadesUrl), headers: {'If-None-Match': ?etag})
          .timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) return await leerNovedadesLocal();
      final body = utf8.decode(r.bodyBytes);
      final f = await _archivo('novedades.json');
      await f.writeAsString(body, flush: true);
      final nuevoEtag = r.headers['etag'];
      if (nuevoEtag != null) await prefs.setString(_kNovedadesEtag, nuevoEtag);
      return Novedades.fromJson(jsonDecode(body) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('novedades.json no disponible: $e');
      return leerNovedadesLocal();
    }
  }

  Future<Novedades?> leerNovedadesLocal() async {
    try {
      final f = await _archivo('novedades.json');
      if (await f.exists()) {
        return Novedades.fromJson(jsonDecode(await f.readAsString()) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  Future<Cambios?> leerCambiosLocal() async {
    try {
      final f = await _archivo('changes.json');
      if (await f.exists()) {
        return Cambios.fromJson(jsonDecode(await f.readAsString()) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }
}
