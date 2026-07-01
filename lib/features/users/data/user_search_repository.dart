import 'package:dio/dio.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response_unwrapper.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/result.dart';
import '../domain/entities/user_search_result.dart';

class UserSearchRepository {
  const UserSearchRepository(this._client);

  final NetworkClient _client;

  Future<Result<List<UserSearchResult>>> search({
    required String query,
    String? country,
    bool includeOtherCountries = false,
    double? latitude,
    double? longitude,
    String sortBy = 'distance',
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _client.dio.get<dynamic>(
        '/api/users/search',
        queryParameters: {
          'q': query,
          if (country != null && country.isNotEmpty) 'country': country,
          'includeOtherCountries': includeOtherCountries,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (latitude != null && longitude != null) 'sortBy': sortBy,
          'page': page,
          'pageSize': pageSize,
        },
      );
      final value = unwrapApiResponse(response.data);
      final itemsRaw = value is Map
          ? (value['items'] ?? value['Items'] ?? value)
          : value;
      final items = (itemsRaw is List ? itemsRaw : unwrapApiList(response.data))
          .whereType<Map>()
          .map((item) => UserSearchResult.fromJson(Map<String, dynamic>.from(item)))
          .where((user) => user.userId.isNotEmpty)
          .toList();
      return Success(items);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return const Success([]);
      }
      return Failure(ErrorMapper.fromObject(error));
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  Future<Result<List<UserSearchResult>>> searchByPhones({
    required List<String> phones,
    String? country,
  }) async {
    try {
      final response = await _client.dio.post<dynamic>(
        '/api/users/search/by-phones',
        data: {
          'phones': phones,
          if (country != null && country.isNotEmpty) 'country': country,
        },
      );
      final value = unwrapApiResponse(response.data);
      final itemsRaw = value is Map
          ? (value['items'] ?? value['Items'] ?? value)
          : value;
      final items = (itemsRaw is List ? itemsRaw : unwrapApiList(response.data))
          .whereType<Map>()
          .map((item) => UserSearchResult.fromJson(Map<String, dynamic>.from(item)))
          .where((user) => user.userId.isNotEmpty)
          .toList();
      return Success(items);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return const Success([]);
      }
      return Failure(ErrorMapper.fromObject(error));
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
