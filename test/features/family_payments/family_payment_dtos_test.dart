import 'package:flutter_test/flutter_test.dart';

import 'package:ciervo_clud/features/family_payments/data/dtos/family_payment_dtos.dart';

void main() {
  group('FamilyPaymentCardDto', () {
    test('parsea tarjeta con alias y estado congelado', () {
      final dto = FamilyPaymentCardDto.fromJson({
        'cardId': '12',
        'brand': 'visa',
        'lastFour': '4242',
        'status': 'frozen',
        'isPrimary': true,
        'isBackup': false,
        'expirationMonth': '12',
        'expirationYear': '2028',
        'alias': 'Tarjeta principal',
      });

      final domain = dto.toDomain();
      expect(domain.id, '12');
      expect(domain.alias, 'Tarjeta principal');
      expect(domain.isPrimary, isTrue);
      expect(domain.isFrozen, isTrue);
      expect(domain.expirationLabel, '12/28');
    });
  });

  group('AddFamilyCardResponseDto', () {
    test('detecta flujo 3DS', () {
      final dto = AddFamilyCardResponseDto.fromJson({
        'card': {
          'id': '9',
          'brand': 'master',
          'lastFour': '1234',
        },
        'requires3DS': true,
        'verificationUrl': 'https://mp.test/3ds',
      });

      final domain = dto.toDomain();
      expect(domain.requires3ds, isTrue);
      expect(domain.verificationUrl, 'https://mp.test/3ds');
      expect(domain.card.id, '9');
    });
  });

  group('FamilyPaymentRecordDto', () {
    test('marca pago respaldado por tarjeta del tutor', () {
      final dto = FamilyPaymentRecordDto.fromJson({
        'paymentId': '55',
        'amount': 25000,
        'currency': 'COP',
        'status': 'completed',
        'merchantName': 'Cafe Ciervo',
        'fundingSource': 'parent_card',
        'usedParentCard': true,
      });

      final detail = dto.toDetailDomain();
      expect(detail.usedParentCard, isTrue);
      expect(detail.merchantName, 'Cafe Ciervo');
    });
  });
}
