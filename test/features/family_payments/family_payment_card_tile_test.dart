import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ciervo_clud/features/family_payments/domain/entities/family_payment_card.dart';
import 'package:ciervo_clud/features/family_payments/presentation/widgets/family_payment_card_tile.dart';

void main() {
  testWidgets('FamilyPaymentCardTile muestra alias, marca y chips', (tester) async {
    const card = FamilyPaymentCard(
      id: '1',
      brand: 'visa',
      lastFour: '4242',
      status: 'active',
      isPrimary: true,
      isBackup: false,
      expirationMonth: '08',
      expirationYear: '2027',
      alias: 'Tarjeta escolar',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FamilyPaymentCardTile(
            card: card,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Tarjeta escolar'), findsOneWidget);
    expect(find.textContaining('VISA'), findsOneWidget);
    expect(find.text('Principal'), findsOneWidget);
  });
}
