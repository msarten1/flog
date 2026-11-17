import 'package:flog/core/dates.dart';
import 'package:flog/models/torneo.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lógica de la pantalla Hoy reproducida sobre el modelo (TorneosState requiere
/// plataforma para el repositorio; aquí se prueban los criterios).
void main() {
  final hoy = Fechas.hoy();
  Torneo t(String id, int dias, {String prov = 'Alicante', String? anadido}) => Torneo(
        id: id,
        fecha: Fechas.iso(hoy.add(Duration(days: dias))),
        nombre: id,
        club: 'C',
        provincia: prov,
        tipo: 'Club',
        anadido: anadido,
      );

  test('relativo y vigencia', () {
    expect(Fechas.relativo(hoy), 'hoy');
    expect(Fechas.relativo(hoy.add(const Duration(days: 1))), 'mañana');
    expect(Fechas.relativo(hoy.add(const Duration(days: 5))), 'en 5 días');
    expect(t('a', -1).vigente, isFalse);
    expect(t('b', 0).vigente, isTrue);
  });

  test('el próximo inscrito es el primero por fecha entre los marcados', () {
    final lista = [t('a', 2), t('b', 4), t('c', 9)]..sort((x, y) => x.fecha.compareTo(y.fecha));
    final inscritos = {'b', 'c'};
    final proximo = lista.firstWhere((x) => inscritos.contains(x.id));
    expect(proximo.id, 'b');
  });

  test('nuevos en provincia', () {
    final actualizado = hoy;
    final lista = [t('a', 2, anadido: Fechas.iso(hoy)), t('b', 4, prov: 'Valencia', anadido: Fechas.iso(hoy)), t('c', 9, anadido: Fechas.iso(hoy.subtract(const Duration(days: 20))))];
    final enAlicante = lista.where((x) => x.esNuevo(actualizado) && x.provincia == 'Alicante').map((x) => x.id);
    expect(enAlicante, ['a']);
  });
}
