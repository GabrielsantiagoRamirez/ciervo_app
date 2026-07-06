import '../../../../core/result/result.dart';
import '../entities/payment_quote.dart';
import '../entities/universal_nfc_payment.dart';

abstract interface class UniversalNfcRepository {
  Future<Result<PaymentQuote>> nfcQuote({
    required double amount,
    required String currency,
    String? paymentMethodId,
    int? childProfileId,
  });

  Future<Result<PaymentQuote>> transferQuote({
    required double amount,
    required String currency,
    required String destination,
    String? paymentMethodId,
  });

  Future<Result<List<SavedPaymentMethod>>> paymentMethods();

  Future<Result<UniversalNfcPayment>> createIntent({
    required double amount,
    required String currency,
    String? paymentMethodId,
    String? merchantName,
    int? merchantId,
    int? childProfileId,
    String? idempotencyKey,
  });

  Future<Result<UniversalNfcPayment>> payment(String paymentIntentId);

  Future<Result<UniversalNfcPayment>> confirm(String paymentIntentId);

  Future<Result<void>> cancel(String paymentIntentId);

  Future<Result<List<KidsNfcParentApproval>>> kidsApprovals();

  Future<Result<UniversalNfcPayment>> approveKidsPayment(String paymentIntentId);

  Future<Result<UniversalNfcPayment>> rejectKidsPayment(
    String paymentIntentId, {
    String? reason,
  });
}
