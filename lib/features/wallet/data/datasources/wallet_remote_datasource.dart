// ignore_for_file: use_null_aware_elements

import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../dtos/nfc_dto.dart';
import '../dtos/payment_request_dto.dart';
import '../dtos/wallet_card_dto.dart';
import '../dtos/wallet_operation_dtos.dart';
import '../dtos/wallet_transaction_dto.dart';

abstract interface class WalletRemoteDataSource {
  Future<List<WalletCardDto>> cards();
  Future<WalletCardDto> cardDetail(String cardId);
  Future<List<WalletTransactionDto>> transactions(String cardId);
  Future<void> setPrimary(String cardId);
  Future<void> block(String cardId);
  Future<void> unblock(String cardId);
  Future<void> delete(String cardId);
  Future<Map<String, dynamic>> mercadoPagoConfig();
  Future<RechargeIntentDto> createRechargeIntent(String cardId, double amount);
  Future<RechargeIntentDto> rechargeIntent(String intentId);
  Future<ResolvedWalletUserDto> resolveUser(String ciervoUserCode);
  Future<TransferResultDto> transfer({
    required String targetCiervoUserCode,
    required double amount,
    required String description,
    String? walletCardId,
  });
  Future<PaymentRequestDto> requestMoney({
    String? payerUserId,
    String? payerCiervoUserCode,
    required double amount,
    required String description,
  });
  Future<RechargeIntentDto> rechargeByCiervoId({
    required String targetCiervoUserCode,
    required double amount,
    String? description,
  });
  Future<List<PaymentRequestDto>> paymentRequestsInbox();
  Future<List<PaymentRequestDto>> paymentRequestsSent();
  Future<PaymentRequestDto> approvePaymentRequest(String id);
  Future<PaymentRequestDto> rejectPaymentRequest(String id, String reason);
  Future<PaymentRequestDto> cancelPaymentRequest(String id);
  Future<NfcSessionDto> createNfcSession({
    required String walletCardId,
    required int businessId,
    required double amount,
    required String currency,
    required String idempotencyKey,
    String? description,
    int expirationSeconds = 60,
  });
  Future<NfcSessionDto> nfcSession(int sessionId);
  Future<void> cancelNfcSession(int sessionId);
  Future<List<PhysicalNfcCardDto>> physicalNfcCards();
  Future<PhysicalNfcCardDto> registerPhysicalNfcCard({
    required String cardId,
    required String cardUid,
    required String label,
  });
  Future<void> blockPhysicalNfcCard(int id);
}

class DioWalletRemoteDataSource implements WalletRemoteDataSource {
  const DioWalletRemoteDataSource(this._client);

  final NetworkClient _client;

  @override
  Future<List<WalletCardDto>> cards() async {
    final response = await _client.dio.get<dynamic>('/api/wallet/cards');
    return WalletCardDto.listFrom(unwrapApiResponse(response.data));
  }

  @override
  Future<WalletCardDto> cardDetail(String cardId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/wallet/cards/$cardId',
    );
    return WalletCardDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<List<WalletTransactionDto>> transactions(String cardId) async {
    final response = await _client.dio.get<dynamic>(
      '/api/wallet/cards/$cardId/transactions',
    );
    return WalletTransactionDto.listFrom(unwrapApiResponse(response.data));
  }

  @override
  Future<void> setPrimary(String cardId) async {
    await _client.dio.post<void>('/api/wallet/cards/$cardId/set-primary');
  }

  @override
  Future<void> block(String cardId) async {
    await _client.dio.post<void>('/api/wallet/cards/$cardId/block');
  }

  @override
  Future<void> unblock(String cardId) async {
    await _client.dio.post<void>('/api/wallet/cards/$cardId/unblock');
  }

  @override
  Future<void> delete(String cardId) async {
    await _client.dio.delete<void>('/api/wallet/cards/$cardId');
  }

  @override
  Future<Map<String, dynamic>> mercadoPagoConfig() async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/wallet/mercadopago/config',
    );
    return unwrapApiMap(response.data);
  }

  @override
  Future<RechargeIntentDto> createRechargeIntent(
    String cardId,
    double amount,
  ) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/wallet/cards/$cardId/recharge-intents',
      data: {
        'amount': amount,
        'currency': 'COP',
        'idempotencyKey': _idempotencyKey('recharge', cardId),
      },
    );
    return RechargeIntentDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<RechargeIntentDto> rechargeIntent(String intentId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/wallet/recharge-intents/$intentId',
    );
    return RechargeIntentDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<ResolvedWalletUserDto> resolveUser(String ciervoUserCode) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/wallet/resolve-user/$ciervoUserCode',
    );
    return ResolvedWalletUserDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<TransferResultDto> transfer({
    required String targetCiervoUserCode,
    required double amount,
    required String description,
    String? walletCardId,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/wallet/transfer',
      data: {
        'targetCiervoUserCode': targetCiervoUserCode,
        'amount': amount,
        'currency': 'COP',
        'idempotencyKey': _idempotencyKey('transfer', targetCiervoUserCode),
        'description': description,
        if (walletCardId != null) 'walletCardId': int.tryParse(walletCardId) ?? walletCardId,
      },
    );
    return TransferResultDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<PaymentRequestDto> requestMoney({
    String? payerUserId,
    String? payerCiervoUserCode,
    required double amount,
    required String description,
  }) async {
    final seed = payerCiervoUserCode ?? payerUserId ?? 'unknown';
    final data = <String, dynamic>{
      'amount': amount,
      'currency': 'COP',
      'description': description,
      'purpose': 'PayForMe',
      'idempotencyKey': _idempotencyKey('pay-for-me', seed),
    };
    if (payerCiervoUserCode != null && payerCiervoUserCode.isNotEmpty) {
      data['payerCiervoUserCode'] = payerCiervoUserCode;
    }
    if (payerUserId != null && payerUserId.isNotEmpty) {
      data['payerUserId'] = payerUserId;
    }
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/payment-requests/pay-for-me',
      data: data,
    );
    return PaymentRequestDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<RechargeIntentDto> rechargeByCiervoId({
    required String targetCiervoUserCode,
    required double amount,
    String? description,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/wallet/recharge-by-ciervo-id',
      data: {
        'targetCiervoUserCode': targetCiervoUserCode,
        'amount': amount,
        'currency': 'COP',
        'description': description ?? 'Recarga CIERVO',
        'idempotencyKey': _idempotencyKey('recharge-cid', targetCiervoUserCode),
      },
    );
    return RechargeIntentDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<List<PaymentRequestDto>> paymentRequestsInbox() async {
    final response = await _client.dio.get<dynamic>(
      '/api/payment-requests/inbox',
    );
    return PaymentRequestDto.listFrom(unwrapApiResponse(response.data));
  }

  @override
  Future<List<PaymentRequestDto>> paymentRequestsSent() async {
    final response = await _client.dio.get<dynamic>(
      '/api/payment-requests/sent',
    );
    return PaymentRequestDto.listFrom(unwrapApiResponse(response.data));
  }

  @override
  Future<PaymentRequestDto> approvePaymentRequest(String id) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/payment-requests/$id/approve',
    );
    return PaymentRequestDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<PaymentRequestDto> rejectPaymentRequest(
    String id,
    String reason,
  ) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/payment-requests/$id/reject',
      data: {'reason': reason},
    );
    return PaymentRequestDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<PaymentRequestDto> cancelPaymentRequest(String id) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/payment-requests/$id/cancel',
    );
    return PaymentRequestDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<NfcSessionDto> createNfcSession({
    required String walletCardId,
    required int businessId,
    required double amount,
    required String currency,
    required String idempotencyKey,
    String? description,
    int expirationSeconds = 60,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/wallet/nfc/sessions',
      data: {
        'idempotencyKey': idempotencyKey,
        'walletCardId': int.tryParse(walletCardId) ?? walletCardId,
        'businessId': businessId,
        'amount': amount,
        'currency': currency,
        'expirationSeconds': expirationSeconds,
        ?description: description,
      },
    );
    return NfcSessionDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<NfcSessionDto> nfcSession(int sessionId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/wallet/nfc/sessions/$sessionId',
    );
    return NfcSessionDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<void> cancelNfcSession(int sessionId) async {
    await _client.dio.post<void>(
      '/api/wallet/nfc/sessions/$sessionId/cancel',
    );
  }

  @override
  Future<List<PhysicalNfcCardDto>> physicalNfcCards() async {
    final response = await _client.dio.get<dynamic>(
      '/api/wallet/nfc/physical-cards',
    );
    return PhysicalNfcCardDto.listFrom(unwrapApiResponse(response.data));
  }

  @override
  Future<PhysicalNfcCardDto> registerPhysicalNfcCard({
    required String cardId,
    required String cardUid,
    required String label,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/wallet/cards/$cardId/physical-nfc',
      data: {
        'cardUid': cardUid,
        'label': label,
      },
    );
    return PhysicalNfcCardDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<void> blockPhysicalNfcCard(int id) async {
    await _client.dio.post<void>('/api/wallet/physical-nfc/$id/block');
  }

  String _idempotencyKey(String prefix, String seed) {
    return '$prefix-$seed-${DateTime.now().microsecondsSinceEpoch}';
  }
}
