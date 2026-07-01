import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import 'package:dio/dio.dart';

class ChatRemoteDataSource {
  const ChatRemoteDataSource(this._client);
  final NetworkClient _client;

  Future<List<dynamic>> conversations() async => unwrapApiList(
    (await _client.dio.get<dynamic>('/api/chat/conversations')).data,
  );

  Future<Map<String, dynamic>> conversation(String id) async => unwrapApiMap(
    (await _client.dio.get<dynamic>('/api/chat/conversations/$id')).data,
  );

  Future<List<dynamic>> messages(String id, int page, int pageSize) async =>
      unwrapApiList(
        (await _client.dio.get<dynamic>(
          '/api/chat/conversations/$id/messages',
          queryParameters: {'page': page, 'pageSize': pageSize},
        )).data,
      );

  Future<Map<String, dynamic>> createDirectConversation({
    required String targetUserId,
  }) async =>
      unwrapApiMap(
        (await _client.dio.post<dynamic>(
          '/api/chat/conversations',
          data: {
            'type': 'Direct',
            'targetUserId': int.tryParse(targetUserId) ?? targetUserId,
          },
        )).data,
      );

  Future<Map<String, dynamic>> forwardMessage({
    required String conversationId,
    required String messageId,
    required String targetConversationId,
    String? comment,
  }) async =>
      unwrapApiMap(
        (await _client.dio.post<dynamic>(
          '/api/chat/conversations/$conversationId/messages/$messageId/forward',
          data: {
            'targetConversationId':
                int.tryParse(targetConversationId) ?? targetConversationId,
            if (comment != null && comment.isNotEmpty) 'comment': comment,
          },
        )).data,
      );

  Future<Map<String, dynamic>> createSupportConversation({
    required String title,
  }) async =>
      unwrapApiMap(
        (await _client.dio.post<dynamic>(
          '/api/chat/conversations',
          data: {
            'type': 'Support',
            'title': title,
          },
        )).data,
      );

  Future<Map<String, dynamic>> createBusinessConversation({
    required int businessId,
    required String title,
    int? reservationId,
    int? orderId,
  }) async => unwrapApiMap(
    (await _client.dio.post<dynamic>(
      '/api/chat/conversations',
      data: {
        'type': 'Business',
        'businessId': businessId,
        'reservationId': reservationId,
        'orderId': orderId,
        'title': title,
      },
    )).data,
  );

  Future<Map<String, dynamic>> sendText(String id, String body) async =>
      unwrapApiMap(
        (await _client.dio.post<dynamic>(
          '/api/chat/conversations/$id/messages',
          data: {
            'messageType': 'Text',
            'body': body,
            'attachmentUrl': null,
            'metadataJson': null,
          },
        )).data,
      );

  Future<Map<String, dynamic>> sendMedia(
    String id,
    String path,
    String fileName,
  ) async =>
      unwrapApiMap(
        (await _client.dio.post<dynamic>(
          '/api/chat/conversations/$id/messages/media',
          data: FormData.fromMap({
            'file': await MultipartFile.fromFile(path, filename: fileName),
          }),
        )).data,
      );

  Future<void> markAsRead(String id) async {
    await _client.dio.post<void>('/api/chat/conversations/$id/read');
  }

  Future<List<dynamic>> buttons() async => unwrapApiList(
    (await _client.dio.get<dynamic>('/api/chat/buttons')).data,
  );

  Future<Map<String, dynamic>> sendTypedMessage(
    String id, {
    required String messageType,
    String? body,
    String? metadataJson,
    String? attachmentUrl,
    String? mediaUrl,
    String? thumbnailUrl,
    String? storagePath,
    String? mediaType,
  }) async =>
      unwrapApiMap(
        (await _client.dio.post<dynamic>(
          '/api/chat/conversations/$id/messages',
          data: {
            'messageType': messageType,
            if (body != null) 'body': body,
            if (metadataJson != null) 'metadataJson': metadataJson,
            if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
            if (mediaUrl != null) 'mediaUrl': mediaUrl,
            if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
            if (storagePath != null) 'storagePath': storagePath,
            if (mediaType != null) 'mediaType': mediaType,
          },
        )).data,
      );
}
