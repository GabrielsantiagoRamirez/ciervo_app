import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../../../../core/utils/idempotency_key.dart';
import '../dtos/universal_nfc_dtos.dart';

abstract interface class UniversalNfcRemoteDataSource {
  Future<PaymentQuoteDto> nfcQuote({
    required double amount,
    required String currency,
    String? paymentMethodId,
    int? childProfileId,
  });

  Future<PaymentQuoteDto> paymentQuote({
    required String type,
    required double amount,
    required String currency,
    String? paymentMethodId,
    String? origin,
    String? destination,
  });

  Future<PaymentQuoteDto> transferQuote({
    required double amount,
    required String currency,
    required String destination,
    String? paymentMethodId,
  });

  Future<List<SavedPaymentMethodDto>> paymentMethods();

  Future<UniversalNfcPaymentDto> createIntent({
    required double amount,
    required String currency,
    String? paymentMethodId,
    String? merchantName,
    int? merchantId,
    int? childProfileId,
    String? idempotencyKey,
  });

  Future<UniversalNfcPaymentDto> payment(String paymentIntentId);

  Future<UniversalNfcPaymentDto> confirm(String paymentIntentId);

  Future<void> cancel(String paymentIntentId);

  Future<List<KidsNfcParentApprovalDto>> kidsApprovals();

  Future<UniversalNfcPaymentDto> approveKidsPayment(String paymentIntentId);

  Future<UniversalNfcPaymentDto> rejectKidsPayment(
    String paymentIntentId, {
    String? reason,
  });
}

class DioUniversalNfcRemoteDataSource implements UniversalNfcRemoteDataSource {
  const DioUniversalNfcRemoteDataSource(this._client);

  final NetworkClient _client;

  @override
  Future<PaymentQuoteDto> nfcQuote({
    required double amount,
    required String currency,
    String? paymentMethodId,
    int? childProfileId,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/nfc/payments/quote',
      data: {
        'amount': amount,
        'currency': currency,
        'context': 'UniversalNfc',
        if (paymentMethodId != null) 'paymentMethodId': paymentMethodId,
        if (childProfileId != null) 'childProfileId': childProfileId,
      },
    );
    return PaymentQuoteDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<PaymentQuoteDto> paymentQuote({
    required String type,
    required double amount,
    required String currency,
    String? paymentMethodId,
    String? origin,
    String? destination,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/payment/quote',
      data: {
        'type': type,
        'amount': amount,
        'currency': currency,
        if (paymentMethodId != null) 'paymentMethodId': paymentMethodId,
        if (origin != null) 'origin': origin,
        if (destination != null) 'destination': destination,
      },
    );
    return PaymentQuoteDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<PaymentQuoteDto> transferQuote({
    required double amount,
    required String currency,
    required String destination,
    String? paymentMethodId,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/wallet/transfer/quote',
      data: {
        'amount': amount,
        'currency': currency,
        'destination': destination,
        if (paymentMethodId != null) 'paymentMethodId': paymentMethodId,
      },
    );
    return PaymentQuoteDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<List<SavedPaymentMethodDto>> paymentMethods() async {
    final response = await _client.dio.get<dynamic>('/api/payment-methods');
    return SavedPaymentMethodDto.listFrom(unwrapApiResponse(response.data));
  }

  @override
  Future<UniversalNfcPaymentDto> createIntent({
    required double amount,
    required String currency,
    String? paymentMethodId,
    String? merchantName,
    int? merchantId,
    int? childProfileId,
    String? idempotencyKey,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/nfc/payments/intent',
      data: {
        'idempotencyKey': idempotencyKey ?? IdempotencyKey.generate('nfc-universal'),
        'amount': amount,
        'currency': currency,
        'context': 'UniversalNfc',
        if (paymentMethodId != null) 'paymentMethodId': paymentMethodId,
        if (merchantName != null) 'merchantName': merchantName,
        if (merchantId != null) 'merchantId': merchantId,
        if (childProfileId != null) 'childProfileId': childProfileId,
      },
    );
    return UniversalNfcPaymentDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<UniversalNfcPaymentDto> payment(String paymentIntentId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/nfc/payments/$paymentIntentId',
    );
    return UniversalNfcPaymentDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<UniversalNfcPaymentDto> confirm(String paymentIntentId) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/nfc/payments/$paymentIntentId/confirm',
    );
    return UniversalNfcPaymentDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<void> cancel(String paymentIntentId) async {
    await _client.dio.post<void>(
      '/api/nfc/payments/$paymentIntentId/cancel',
    );
  }

  @override
  Future<List<KidsNfcParentApprovalDto>> kidsApprovals() async {
    final response = await _client.dio.get<dynamic>(
      '/api/nfc/kids/payments/approvals',
    );
    return KidsNfcParentApprovalDto.listFrom(unwrapApiResponse(response.data));
  }

  @override
  Future<UniversalNfcPaymentDto> approveKidsPayment(
    String paymentIntentId,
  ) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/nfc/kids/payments/$paymentIntentId/approve',
    );
    return UniversalNfcPaymentDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<UniversalNfcPaymentDto> rejectKidsPayment(
    String paymentIntentId, {
    String? reason,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/nfc/kids/payments/$paymentIntentId/reject',
      data: {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    return UniversalNfcPaymentDto.fromJson(unwrapApiMap(response.data));
  }
}
