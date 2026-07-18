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
}
