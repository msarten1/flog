import 'package:flog/services/rfeg_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('JugadorRfeg se construye desde el documento de la RFEG', () {
    final j = JugadorRfeg.fromDocument({
      'full_name': 'FADRIQUE JORDAN DE URRIES GARCIA',
      'guid_licence': '0100058461',
      'club_title': 'CLUB DE GOLF ESCORPIÓN',
      'federation_title': 'FEDERACIÓN DE GOLF DE LA COMUNIDAD VALENCIANA',
      'handicap': '12,4',
      'date_hdc_updated_at': '2026-11-01T00:00:00',
      'is_professional': 0,
    });
    expect(j.nombre, 'Fadrique Jordan de Urries Garcia');
    expect(j.club, 'Club de Golf Escorpión');
    expect(j.handicap, 12.4);
    expect(j.actualizado, '2026-11-01');
    expect(j.profesional, isFalse);
  });

  test('hándicap 99.9 significa sin hándicap', () {
    final j = JugadorRfeg.fromDocument({'full_name': 'X Y', 'guid_licence': '1', 'club_title': '', 'federation_title': '', 'handicap': '99.9'});
    expect(j.handicap, isNull);
  });
}
