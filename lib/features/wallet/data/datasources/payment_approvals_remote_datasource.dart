import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';

class PaymentApprovalsRemoteDataSource {
  const PaymentApprovalsRemoteDataSource(this._client);
  final NetworkClient _client;

  Future<Map<String, dynamic>> createRequest({
    required double amount,
    required String description,
    String? chatConversationId,
    int? businessId,
    String? approverCiervoUserCode,
    String currency = 'COP',
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/approvals/payment-requests',
      data: {
        'amount': amount,
        'currency': currency,
        'description': description,
        if (businessId != null) 'businessId': businessId,
        if (chatConversationId != null && chatConversationId.isNotEmpty)
          'chatConversationId':
              int.tryParse(chatConversationId) ?? chatConversationId,
        'idempotencyKey':
            'approval-${chatConversationId ?? 'chat'}-${DateTime.now().microsecondsSinceEpoch}',
      },
    );
    return unwrapApiMap(response.data);
  }
}
