import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../../domain/entities/global_search_models.dart';

class GlobalSearchRemoteDataSource {
  const GlobalSearchRemoteDataSource(this._client);

  final NetworkClient _client;

  Future<GlobalSearchResult> search({
    String? query,
    double? latitude,
    double? longitude,
    double? radiusKm,
    int limit = 20,
    String? types,
  }) async {
    final q = query?.trim() ?? '';
    final cappedLimit = limit.clamp(1, 50);

    final response = await _client.dio.get<dynamic>(
      '/api/search',
      queryParameters: {
        if (q.length >= 2) 'q': q,
        'latitude': ?latitude,
        'longitude': ?longitude,
        'radiusKm': ?radiusKm,
        'limit': cappedLimit,
        if (types != null && types.trim().isNotEmpty) 'types': types.trim(),
      },
    );

    final value = unwrapApiResponse(response.data);
    if (value is Map<String, dynamic>) {
      return GlobalSearchResult.fromJson(value);
    }
    if (value is Map) {
      return GlobalSearchResult.fromJson(Map<String, dynamic>.from(value));
    }
    if (value is List) {
      return GlobalSearchResult(
        items: value
            .whereType<Map>()
            .map(
              (e) => GlobalSearchItem.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList(),
        query: q,
        total: value.length,
      );
    }
    return const GlobalSearchResult(items: []);
  }
}
