import 'package:ciervo_clud/features/business_nfc/domain/business_nfc_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validate usa sesión y secreto sin campos adicionales', () {
    const command = BusinessNfcValidateCommand(
      sessionId: 41,
      token: 'one-time-secret',
    );

    expect(command.toJson(), {'sessionId': 41, 'token': 'one-time-secret'});
  });

  test('charge manda idempotencia en JSON y conserva la clave en retry', () {
    const command = BusinessNfcChargeCommand(
      sessionId: 41,
      token: 'one-time-secret',
      idempotencyKey: 'c4d7b747-f3a9-4dd7-bfdb-e32584591dd9',
    );

    expect(command.toJson()['idempotencyKey'], command.idempotencyKey);
    expect(command.toJson(), command.toJson());
  });

  test('payload compacto NFC se convierte a credencial tipada', () {
    final credential = BusinessNfcCredential.fromPayload({
      'v': 1,
      's': 41,
      't': 'one-time-secret',
    });

    expect(credential.sessionId, 41);
    expect(credential.token, 'one-time-secret');
  });
}
