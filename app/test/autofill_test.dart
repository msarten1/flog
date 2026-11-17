import 'package:flog/services/autofill_js.dart';
import 'package:flog/state/perfil_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('los datos del perfil se separan en nombre y apellidos', () {
    const p = Perfil(nombre: 'Manuel Sartén Pérez', licencia: '0300012345', email: 'm@x.com', club: 'Alenda Golf', handicap: 18.25);
    final d = AutofillJs.datos(p);
    expect(d['nombre'], 'Manuel');
    expect(d['apellidos'], 'Sartén Pérez');
    expect(d['nombreCompleto'], 'Manuel Sartén Pérez');
    expect(d['licencia'], '0300012345');
    expect(d['handicap'], '18.3');
  });

  test('el script incrusta los datos escapados y nunca toca contraseñas', () {
    const p = Perfil(nombre: 'Ana "La Pro" O\'Neil', licencia: '12345');
    final js = AutofillJs.script(p);
    expect(js, contains(r'Ana \"La Pro\" O'));
    expect(js, contains("'password'"));
    expect(js, contains('MutationObserver'));
    expect(js, contains(AutofillJs.canal));
  });
}
