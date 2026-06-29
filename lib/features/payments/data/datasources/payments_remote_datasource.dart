import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../dtos/payment_dtos.dart';

abstract interface class PaymentsRemoteDataSource {
  Future<PaymentConfigDto> config();
  Future<PaymentIntentDto> createIntent(Map<String, dynamic> body);
  Future<PaymentIntentDto> intent(String id);
  Future<List<PaymentHistoryItemDto>> myPayments({
    String? type,
    String? status,
    int page,
    int pageSize,
  });
  Future<PaymentHistoryItemDto> myPayment(String id);
  Future<PaymentIntentDto> membershipSubscribeIntent({
    required String membershipPlanId,
    required String idempotencyKey,
  });

  Future<PaymentIntentDto> legacyWalletRecharge({
    required String walletCardId,
    required double amount,
    required String idempotencyKey,
  });
}

class DioPaymentsRemoteDataSource implements PaymentsRemoteDataSource {
  const DioPaymentsRemoteDataSource(this._client);

  final NetworkClient _client;

  @override
  Future<PaymentConfigDto> config() async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/payments/config',
      );
      return PaymentConfigDto.fromJson(unwrapApiMap(response.data));
    } catch (_) {
      final legacy = await _client.dio.get<Map<String, dynamic>>(
        '/api/wallet/mercadopago/config',
      );
      final map = unwrapApiMap(legacy.data);
      return PaymentConfigDto.fromJson({
        'provider': 'MercadoPago',
        'enabled': map['enabled'] ?? true,
        'publicKey': map['publicKey'] ?? map['public_key'] ?? '',
        'currency': map['currency'] ?? 'COP',
        'isSandbox': map['isSandbox'] ?? map['sandbox'] ?? false,
      });
    }
  }

  @override
  Future<PaymentIntentDto> createIntent(Map<String, dynamic> body) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/payments/intents',
      data: body,
    );
    return PaymentIntentDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<PaymentIntentDto> intent(String id) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/payments/intents/$id',
      );
      return PaymentIntentDto.fromJson(unwrapApiMap(response.data));
    } catch (_) {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/wallet/recharge-intents/$id',
      );
      return PaymentIntentDto.fromJson(unwrapApiMap(response.data));
    }
  }

  @override
  Future<List<PaymentHistoryItemDto>> myPayments({
    String? type,
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _client.dio.get<dynamic>(
      '/api/payments/me',
      queryParameters: {
        if (type != null && type.isNotEmpty) 'type': type,
        if (status != null && status.isNotEmpty) 'status': status,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return PaymentHistoryItemDto.listFrom(unwrapApiResponse(response.data));
  }

  @override
  Future<PaymentHistoryItemDto> myPayment(String id) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/payments/me/$id',
    );
    return PaymentHistoryItemDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<PaymentIntentDto> membershipSubscribeIntent({
    required String membershipPlanId,
    required String idempotencyKey,
  }) async {
    final parsed = int.tryParse(membershipPlanId);
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/memberships/subscribe-intents',
      data: {
        'membershipPlanId': parsed ?? membershipPlanId,
        'idempotencyKey': idempotencyKey,
      },
    );
    return PaymentIntentDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<PaymentIntentDto> legacyWalletRecharge({
    required String walletCardId,
    required double amount,
    required String idempotencyKey,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/wallet/cards/$walletCardId/recharge-intents',
      data: {
        'amount': amount,
        'currency': 'COP',
        'idempotencyKey': idempotencyKey,
      },
    );
    return PaymentIntentDto.fromJson(unwrapApiMap(response.data));
  }
}
