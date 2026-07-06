import 'package:flutter_test/flutter_test.dart';

import 'package:ciervo_clud/features/kids/presentation/utils/child_wallet_card_view.dart';

void main() {
  group('ChildWalletCardView', () {
    test('statusId 2 (creada) no se marca como bloqueada', () {
      final card = ChildWalletCardView.fromMap({
        'id': 42,
        'displayName': 'Mesada',
        'availableBalance': 5000,
        'currency': 'COP',
        'statusId': 2,
      });

      expect(card.id, '42');
      expect(card.isBlocked, isFalse);
      expect(card.displayName, 'Mesada');
      expect(card.balance, 5000);
    });

    test('statusId 0 se marca como bloqueada', () {
      final card = ChildWalletCardView.fromMap({
        'walletCardId': '7',
        'name': 'Tarjeta principal',
        'balance': 1000,
        'statusId': 0,
      });

      expect(card.id, '7');
      expect(card.isBlocked, isTrue);
      expect(card.displayName, 'Tarjeta principal');
    });

    test('desenvuelve tarjeta anidada en card', () {
      final cards = ChildWalletCardView.listFrom({
        'card': {
          'childWalletCardId': 99,
          'displayName': 'Regalo',
          'availableBalance': 25000,
        },
      });

      expect(cards, hasLength(1));
      expect(cards.first.id, '99');
      expect(cards.first.displayName, 'Regalo');
    });

    test('lista desde envelope con cards', () {
      final cards = ChildWalletCardView.listFrom({
        'cards': [
          {'id': 1, 'displayName': 'A', 'balance': 0},
          {'id': 2, 'displayName': 'B', 'balance': 100},
        ],
      });

      expect(cards, hasLength(2));
      expect(cards.map((c) => c.displayName), ['A', 'B']);
    });
  });
}
