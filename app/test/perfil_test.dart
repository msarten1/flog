import 'package:flog/state/perfil_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Perfil: iniciales y simetría JSON', () {
    const p = Perfil(nombre: 'Manuel Sarten', club: 'Alenda Golf', licencia: '0300012345', handicap: 18.2, handicapActualizado: '2026-11-16');
    expect(p.iniciales, 'MS');
    expect(Perfil.fromJson(p.toJson()).toJson(), p.toJson());
    expect(const Perfil().vacio, isTrue);
    expect(const Perfil(nombre: 'Ana').iniciales, 'A');
  });
}
