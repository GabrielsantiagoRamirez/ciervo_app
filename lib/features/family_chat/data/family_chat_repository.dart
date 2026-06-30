import 'package:dio/dio.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response_unwrapper.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/result.dart';
import '../../chat/data/dtos/chat_dtos.dart';
import '../../chat/domain/entities/chat_conversation.dart';
import '../../chat/domain/entities/chat_message.dart';
import '../../kids/data/dtos/child_profile_dto.dart';
import '../domain/entities/family_member.dart';

class FamilyChatRepository {
  const FamilyChatRepository(this._client);
  final NetworkClient _client;

  Future<Result<List<FamilyMember>>> members() => _guard(() async {
    final response = await _client.dio.get<dynamic>('/api/family/members');
    return unwrapApiList(response.data)
        .whereType<Map>()
        .map((item) => FamilyMember.fromJson(Map<String, dynamic>.from(item)))
        .where((member) => member.userId.isNotEmpty)
        .toList();
  });

  Future<Result<List<ChildProfileDto>>> children() => _guard(() async {
    final response = await _client.dio.get<dynamic>('/api/guardians/children');
    return ChildProfileDto.listFrom(unwrapApiResponse(response.data));
  });

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
      data: {
        'childId': int.tryParse(childId) ?? childId,
        'participantUserId': int.tryParse(participantUserId) ?? participantUserId,
      },
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

  Future<Result<ChatMessage>> sendText(String id, String body) =>
      _guard(() async {
        final response = await _client.dio.post<dynamic>(
          '/api/family/conversations/$id/messages',
          data: {'body': body, 'messageType': 'Text'},
        );
        return messageFromJson(unwrapApiMap(response.data));
      });

  Future<Result<ChatMessage>> sendMedia(
    String id, {
    required String path,
    required String fileName,
  }) => _guard(() async {
    final response = await _client.dio.post<dynamic>(
      '/api/family/conversations/$id/messages/media',
      data: FormData.fromMap({
        'file': await MultipartFile.fromFile(path, filename: fileName),
      }),
    );
    return messageFromJson(unwrapApiMap(response.data));
  });

  Future<Result<ChatMessage>> sendLocation(
    String id, {
    required double latitude,
    required double longitude,
    String? label,
  }) => _guard(() async {
    final metadata = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      if (label != null && label.isNotEmpty) 'label': label,
    };
    final response = await _client.dio.post<dynamic>(
      '/api/family/conversations/$id/messages',
      data: {
        'messageType': 'Location',
        'body': label ?? 'Ubicación compartida',
        'metadataJson': metadata,
      },
    );
    return messageFromJson(unwrapApiMap(response.data));
  });

  Future<Result<void>> markRead(String id) => _guard(() async {
    await _client.dio.post<void>('/api/family/conversations/$id/read');
  });

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return Failure(
          ErrorMapper.fromObject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: DioExceptionType.badResponse,
              error: error,
            ),
          ),
        );
      }
      return Failure(ErrorMapper.fromObject(error));
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
