import 'package:dio/dio.dart';

import '../../../core/country/country_registration.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response_unwrapper.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/result.dart';
import '../../../core/utils/idempotency_key.dart';
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

  Future<Result<List<Map<String, dynamic>>>> tutors() async {
    final result = await profile();
    return result.when(
      success: (data) => Success(_parseTutors(data)),
      failure: Failure.new,
    );
  }

  List<Map<String, dynamic>> _parseTutors(Map<String, dynamic> profile) {
    for (final key in const ['guardians', 'tutors', 'familyTutors']) {
      final raw = profile[key];
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }
    return const [];
  }

  Future<Result<Map<String, dynamic>>> updateDisplayName(String displayName) =>
      _guard(() async {
        final response = await _client.dio.patch<dynamic>(
          '/api/kids/me/profile',
          data: {'displayName': displayName.trim()},
        );
        return unwrapApiMap(response.data);
      });

  Future<Result<Map<String, dynamic>>> uploadPhoto({
    required String path,
    required String fileName,
  }) =>
      _guard(() async {
        final response = await _client.dio.post<dynamic>(
          '/api/kids/me/photo',
          data: FormData.fromMap({
            'file': await MultipartFile.fromFile(path, filename: fileName),
          }),
        );
        return unwrapApiMap(response.data);
      });

  Future<Result<Map<String, dynamic>>> requestPayForMe({
    required double amount,
    String? businessId,
    String? description,
    String? currency,
    String? country,
    String? requestedToTutorId,
    String? commerceCiervoId,
    String? method,
    double? latitude,
    double? longitude,
    String? address,
    bool shareInFamilyChat = false,
  }) =>
      _guard(() async {
        final resolvedCurrency =
            currency ?? CountryRegistration.currencyForCountry(country ?? 'CO');
        final response = await _client.dio.post<dynamic>(
          '/api/kids/me/pay-for-me/request',
          data: {
            if (businessId != null && businessId.isNotEmpty)
              'businessId': int.tryParse(businessId) ?? businessId,
            'amount': amount,
            'currency': resolvedCurrency,
            if (country != null && country.isNotEmpty) 'country': country,
            if (description != null && description.trim().isNotEmpty)
              'description': description.trim(),
            if (requestedToTutorId != null && requestedToTutorId.isNotEmpty)
              'requestedToTutorId':
                  int.tryParse(requestedToTutorId) ?? requestedToTutorId,
            if (commerceCiervoId != null && commerceCiervoId.isNotEmpty)
              'commerceCiervoId': commerceCiervoId,
            if (method != null && method.isNotEmpty) 'method': method,
            if (shareInFamilyChat) 'shareInFamilyChat': true,
            'idempotencyKey': IdempotencyKey.generate('kid-pay-for-me'),
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
