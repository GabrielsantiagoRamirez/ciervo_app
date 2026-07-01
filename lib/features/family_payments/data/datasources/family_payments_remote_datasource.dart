import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../dtos/family_payment_dtos.dart';

abstract interface class FamilyPaymentsRemoteDataSource {
  Future<List<FamilyPaymentCardDto>> listCards();

  Future<AddFamilyCardResponseDto> addCard({
    required String cardToken,
    String? alias,
    required String idempotencyKey,
  });

  Future<FamilyPaymentCardDto> verifyCard(String cardId);

  Future<FamilyPaymentCardDto> updateCard({
    required String cardId,
    String? alias,
    bool? isPrimary,
    bool? isBackup,
  });

  Future<void> deleteCard(String cardId);

  Future<FamilyPaymentCardDto> freezeCard(String cardId);

  Future<FamilyPaymentCardDto> unfreezeCard(String cardId);

  Future<KidPaymentSourceDto> kidPaymentSource(String kidId);

  Future<KidPaymentSourceDto> saveKidPaymentSource(
    String kidId,
    Map<String, dynamic> data,
  );

  Future<KidSpendingLimitsDto> kidLimits(String kidId);

  Future<KidSpendingLimitsDto> saveKidLimits(
    String kidId,
    Map<String, dynamic> data,
  );

  Future<KidMerchantRulesDto> kidMerchantRules(String kidId);

  Future<KidMerchantRulesDto> saveKidMerchantRules(
    String kidId,
    Map<String, dynamic> data,
  );

  Future<KidScheduleRulesDto> kidSchedule(String kidId);

  Future<KidScheduleRulesDto> saveKidSchedule(
    String kidId,
    Map<String, dynamic> data,
  );

  Future<KidAutoPaymentRulesDto> kidAutoPayment(String kidId);

  Future<KidAutoPaymentRulesDto> saveKidAutoPayment(
    String kidId,
    Map<String, dynamic> data,
  );

  Future<KidApprovalRulesDto> kidApprovalRules(String kidId);

  Future<KidApprovalRulesDto> saveKidApprovalRules(
    String kidId,
    Map<String, dynamic> data,
  );

  Future<KidGeofenceRulesDto> kidGeofence(String kidId);

  Future<KidGeofenceRulesDto> saveKidGeofence(
    String kidId,
    Map<String, dynamic> data,
  );

  Future<List<FamilyPaymentRecordDto>> parentPayments({
    DateTime? from,
    DateTime? to,
    String? kidId,
    String? status,
    String? merchantQuery,
    String? cardId,
    int page = 1,
    int pageSize = 20,
  });

  Future<List<FamilyPaymentRecordDto>> kidPayments(
    String kidId, {
    int page = 1,
    int pageSize = 20,
  });

  Future<FamilyPaymentRecordDto> paymentDetail(String paymentId);

  Future<PendingParentPaymentDto> pendingParentPayment(String paymentId);

  Future<void> approvePayment(String paymentId);

  Future<void> rejectPayment(String paymentId, {String? reason});
}

class DioFamilyPaymentsRemoteDataSource
    implements FamilyPaymentsRemoteDataSource {
  const DioFamilyPaymentsRemoteDataSource(this._client);

  final NetworkClient _client;

  @override
  Future<List<FamilyPaymentCardDto>> listCards() async {
    final response = await _client.dio.get<dynamic>(
      '/api/family/payment-methods/cards',
    );
    return FamilyPaymentCardDto.listFrom(unwrapApiResponse(response.data));
  }

  @override
  Future<AddFamilyCardResponseDto> addCard({
    required String cardToken,
    String? alias,
    required String idempotencyKey,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/family/payment-methods/cards',
      data: {
        'cardToken': cardToken,
        if (alias != null && alias.trim().isNotEmpty) 'alias': alias.trim(),
        'idempotencyKey': idempotencyKey,
      },
    );
    return AddFamilyCardResponseDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<FamilyPaymentCardDto> verifyCard(String cardId) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/family/payment-methods/cards/$cardId/verify',
    );
    return FamilyPaymentCardDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<FamilyPaymentCardDto> updateCard({
    required String cardId,
    String? alias,
    bool? isPrimary,
    bool? isBackup,
  }) async {
    final response = await _client.dio.put<Map<String, dynamic>>(
      '/api/family/payment-methods/cards/$cardId',
      data: {
        if (alias != null) 'alias': alias,
        if (isPrimary != null) 'isPrimary': isPrimary,
        if (isBackup != null) 'isBackup': isBackup,
      },
    );
    return FamilyPaymentCardDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<void> deleteCard(String cardId) async {
    await _client.dio.delete<void>(
      '/api/family/payment-methods/cards/$cardId',
    );
  }

  @override
  Future<FamilyPaymentCardDto> freezeCard(String cardId) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/family/payment-methods/cards/$cardId/freeze',
    );
    return FamilyPaymentCardDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<FamilyPaymentCardDto> unfreezeCard(String cardId) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/family/payment-methods/cards/$cardId/unfreeze',
    );
    return FamilyPaymentCardDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<KidPaymentSourceDto> kidPaymentSource(String kidId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/family/kids/$kidId/payment-source',
    );
    return KidPaymentSourceDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<KidPaymentSourceDto> saveKidPaymentSource(
    String kidId,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/family/kids/$kidId/payment-source',
      data: data,
    );
    return KidPaymentSourceDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<KidSpendingLimitsDto> kidLimits(String kidId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/family/kids/$kidId/limits',
    );
    return KidSpendingLimitsDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<KidSpendingLimitsDto> saveKidLimits(
    String kidId,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.dio.put<Map<String, dynamic>>(
      '/api/family/kids/$kidId/limits',
      data: data,
    );
    return KidSpendingLimitsDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<KidMerchantRulesDto> kidMerchantRules(String kidId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/family/kids/$kidId/merchant-rules',
    );
    return KidMerchantRulesDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<KidMerchantRulesDto> saveKidMerchantRules(
    String kidId,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.dio.put<Map<String, dynamic>>(
      '/api/family/kids/$kidId/merchant-rules',
      data: data,
    );
    return KidMerchantRulesDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<KidScheduleRulesDto> kidSchedule(String kidId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/family/kids/$kidId/schedule',
    );
    return KidScheduleRulesDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<KidScheduleRulesDto> saveKidSchedule(
    String kidId,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.dio.put<Map<String, dynamic>>(
      '/api/family/kids/$kidId/schedule',
      data: data,
    );
    return KidScheduleRulesDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<KidAutoPaymentRulesDto> kidAutoPayment(String kidId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/family/kids/$kidId/auto-payment',
    );
    return KidAutoPaymentRulesDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<KidAutoPaymentRulesDto> saveKidAutoPayment(
    String kidId,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.dio.put<Map<String, dynamic>>(
      '/api/family/kids/$kidId/auto-payment',
      data: data,
    );
    return KidAutoPaymentRulesDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<KidApprovalRulesDto> kidApprovalRules(String kidId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/family/kids/$kidId/approval-rules',
    );
    return KidApprovalRulesDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<KidApprovalRulesDto> saveKidApprovalRules(
    String kidId,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.dio.put<Map<String, dynamic>>(
      '/api/family/kids/$kidId/approval-rules',
      data: data,
    );
    return KidApprovalRulesDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<KidGeofenceRulesDto> kidGeofence(String kidId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/family/kids/$kidId/geofence',
    );
    return KidGeofenceRulesDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<KidGeofenceRulesDto> saveKidGeofence(
    String kidId,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.dio.put<Map<String, dynamic>>(
      '/api/family/kids/$kidId/geofence',
      data: data,
    );
    return KidGeofenceRulesDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<List<FamilyPaymentRecordDto>> parentPayments({
    DateTime? from,
    DateTime? to,
    String? kidId,
    String? status,
    String? merchantQuery,
    String? cardId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _client.dio.get<dynamic>(
      '/api/family/payments',
      queryParameters: {
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
        if (kidId != null && kidId.isNotEmpty) 'kidId': kidId,
        if (status != null && status.isNotEmpty) 'status': status,
        if (merchantQuery != null && merchantQuery.isNotEmpty)
          'merchant': merchantQuery,
        if (cardId != null && cardId.isNotEmpty) 'cardId': cardId,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return FamilyPaymentRecordDto.listFrom(unwrapApiResponse(response.data));
  }

  @override
  Future<List<FamilyPaymentRecordDto>> kidPayments(
    String kidId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _client.dio.get<dynamic>(
      '/api/kids/$kidId/payments',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
    );
    return FamilyPaymentRecordDto.listFrom(unwrapApiResponse(response.data));
  }

  @override
  Future<FamilyPaymentRecordDto> paymentDetail(String paymentId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/payments/$paymentId',
    );
    return FamilyPaymentRecordDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<PendingParentPaymentDto> pendingParentPayment(String paymentId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/family/payments/$paymentId',
    );
    return PendingParentPaymentDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<void> approvePayment(String paymentId) async {
    await _client.dio.post<void>(
      '/api/family/payments/$paymentId/approve',
    );
  }

  @override
  Future<void> rejectPayment(String paymentId, {String? reason}) async {
    await _client.dio.post<void>(
      '/api/family/payments/$paymentId/reject',
      data: {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
  }
}
