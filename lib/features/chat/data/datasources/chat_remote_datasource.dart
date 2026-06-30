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

  Future<Map<String, dynamic>> createUserConversation({
    required String participantUserId,
  }) async =>
      unwrapApiMap(
        (await _client.dio.post<dynamic>(
          '/api/chat/conversations',
          data: {
            'type': 'Direct',
            'participantUserId':
                int.tryParse(participantUserId) ?? participantUserId,
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
  }) async =>
      unwrapApiMap(
        (await _client.dio.post<dynamic>(
          '/api/chat/conversations/$id/messages',
          data: {
            'messageType': messageType,
            'body': body,
            'attachmentUrl': attachmentUrl,
            'metadataJson': metadataJson,
          },
        )).data,
      );
}
