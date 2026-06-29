import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response_unwrapper.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/result.dart';
import '../../chat/data/dtos/chat_dtos.dart';
import '../../chat/domain/entities/chat_conversation.dart';
import '../../chat/domain/entities/chat_message.dart';

class FamilyChatRepository {
  const FamilyChatRepository(this._client);
  final NetworkClient _client;

  Future<Result<List<ChatConversation>>> conversations() => _guard(() async {
    final response = await _client.dio.get<dynamic>('/api/family/conversations');
    return unwrapApiList(response.data)
        .whereType<Map>()
        .map((item) => conversationFromJson(Map<String, dynamic>.from(item)))
        .toList();
  });

  Future<Result<ChatConversation>> create({
    required String childId,
    required String participantUserId,
  }) => _guard(() async {
    final response = await _client.dio.post<dynamic>(
      '/api/family/conversations',
      data: {'childId': childId, 'participantUserId': participantUserId},
    );
    return conversationFromJson(unwrapApiMap(response.data));
  });

  Future<Result<List<ChatMessage>>> messages(String id) => _guard(() async {
    final response = await _client.dio.get<dynamic>(
      '/api/family/conversations/$id/messages',
    );
    return unwrapApiList(response.data)
        .whereType<Map>()
        .map((item) => messageFromJson(Map<String, dynamic>.from(item)))
        .toList();
  });

  Future<Result<ChatMessage>> send(String id, String body) => _guard(() async {
    final response = await _client.dio.post<dynamic>(
      '/api/family/conversations/$id/messages',
      data: {'body': body, 'messageType': 'Text'},
    );
    return messageFromJson(unwrapApiMap(response.data));
  });

  Future<Result<void>> markRead(String id) => _guard(() async {
    await _client.dio.post<void>('/api/family/conversations/$id/read');
  });

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
