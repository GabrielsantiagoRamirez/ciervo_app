import 'package:ciervo_clud/core/logging/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('redacta credenciales conocidas antes de escribir logs', () {
    const jwt = 'abcdefgh.ijklmnop.qrstuvwx';
    final result = sanitizeForLog(
      'Authorization: Bearer secret-token '
      '{"refreshToken":"refresh-secret","pin":"654321","jwt":"$jwt"}',
    );

    expect(result, isNot(contains('secret-token')));
    expect(result, isNot(contains('refresh-secret')));
    expect(result, isNot(contains('654321')));
    expect(result, isNot(contains(jwt)));
  });

  test('redacta token de proveedor, PII y cuerpos de media MOVE', () {
    final result = sanitizeForLog(
      '{"externalProviderToken":"provider-secret",'
      '"firstNames":"Persona Demo","documentNumber":"DEMO0001",'
      '"email":"persona@example.invalid","emergencyPhone":"+573000000001",'
      '"file":"documento-en-bytes"}',
    );

    expect(result, isNot(contains('provider-secret')));
    expect(result, isNot(contains('Persona Demo')));
    expect(result, isNot(contains('DEMO0001')));
    expect(result, isNot(contains('persona@example.invalid')));
    expect(result, isNot(contains('+573000000001')));
    expect(result, isNot(contains('documento-en-bytes')));
    expect(result, contains('externalProviderToken'));
    expect(result, contains('firstNames'));
  });
}
