import '../../../../core/result/result.dart';
import '../entities/ciervo_wallet_identity.dart';
import '../entities/nfc_models.dart';
import '../entities/payment_request.dart';
import '../entities/recharge_intent.dart';
import '../entities/resolved_wallet_user.dart';
import '../entities/transfer_result.dart';
import '../entities/wallet_card.dart';
import '../entities/wallet_transaction.dart';

abstract interface class WalletRepository {
  Future<Result<List<WalletCard>>> cards();
  Future<Result<WalletCard>> cardDetail(String cardId);
  Future<Result<List<WalletTransaction>>> transactions(String cardId);
  Future<Result<void>> setPrimary(String cardId);
  Future<Result<void>> block(String cardId);
  Future<Result<void>> unblock(String cardId);
  Future<Result<void>> delete(String cardId);
  Future<Result<RechargeIntent>> createRechargeIntent({
    required String cardId,
    required double amount,
  });
  Future<Result<RechargeIntent>> rechargeIntent(String intentId);
  Future<Result<CiervoWalletIdentity>> myCiervoId();
  Future<Result<Map<String, dynamic>>> mercadoPagoConfig();
  Future<Result<ResolvedWalletUser>> resolveUser(String ciervoUserCode);
  Future<Result<TransferResult>> transfer({
    required String targetCiervoUserCode,
    required double amount,
    required String description,
    String? walletCardId,
  });
  Future<Result<PaymentRequest>> requestMoney({
    String? payerUserId,
    String? payerCiervoUserCode,
    required double amount,
    required String description,
    String? chatConversationId,
    int? businessId,
  });
  Future<Result<RechargeIntent>> rechargeByCiervoId({
    required String targetCiervoUserCode,
    required double amount,
    String? description,
  });
  Future<Result<List<PaymentRequest>>> paymentRequestsInbox();
  Future<Result<List<PaymentRequest>>> paymentRequestsSent();
  Future<Result<PaymentRequest>> approvePaymentRequest(String id);
  Future<Result<PaymentRequest>> rejectPaymentRequest(String id, String reason);
  Future<Result<PaymentRequest>> cancelPaymentRequest(String id);
  Future<Result<NfcSession>> createNfcSession({
    required String walletCardId,
    required int businessId,
    required double amount,
    String currency = 'COP',
    String? description,
    int expirationSeconds = 60,
  });
  Future<Result<NfcSession>> nfcSession(int sessionId);
  Future<Result<void>> cancelNfcSession(int sessionId);
  Future<Result<List<PhysicalNfcCard>>> physicalNfcCards();
  Future<Result<PhysicalNfcCard>> registerPhysicalNfcCard({
    required String cardId,
    required String cardUid,
    required String label,
  });
  Future<Result<void>> blockPhysicalNfcCard(int id);
}
