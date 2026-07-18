import 'package:ciervo_clud/features/kid_wallet/presentation/widgets/kid_premium_wallet_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the Kids wallet overview and safe request actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: KidPremiumWalletDashboard(
            userName: 'Lucas',
            balance: 125750,
            heldBalance: 0,
            currency: 'COP',
            movements: const [
              {
                'description': 'Librería Nacional',
                'amount': -18900,
                'currency': 'COP',
                'createdAt': '2026-07-17T16:30:00Z',
              },
            ],
            monthlySpent: 126350,
            monthlyLimit: 300000,
            shieldLocked: false,
            cardLast4: '4582',
            photoUrl: '',
            onRefresh: () async {},
          ),
        ),
      ),
    );

    expect(find.text('MI WALLET'), findsOneWidget);
    expect(find.text('Pinduck'), findsOneWidget);
    expect(find.text('CIERVO SHIELD ACTIVO'), findsOneWidget);
    expect(find.text('Solicitar\npago'), findsOneWidget);
    expect(find.text('Tarjetas\ny NFC'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
