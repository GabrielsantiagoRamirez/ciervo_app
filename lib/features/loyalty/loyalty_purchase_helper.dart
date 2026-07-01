import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../features/loyalty/data/loyalty_repository.dart';

Future<void> processLoyaltyAfterPurchase(
  BuildContext? context, {
  required double amount,
  String currency = 'COP',
  int? businessId,
  int? paymentIntentId,
  String? transactionId,
}) async {
  if (amount <= 0) return;
  final keySeed = paymentIntentId?.toString() ??
      transactionId ??
      '${businessId ?? 'pay'}-${amount.toStringAsFixed(2)}-${DateTime.now().millisecondsSinceEpoch}';
  final result = await getIt<LoyaltyRepository>().processPurchase(
    idempotencyKey: 'loyalty-$keySeed',
    amount: amount,
    currency: currency,
    businessId: businessId,
    paymentIntentId: paymentIntentId,
  );
  result.when(
    success: (value) {
      if (!value.hasRewards || context == null || !context.mounted) return;
      final parts = <String>[];
      if (value.pointsGenerated > 0) {
        parts.add('${value.pointsGenerated} puntos');
      }
      if (value.cashbackGenerated > 0) {
        parts.add('${value.cashbackGenerated} cashback');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡Ganaste ${parts.join(' y ')}!')),
      );
    },
    failure: (_) {},
  );
}
