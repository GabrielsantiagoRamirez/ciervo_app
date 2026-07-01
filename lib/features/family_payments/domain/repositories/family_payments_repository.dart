import '../../../../core/result/result.dart';
import '../entities/family_payment_card.dart';
import '../entities/family_payment_record.dart';
import '../entities/kid_parental_rules.dart';
import '../entities/pending_parent_payment.dart';

abstract interface class FamilyPaymentsRepository {
  Future<Result<List<FamilyPaymentCard>>> listCards();

  Future<Result<AddFamilyCardResult>> addCard({
    required String cardToken,
    String? alias,
    required String idempotencyKey,
  });

  Future<Result<FamilyPaymentCard>> verifyCard(String cardId);

  Future<Result<FamilyPaymentCard>> updateCardAlias({
    required String cardId,
    required String alias,
  });

  Future<Result<FamilyPaymentCard>> setPrimaryCard(String cardId);

  Future<Result<FamilyPaymentCard>> setBackupCard(String cardId);

  Future<Result<void>> deleteCard(String cardId);

  Future<Result<FamilyPaymentCard>> freezeCard(String cardId);

  Future<Result<FamilyPaymentCard>> unfreezeCard(String cardId);

  Future<Result<KidPaymentSource>> kidPaymentSource(String kidId);

  Future<Result<KidPaymentSource>> saveKidPaymentSource({
    required String kidId,
    required KidPaymentSource source,
  });

  Future<Result<KidSpendingLimits>> kidLimits(String kidId);

  Future<Result<KidSpendingLimits>> saveKidLimits({
    required String kidId,
    required KidSpendingLimits limits,
  });

  Future<Result<KidMerchantRules>> kidMerchantRules(String kidId);

  Future<Result<KidMerchantRules>> saveKidMerchantRules({
    required String kidId,
    required KidMerchantRules rules,
  });

  Future<Result<KidScheduleRules>> kidSchedule(String kidId);

  Future<Result<KidScheduleRules>> saveKidSchedule({
    required String kidId,
    required KidScheduleRules schedule,
  });

  Future<Result<KidAutoPaymentRules>> kidAutoPayment(String kidId);

  Future<Result<KidAutoPaymentRules>> saveKidAutoPayment({
    required String kidId,
    required KidAutoPaymentRules rules,
  });

  Future<Result<KidApprovalRules>> kidApprovalRules(String kidId);

  Future<Result<KidApprovalRules>> saveKidApprovalRules({
    required String kidId,
    required KidApprovalRules rules,
  });

  Future<Result<KidGeofenceRules>> kidGeofence(String kidId);

  Future<Result<KidGeofenceRules>> saveKidGeofence({
    required String kidId,
    required KidGeofenceRules geofence,
  });

  Future<Result<List<FamilyPaymentRecord>>> parentPayments({
    DateTime? from,
    DateTime? to,
    String? kidId,
    String? status,
    String? merchantQuery,
    String? cardId,
    int page = 1,
    int pageSize = 20,
  });

  Future<Result<List<FamilyPaymentRecord>>> kidPayments(
    String kidId, {
    int page = 1,
    int pageSize = 20,
  });

  Future<Result<FamilyPaymentDetail>> paymentDetail(String paymentId);

  Future<Result<PendingParentPayment>> pendingParentPayment(String paymentId);

  Future<Result<void>> approvePayment(String paymentId);

  Future<Result<void>> rejectPayment(String paymentId, {String? reason});
}
