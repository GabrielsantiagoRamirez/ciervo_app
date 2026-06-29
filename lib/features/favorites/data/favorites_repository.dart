import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response_unwrapper.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/result.dart';
import '../domain/entities/favorite_business.dart';

class FavoritesRepository {
  const FavoritesRepository(this._client);

  final NetworkClient _client;

  Future<Result<List<FavoriteBusiness>>> favorites({
    int page = 1,
    int pageSize = 30,
  }) =>
      _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/users/me/favorites',
          queryParameters: {'page': page, 'pageSize': pageSize},
        );
        return _list(response.data).map(_favoriteFromJson).toList();
      });

  Future<Result<bool>> exists(String businessId) => _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/users/me/favorites/$businessId/exists',
        );
        final value = unwrapApiResponse(response.data);
        if (value is bool) return value;
        if (value is Map<String, dynamic>) {
          final source = value['exists'] ?? value['isFavorite'] ?? value['value'];
          if (source is bool) return source;
          return source?.toString().toLowerCase() == 'true';
        }
        return value?.toString().toLowerCase() == 'true';
      });

  Future<Result<void>> add(String businessId) => _guard(() async {
        await _client.dio.post<void>('/api/users/me/favorites/$businessId');
      });

  Future<Result<void>> remove(String businessId) => _guard(() async {
        await _client.dio.delete<void>('/api/users/me/favorites/$businessId');
      });

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}

FavoriteBusiness _favoriteFromJson(Map<String, dynamic> json) {
  final business = json['business'] is Map
      ? Map<String, dynamic>.from(json['business'] as Map)
      : json['businessSummary'] is Map
          ? Map<String, dynamic>.from(json['businessSummary'] as Map)
          : json;
  return FavoriteBusiness(
    id: _string(business, const ['id', 'businessId']),
    name: _string(business, const ['name', 'businessName', 'title']),
    category: _string(business, const ['category', 'categoryName', 'type']),
    rating: _double(business, const ['rating', 'score']),
    distanceKm: _double(business, const ['distanceKm', 'distance']),
    imageUrl: _mediaUrl(business),
    businessCategoryId: _intOrNull(
      business['businessCategoryId'] ??
          business['categoryId'] ??
          business['businessCategory']?['id'],
    ),
    priceLevel: _string(business, const ['priceLevel', 'priceRange']),
    city: _stringOrNull(business, const ['city', 'cityName']),
    addedAt: DateTime.tryParse(
      '${json['createdAt'] ?? json['addedAt'] ?? json['favoriteAt'] ?? ''}',
    ),
  );
}

List<Map<String, dynamic>> _list(dynamic response) {
  final source = unwrapApiResponse(response);
  final items = source is List
      ? source
      : source is Map<String, dynamic> && source['items'] is List
          ? source['items'] as List
          : const [];
  return items
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

String _string(Map<String, dynamic> json, List<String> keys) =>
    _stringOrNull(json, keys) ?? '';

String? _stringOrNull(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().isNotEmpty) return value.toString();
  }
  return null;
}

double _double(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toDouble();
    final parsed = double.tryParse('${value ?? ''}');
    if (parsed != null) return parsed;
  }
  return 0;
}

int? _intOrNull(dynamic value) => value is int ? value : int.tryParse('$value');

String _mediaUrl(Map<String, dynamic> json) {
  final direct = _string(json, const [
    'imageMediaId',
    'coverMediaId',
    'logoMediaId',
    'eventImageMediaId',
    'promotionImageMediaId',
    'mediaId',
    'imageUrl',
  ]);
  if (direct.isNotEmpty) return direct;
  for (final key in const ['cover', 'logo', 'image', 'eventImage']) {
    final media = json[key];
    if (media is Map) {
      final id = _string(Map<String, dynamic>.from(media), const ['id', 'mediaId']);
      if (id.isNotEmpty) return id;
    }
  }
  return '';
}
