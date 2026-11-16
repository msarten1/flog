import 'dart:convert';
import 'dart:io';

import 'package:flog/core/dates.dart';
import 'package:flog/models/catalogo.dart';
import 'package:flog/models/torneo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final raw = File('assets/data/torneos.json').readAsStringSync();
  final catalogo = Catalogo.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  test('la semilla se parsea y tiene torneos', () {
    expect(catalogo.torneos, isNotEmpty);
    expect(catalogo.actualizado, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    for (final t in catalogo.torneos) {
      expect(['Alicante', 'Valencia', 'Castellón'], contains(t.provincia));
      expect(['Federación', 'Club', 'Circuito', 'Nacional en la CV'], contains(t.tipo));
    }
  });

  test('toJson/fromJson es simétrico', () {
    for (final t in catalogo.torneos) {
      final copia = Torneo.fromJson(t.toJson());
      expect(copia.toJson(), equals(t.toJson()));
    }
  });

  test('fechas y cobertura de días', () {
    const t = Torneo(
      id: 'x',
      fecha: '2026-11-27',
      fechaFin: '2026-11-29',
      nombre: 'Cto Absoluto',
      club: 'Font del Llop',
      provincia: 'Alicante',
      tipo: 'Federación',
    );
    expect(t.esMultidia, isTrue);
    expect(t.cubre(DateTime(2026, 11, 28)), isTrue);
    expect(t.cubre(DateTime(2026, 11, 30)), isFalse);
    expect(t.fechasTexto, '27–29 nov');
    expect(Fechas.larga(t.inicio), 'viernes 27 de noviembre');
  });

  test('búsqueda ignora acentos y mayúsculas', () {
    const t = Torneo(
      id: 'x',
      fecha: '2026-12-20',
      nombre: 'Torneo de Navidad Mediterráneo Golf',
      club: 'Mediterráneo Golf',
      provincia: 'Castellón',
      tipo: 'Club',
    );
    expect(t.coincide('mediterraneo'), isTrue);
    expect(t.coincide('CASTELLON'), isTrue);
    expect(t.coincide('alicante'), isFalse);
  });

  test('esNuevo depende de la fecha de actualización', () {
    const t = Torneo(
      id: 'x',
      fecha: '2026-12-20',
      nombre: 'T',
      club: 'C',
      provincia: 'Valencia',
      tipo: 'Club',
      anadido: '2026-11-16',
    );
    expect(t.esNuevo(DateTime(2026, 11, 16)), isTrue);
    expect(t.esNuevo(DateTime(2026, 11, 30)), isFalse);
  });
}
