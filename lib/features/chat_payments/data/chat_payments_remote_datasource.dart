import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';

class ChatPaymentsRemoteDataSource {
  const ChatPaymentsRemoteDataSource(this._client);
  final NetworkClient _client;

  Future<Map<String, dynamic>> sendGift({
    required String conversationId,
    required String targetCiervoUserCode,
    required double amount,
    required String giftType,
    String? description,
    String? walletCardId,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/chat-payments/gift',
      data: {
        'conversationId': conversationId,
        'targetCiervoUserCode': targetCiervoUserCode,
        'amount': amount,
        'giftType': giftType,
        ?description: description,
        ?walletCardId: walletCardId,
        'idempotencyKey':
            'chat-gift-$conversationId-${DateTime.now().microsecondsSinceEpoch}',
      },
    );
    return unwrapApiMap(response.data);
  }
}
