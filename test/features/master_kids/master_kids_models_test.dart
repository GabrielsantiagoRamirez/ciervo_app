import 'package:ciervo_clud/features/master_kids/domain/models/master_kids_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reservation policy body matches the contract', () {
    const command = AcceptReservationPolicyCommand(
      paymentRequestId: 9001,
      commerceId: 25,
      policyVersion: 3,
      idempotencyKey: 'policy-install-uuid-0001',
    );

    expect(command.toJson(), {
      'paymentRequestId': 9001,
      'commerceId': 25,
      'policyVersion': 3,
      'idempotencyKey': 'policy-install-uuid-0001',
    });
  });

  test('payment execution sends idempotency and paired coordinates', () {
    const command = PaymentExecuteCommand(
      token: 'one-time-token',
      pin: '654321',
      idempotencyKey: 'execute-terminal-0001',
      latitude: 4.710989,
      longitude: -74.072092,
    );

    expect(command.toJson(), {
      'token': 'one-time-token',
      'pin': '654321',
      'idempotencyKey': 'execute-terminal-0001',
      'latitude': 4.710989,
      'longitude': -74.072092,
    });
  });

  test('payment execution rejects half a coordinate pair', () {
    expect(
      () => PaymentExecuteCommand(
        token: 'token',
        pin: '654321',
        idempotencyKey: 'execute-terminal-0001',
        latitude: 4.7,
      ),
      throwsAssertionError,
    );
  });

  test('device response parses approval lifecycle as UTC', () {
    final device = KidDeviceRegistration.fromJson({
      'id': 18,
      'kidId': 7,
      'deviceId': 'install-uuid',
      'platform': 'android',
      'appVersion': '2.0.0',
      'approved': true,
      'revoked': false,
      'registeredAt': '2026-07-18T01:00:00-05:00',
      'approvedAt': '2026-07-18T01:01:00-05:00',
      'lastSeenAt': null,
    });

    expect(device.approved, isTrue);
    expect(device.revoked, isFalse);
    expect(device.registeredAt.isUtc, isTrue);
    expect(device.approvedAt?.isUtc, isTrue);
  });

  test('token repetido no inventa ni persiste el secreto', () {
    final repeated = PaymentTokenIssued.fromJson({
      'authorizationId': 1,
      'paymentRequestId': 2,
      'commerceId': 3,
      'amount': 12000,
      'currency': 'COP',
      'expiresAt': '2026-07-18T10:00:00Z',
      'secretShown': false,
    });

    expect(repeated.secretShown, isFalse);
    expect(repeated.token, isNull);
    expect(repeated.pin, isNull);
  });

  test('reglas tipadas conservan nombres en lugar de IDs crudos', () {
    final merchant = KidRuleItem.fromJson({
      'merchantId': 7,
      'merchantName': 'Cine Centro',
    });
    final geofence = KidGeofence.fromJson({
      'id': 9,
      'name': 'Casa',
      'latitude': 4.7,
      'longitude': -74.0,
      'radius': 250,
    });

    expect(merchant.label, 'Cine Centro');
    expect(geofence.name, 'Casa');
    expect(geofence.radiusMeters, 250);
  });

  test('auditoría pagina items y export conserva bytes', () {
    final page = KidAuditPage.fromJson({
      'page': 2,
      'pageSize': 25,
      'total': 26,
      'items': [
        {
          'id': 1,
          'kidId': 3,
          'action': 'RULE_UPDATED',
          'createdAt': '2026-07-18T10:00:00Z',
        },
      ],
    });
    const export = AuditExport(
      bytes: [0xEF, 0xBB, 0xBF, 0x61],
      fileName: 'audit.csv',
    );

    expect(page.page, 2);
    expect(page.items.single.action, 'RULE_UPDATED');
    expect(export.bytes, [0xEF, 0xBB, 0xBF, 0x61]);
  });
}
