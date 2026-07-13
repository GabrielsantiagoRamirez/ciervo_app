import 'package:flutter_test/flutter_test.dart';

import 'package:ciervo_clud/features/promotions/data/promotions_repository.dart';

void main() {
  group('CurrentPromotion', () {
    test('parsea respuesta prod de GET /current', () {
      final promo = CurrentPromotion.fromJson({
        'id': 'gold-trial-200',
        'title': 'Plan Gold gratis 60 días',
        'description': 'Las primeras 200 personas...',
        'eligible': true,
        'slotsRemaining': 187,
        'termsUrl': 'https://ciervo.club/#/terms',
      });

      expect(promo.id, 'gold-trial-200');
      expect(promo.eligible, isTrue);
      expect(promo.slotsRemaining, 187);
    });
  });

  group('GoldTrialClaimResult', () {
    test('parsea respuesta prod de POST /claim', () {
      final claim = GoldTrialClaimResult.fromJson({
        'promotionId': 'gold-trial-200',
        'membershipId': 42,
        'planCode': 'gold',
        'planName': 'CIERVO GOLD',
        'status': 'Active',
        'startsAt': '2026-07-05T17:30:00Z',
        'expiresAt': '2026-09-03T17:30:00Z',
        'trialDays': 60,
        'termsAccepted': true,
        'message': 'Plan Gold activado por 60 días.',
      });

      expect(claim.membershipId, 42);
      expect(claim.planCode, 'gold');
      expect(claim.trialDays, 60);
      expect(claim.message, contains('60 días'));
    });
  });
}
