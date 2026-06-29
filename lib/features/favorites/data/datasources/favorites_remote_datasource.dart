import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../../domain/entities/favorite_filters.dart';
import '../dtos/favorite_business_dto.dart';

abstract interface class FavoritesRemoteDataSource {
  Future<List<FavoriteBusinessDto>> list(FavoriteFilters filters);

  Future<bool> check(String businessId);

  Future<void> add(String businessId);

  Future<void> remove(String businessId);
}

class DioFavoritesRemoteDataSource implements FavoritesRemoteDataSource {
  const DioFavoritesRemoteDataSource(this._client);

  final NetworkClient _client;

  static const _base = '/api/users/me/favorite-businesses';

  @override
  Future<List<FavoriteBusinessDto>> list(FavoriteFilters filters) async {
    final response = await _client.dio.get<dynamic>(
      _base,
      queryParameters: filters.toQueryParameters(),
    );
    return FavoriteBusinessDto.listFromResponse(response.data);
  }

  @override
  Future<bool> check(String businessId) async {
    final response = await _client.dio.get<dynamic>('$_base/check/$businessId');
    final value = unwrapApiResponse(response.data);
    if (value is bool) return value;
    if (value is Map<String, dynamic>) {
      final source = value['isFavorite'] ?? value['exists'] ?? value['value'];
      if (source is bool) return source;
      return source?.toString().toLowerCase() == 'true';
    }
    return value?.toString().toLowerCase() == 'true';
  }

  @override
  Future<void> add(String businessId) async {
    await _client.dio.post<void>('$_base/$businessId');
  }

  @override
  Future<void> remove(String businessId) async {
    await _client.dio.delete<void>('$_base/$businessId');
  }
}
