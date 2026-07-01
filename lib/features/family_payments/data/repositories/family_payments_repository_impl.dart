import 'package:dio/dio.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/family_payment_card.dart';
import '../../domain/entities/family_payment_record.dart';
import '../../domain/entities/kid_parental_rules.dart';
import '../../domain/entities/pending_parent_payment.dart';
import '../../domain/repositories/family_payments_repository.dart';
import '../datasources/family_payments_remote_datasource.dart';
import '../dtos/family_payment_dtos.dart';

class FamilyPaymentsRepositoryImpl implements FamilyPaymentsRepository {
  const FamilyPaymentsRepositoryImpl(this._remote);

  final FamilyPaymentsRemoteDataSource _remote;

  @override
  Future<Result<List<FamilyPaymentCard>>> listCards() => _guard(
        () async => (await _remote.listCards()).map((dto) => dto.toDomain()).toList(),
      );

  @override
  Future<Result<AddFamilyCardResult>> addCard({
    required String cardToken,
    String? alias,
    required String idempotencyKey,
  }) => _guard(
        () async => (await _remote.addCard(
          cardToken: cardToken,
          alias: alias,
          idempotencyKey: idempotencyKey,
        ))
            .toDomain(),
      );

  @override
  Future<Result<FamilyPaymentCard>> verifyCard(String cardId) => _guard(
        () async => (await _remote.verifyCard(cardId)).toDomain(),
      );

  @override
  Future<Result<FamilyPaymentCard>> updateCardAlias({
    required String cardId,
    required String alias,
  }) => _guard(
        () async =>
            (await _remote.updateCard(cardId: cardId, alias: alias)).toDomain(),
      );

  @override
  Future<Result<FamilyPaymentCard>> setPrimaryCard(String cardId) => _guard(
        () async => (await _remote.updateCard(
          cardId: cardId,
          isPrimary: true,
        ))
            .toDomain(),
      );

  @override
  Future<Result<FamilyPaymentCard>> setBackupCard(String cardId) => _guard(
        () async => (await _remote.updateCard(
          cardId: cardId,
          isBackup: true,
        ))
            .toDomain(),
      );

  @override
  Future<Result<void>> deleteCard(String cardId) => _guard(
        () async => _remote.deleteCard(cardId),
      );

  @override
  Future<Result<FamilyPaymentCard>> freezeCard(String cardId) => _guard(
        () async => (await _remote.freezeCard(cardId)).toDomain(),
      );

  @override
  Future<Result<FamilyPaymentCard>> unfreezeCard(String cardId) => _guard(
        () async => (await _remote.unfreezeCard(cardId)).toDomain(),
      );

  @override
  Future<Result<KidPaymentSource>> kidPaymentSource(String kidId) => _guard(
        () async => (await _remote.kidPaymentSource(kidId)).toDomain(),
      );

  @override
  Future<Result<KidPaymentSource>> saveKidPaymentSource({
    required String kidId,
    required KidPaymentSource source,
  }) =>
      _guard(
        () async => (await _remote.saveKidPaymentSource(
          kidId,
          KidPaymentSourceDto(
            cardId: source.cardId,
            mode: source.mode,
            usePrimaryCard: source.usePrimaryCard,
          ).toJson(),
        ))
            .toDomain(),
      );

  @override
  Future<Result<KidSpendingLimits>> kidLimits(String kidId) => _guard(
        () async => (await _remote.kidLimits(kidId)).toDomain(),
      );

  @override
  Future<Result<KidSpendingLimits>> saveKidLimits({
    required String kidId,
    required KidSpendingLimits limits,
  }) =>
      _guard(
        () async => (await _remote.saveKidLimits(
          kidId,
          KidSpendingLimitsDto(
            perPurchaseLimit: limits.perPurchaseLimit,
            dailyLimit: limits.dailyLimit,
            monthlyLimit: limits.monthlyLimit,
          ).toJson(),
        ))
            .toDomain(),
      );

  @override
  Future<Result<KidMerchantRules>> kidMerchantRules(String kidId) => _guard(
        () async => (await _remote.kidMerchantRules(kidId)).toDomain(),
      );

  @override
  Future<Result<KidMerchantRules>> saveKidMerchantRules({
    required String kidId,
    required KidMerchantRules rules,
  }) =>
      _guard(
        () async => (await _remote.saveKidMerchantRules(
          kidId,
          KidMerchantRulesDto(
            allowedCategoryIds: rules.allowedCategoryIds,
            blockedCategoryIds: rules.blockedCategoryIds,
            allowedBusinessIds: rules.allowedBusinessIds,
            blockedBusinessIds: rules.blockedBusinessIds,
          ).toJson(),
        ))
            .toDomain(),
      );

  @override
  Future<Result<KidScheduleRules>> kidSchedule(String kidId) => _guard(
        () async => (await _remote.kidSchedule(kidId)).toDomain(),
      );

  @override
  Future<Result<KidScheduleRules>> saveKidSchedule({
    required String kidId,
    required KidScheduleRules schedule,
  }) =>
      _guard(
        () async => (await _remote.saveKidSchedule(
          kidId,
          KidScheduleRulesDto(
            startTime: schedule.startTime,
            endTime: schedule.endTime,
            allowedDays: schedule.allowedDays,
          ).toJson(),
        ))
            .toDomain(),
      );

  @override
  Future<Result<KidAutoPaymentRules>> kidAutoPayment(String kidId) => _guard(
        () async => (await _remote.kidAutoPayment(kidId)).toDomain(),
      );

  @override
  Future<Result<KidAutoPaymentRules>> saveKidAutoPayment({
    required String kidId,
    required KidAutoPaymentRules rules,
  }) =>
      _guard(
        () async => (await _remote.saveKidAutoPayment(
          kidId,
          KidAutoPaymentRulesDto(
            enabled: rules.enabled,
            maxAutomaticAmount: rules.maxAutomaticAmount,
          ).toJson(),
        ))
            .toDomain(),
      );

  @override
  Future<Result<KidApprovalRules>> kidApprovalRules(String kidId) => _guard(
        () async => (await _remote.kidApprovalRules(kidId)).toDomain(),
      );

  @override
  Future<Result<KidApprovalRules>> saveKidApprovalRules({
    required String kidId,
    required KidApprovalRules rules,
  }) =>
      _guard(
        () async => (await _remote.saveKidApprovalRules(
          kidId,
          KidApprovalRulesDto(
            requireApprovalFromAmount: rules.requireApprovalFromAmount,
            alwaysApprovedCategoryIds: rules.alwaysApprovedCategoryIds,
            alwaysManualCategoryIds: rules.alwaysManualCategoryIds,
          ).toJson(),
        ))
            .toDomain(),
      );

  @override
  Future<Result<KidGeofenceRules>> kidGeofence(String kidId) => _guard(
        () async => (await _remote.kidGeofence(kidId)).toDomain(),
      );

  @override
  Future<Result<KidGeofenceRules>> saveKidGeofence({
    required String kidId,
    required KidGeofenceRules geofence,
  }) =>
      _guard(
        () async => (await _remote.saveKidGeofence(
          kidId,
          KidGeofenceRulesDto(
            enabled: geofence.enabled,
            latitude: geofence.latitude,
            longitude: geofence.longitude,
            radiusMeters: geofence.radiusMeters,
          ).toJson(),
        ))
            .toDomain(),
      );

  @override
  Future<Result<List<FamilyPaymentRecord>>> parentPayments({
    DateTime? from,
    DateTime? to,
    String? kidId,
    String? status,
    String? merchantQuery,
    String? cardId,
    int page = 1,
    int pageSize = 20,
  }) =>
      _guard(
        () async => (await _remote.parentPayments(
          from: from,
          to: to,
          kidId: kidId,
          status: status,
          merchantQuery: merchantQuery,
          cardId: cardId,
          page: page,
          pageSize: pageSize,
        ))
            .map((dto) => dto.toDomain())
            .toList(),
      );

  @override
  Future<Result<List<FamilyPaymentRecord>>> kidPayments(
    String kidId, {
    int page = 1,
    int pageSize = 20,
  }) =>
      _guard(
        () async => (await _remote.kidPayments(
          kidId,
          page: page,
          pageSize: pageSize,
        ))
            .map((dto) => dto.toDomain())
            .toList(),
      );

  @override
  Future<Result<FamilyPaymentDetail>> paymentDetail(String paymentId) =>
      _guard(
        () async => (await _remote.paymentDetail(paymentId)).toDetailDomain(),
      );

  @override
  Future<Result<PendingParentPayment>> pendingParentPayment(
    String paymentId,
  ) =>
      _guard(
        () async {
          try {
            return (await _remote.pendingParentPayment(paymentId)).toDomain();
          } on DioException catch (error) {
            if (error.response?.statusCode == 404) {
              final detail = await _remote.paymentDetail(paymentId);
              return PendingParentPayment(
                paymentId: detail.id,
                kidId: detail.kidId ?? '',
                kidName: detail.kidName ?? 'Menor',
                merchantName: detail.merchantName,
                city: detail.city,
                amount: detail.amount,
                currency: detail.currency,
                requestedAt: detail.createdAt,
                fundingSource: detail.fundingSource,
              );
            }
            rethrow;
          }
        },
      );

  @override
  Future<Result<void>> approvePayment(String paymentId) => _guard(
        () async => _remote.approvePayment(paymentId),
      );

  @override
  Future<Result<void>> rejectPayment(String paymentId, {String? reason}) =>
      _guard(
        () async => _remote.rejectPayment(paymentId, reason: reason),
      );

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Success(await run());
    } on DioException catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
