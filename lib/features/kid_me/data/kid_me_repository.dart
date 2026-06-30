import 'package:dio/dio.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response_unwrapper.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/result.dart';
import '../../chat/data/dtos/chat_dtos.dart';
import '../../chat/domain/entities/chat_conversation.dart';
import '../../chat/domain/entities/chat_message.dart';

class KidMeRepository {
  const KidMeRepository(this._client);

  final NetworkClient _client;

  Future<Result<Map<String, dynamic>>> home() => _guard(() async {
        final response = await _client.dio.get<dynamic>('/api/kids/me/home');
        return unwrapApiMap(response.data);
      });

  Future<Result<Map<String, dynamic>>> wallet() => _guard(() async {
        final response = await _client.dio.get<dynamic>('/api/kids/me/wallet');
        return unwrapApiMap(response.data);
      });

  Future<Result<List<Map<String, dynamic>>>> allowedBusinesses({
    String? query,
    String? city,
    int? categoryId,
    int page = 1,
    int pageSize = 30,
  }) =>
      _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/kids/me/allowed-businesses',
          queryParameters: {
            if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
            if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
            if (categoryId != null) 'categoryId': categoryId,
            'page': page,
            'pageSize': pageSize,
          },
        );
        final value = unwrapApiResponse(response.data);
        if (value is List) {
          return value
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        if (value is Map && value['items'] is List) {
          return (value['items'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        return const [];
      });

  Future<Result<Map<String, dynamic>>> profile() => _guard(() async {
        final response =
            await _client.dio.get<dynamic>('/api/kids/me/profile');
        return unwrapApiMap(response.data);
      });

  Future<Result<ChatConversation>> familyChat() => _guard(() async {
        final response =
            await _client.dio.get<dynamic>('/api/kids/me/family-chat');
        return conversationFromJson(unwrapApiMap(response.data));
      });

  Future<Result<List<ChatMessage>>> messages(String conversationId) =>
      _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/family/conversations/$conversationId/messages',
        );
        return unwrapApiList(response.data)
            .whereType<Map>()
            .map((item) => messageFromJson(Map<String, dynamic>.from(item)))
            .toList();
      });

  Future<Result<void>> shareLocation({
    required double latitude,
    required double longitude,
  }) =>
      _guard(() async {
        await _client.dio.post<void>(
          '/api/kids/me/location/share',
          data: {'latitude': latitude, 'longitude': longitude},
        );
      });

  Future<Result<Map<String, dynamic>>> requestPayForMe({
    required String businessId,
    required double amount,
    String? description,
    double? latitude,
    double? longitude,
    String? address,
  }) =>
      _guard(() async {
        final response = await _client.dio.post<dynamic>(
          '/api/kids/me/pay-for-me/request',
          data: {
            'businessId': int.tryParse(businessId) ?? businessId,
            'amount': amount,
            'currency': 'COP',
            if (description != null && description.trim().isNotEmpty)
              'description': description.trim(),
            if (latitude != null && longitude != null)
              'location': {
                'latitude': latitude,
                'longitude': longitude,
                if (address != null && address.trim().isNotEmpty)
                  'address': address.trim(),
              },
          },
        );
        return unwrapApiMap(response.data);
      });

  Future<Result<List<Map<String, dynamic>>>> payForMeRequests() =>
      _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/kids/me/pay-for-me/requests',
        );
        final value = unwrapApiResponse(response.data);
        if (value is List) {
          return value
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        if (value is Map && value['items'] is List) {
          return (value['items'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        return const [];
      });

  Future<Result<Map<String, dynamic>>> createNfcSession({
    required String businessId,
    required double amount,
  }) =>
      _guard(() async {
        final response = await _client.dio.post<dynamic>(
          '/api/kids/me/nfc/sessions',
          data: {
            'businessId': int.tryParse(businessId) ?? businessId,
            'amount': amount,
            'currency': 'COP',
          },
        );
        return unwrapApiMap(response.data);
      });

  Future<Result<Map<String, dynamic>>> nfcSession(int sessionId) =>
      _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/kids/me/nfc/sessions/$sessionId',
        );
        return unwrapApiMap(response.data);
      });

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Success(await run());
    } on DioException catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
