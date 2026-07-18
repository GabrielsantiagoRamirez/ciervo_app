import 'package:ciervo_clud/features/kids_v2/domain/models/kids_v2_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Kids v2 auth contracts', () {
    test('PIN login sends the documented body', () {
      const command = KidPinLoginCommand(
        username: 'kid_demo',
        pin: '1234',
        deviceId: 'install-uuid',
        platform: 'android',
        appVersion: '2.0.0',
      );

      expect(command.toJson(), {
        'username': 'kid_demo',
        'pin': '1234',
        'firebaseIdToken': null,
        'deviceId': 'install-uuid',
        'platform': 'android',
        'appVersion': '2.0.0',
      });
    });

    test('Firebase login never sends PIN credentials', () {
      const command = KidFirebaseLoginCommand(
        firebaseIdToken: 'firebase-token',
        deviceId: 'install-uuid',
        platform: 'android',
        appVersion: '2.0.0',
      );

      expect(command.toJson()['username'], isNull);
      expect(command.toJson()['pin'], isNull);
      expect(command.toJson()['firebaseIdToken'], 'firebase-token');
    });
  });

  test('payment request carries idempotency in JSON body', () {
    const command = PayForMeCommand(
      payerUserId: 120,
      businessId: 25,
      amount: 28000,
      currency: 'COP',
      description: 'Entrada de cine',
      idempotencyKey: 'payforme-install-uuid-0001',
      chatConversationId: 44,
    );

    final json = command.toJson();
    expect(json['idempotencyKey'], 'payforme-install-uuid-0001');
    expect(json['purpose'], 'PayForMe');
    expect(json['amount'], 28000);
  });

  test('realtime event preserves and tolerantly decodes payloadJson', () {
    final event = KidsRealtimeEvent.fromJson({
      'cursor': 9,
      'type': 'PAYMENT_UPDATED',
      'payloadJson': '{"status":6}',
      'createdAt': '2026-07-18T01:00:00-05:00',
    });

    expect(event.cursor, 9);
    expect(event.payload, {'status': 6});
    expect(event.createdAt.isUtc, isTrue);
  });

  test('numeric payment status remains forward compatible', () {
    expect(PaymentRequestStatus.parse(2), PaymentRequestStatus.approved);
    expect(PaymentRequestStatus.parse(99), isNull);
  });
}
