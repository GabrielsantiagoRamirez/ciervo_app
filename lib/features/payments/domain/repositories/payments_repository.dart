import '../../../../core/result/result.dart';
import '../entities/payment_config.dart';
import '../entities/payment_history_item.dart';
import '../entities/payment_intent.dart';

abstract interface class PaymentsRepository {
  Future<Result<PaymentConfig>> config();

  Future<Result<PaymentIntent>> createWalletRecharge({
    required String walletCardId,
    required double amount,
    required String currency,
    required String idempotencyKey,
  });

  Future<Result<PaymentIntent>> createDeliveryPayment({
    required String deliveryOrderId,
    required String idempotencyKey,
  });

  Future<Result<PaymentIntent>> createMembershipSubscribeIntent({
    required String membershipPlanId,
    required String idempotencyKey,
  });

  Future<Result<PaymentIntent>> intent(String id);

  Future<Result<PaymentIntent>> pollIntent(
    String id, {
    Duration interval = const Duration(seconds: 3),
    int maxAttempts = 20,
  });

  Future<Result<List<PaymentHistoryItem>>> myPayments({
    String? type,
    String? status,
    int page,
    int pageSize,
  });

  Future<Result<PaymentHistoryItem>> myPayment(String id);
}
