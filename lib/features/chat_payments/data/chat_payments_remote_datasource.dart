import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';

class ChatPaymentsRemoteDataSource {
  const ChatPaymentsRemoteDataSource(this._client);
  final NetworkClient _client;

  Future<Map<String, dynamic>> pay({
    String? chatConversationId,
    String? targetCiervoUserCode,
    String? targetUserId,
    int? businessId,
    required double amount,
    required String description,
    String currency = 'COP',
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/chat-payments/pay',
      data: {
        if (targetCiervoUserCode != null && targetCiervoUserCode.isNotEmpty)
          'targetCiervoUserCode': targetCiervoUserCode,
        if (targetUserId != null && targetUserId.isNotEmpty)
          'targetUserId': int.tryParse(targetUserId) ?? targetUserId,
        if (businessId != null) 'businessId': businessId,
        'amount': amount,
        'currency': currency,
        'description': description,
        if (chatConversationId != null && chatConversationId.isNotEmpty)
          'chatConversationId':
              int.tryParse(chatConversationId) ?? chatConversationId,
        'idempotencyKey':
            'chat-pay-${chatConversationId ?? 'p2p'}-${DateTime.now().microsecondsSinceEpoch}',
      },
    );
    return unwrapApiMap(response.data);
  }

  Future<Map<String, dynamic>> sendGift({
    String? chatConversationId,
    required String targetCiervoUserCode,
    required double amount,
    required String giftType,
    String? message,
    String? walletCardId,
    String? targetUserId,
    int? businessId,
    String currency = 'COP',
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/chat-payments/gift',
      data: {
        'giftType': giftType,
        if (targetCiervoUserCode.isNotEmpty)
          'targetCiervoUserCode': targetCiervoUserCode,
        if (targetUserId != null && targetUserId.isNotEmpty)
          'targetUserId': int.tryParse(targetUserId) ?? targetUserId,
        if (businessId != null) 'businessId': businessId,
        'amount': amount,
        'currency': currency,
        if (message != null && message.isNotEmpty) 'message': message,
        if (walletCardId != null && walletCardId.isNotEmpty)
          'walletCardId': int.tryParse(walletCardId) ?? walletCardId,
        if (chatConversationId != null && chatConversationId.isNotEmpty)
          'chatConversationId':
              int.tryParse(chatConversationId) ?? chatConversationId,
        'idempotencyKey':
            'chat-gift-${chatConversationId ?? 'p2p'}-${DateTime.now().microsecondsSinceEpoch}',
      },
    );
    return unwrapApiMap(response.data);
  }
}
