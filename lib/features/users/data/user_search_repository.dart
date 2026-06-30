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
          'page': page,
          'pageSize': pageSize,
        },
      );
      final items = unwrapApiList(response.data)
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
