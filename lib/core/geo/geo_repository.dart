import '../errors/error_mapper.dart';
import '../network/api_response_unwrapper.dart';
import '../network/network_client.dart';
import '../result/result.dart';
import 'geo_autocomplete_models.dart';
import 'geocode_result.dart';

class GeoRepository {
  const GeoRepository(this._client);

  final NetworkClient _client;

  Future<Result<GeocodeResult>> reverse({
    required double latitude,
    required double longitude,
  }) => _guard(() async {
    final response = await _client.dio.get<dynamic>(
      '/api/geo/reverse',
      queryParameters: {'lat': latitude, 'lng': longitude},
    );
    return GeocodeResult.fromJson(unwrapApiMap(response.data));
  });

  Future<Result<GeocodeResult>> geocodeAddress(String address) =>
      _guard(() async {
        final q = address.trim();
        final response = await _client.dio.get<dynamic>(
          '/api/geo/geocode',
          queryParameters: {'q': q},
        );
        return GeocodeResult.fromJson(unwrapApiMap(response.data));
      });

  Future<Result<GeocodeResult>> resolve({
    String? address,
    double? latitude,
    double? longitude,
  }) => _guard(() async {
    final response = await _client.dio.post<dynamic>(
      '/api/geo/resolve',
      data: {
        if (address != null && address.trim().isNotEmpty)
          'address': address.trim(),
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );
    return GeocodeResult.fromJson(unwrapApiMap(response.data));
  });

  /// Autocomplete Places (Google / OSM fallback en backend).
  Future<Result<List<GeoAutocompleteItem>>> autocomplete({
    required String query,
    double? latitude,
    double? longitude,
    double? radiusKm,
    String? country,
    int limit = 8,
    String? sessionToken,
  }) => _guard(() async {
    final q = query.trim();
    if (q.length < 2) return const <GeoAutocompleteItem>[];
    final params = <String, dynamic>{'q': q, 'limit': limit.clamp(1, 15)};
    if (latitude != null) params['latitude'] = latitude;
    if (longitude != null) params['longitude'] = longitude;
    if (radiusKm != null) params['radiusKm'] = radiusKm;
    if (country != null && country.trim().isNotEmpty) {
      params['country'] = country.trim().toUpperCase();
    }
    if (sessionToken != null && sessionToken.isNotEmpty) {
      params['sessionToken'] = sessionToken;
    }
    final response = await _client.dio.get<dynamic>(
      '/api/geo/autocomplete',
      queryParameters: params,
    );
    final value = unwrapApiResponse(response.data);
    final raw = value is Map
        ? (value['items'] ?? value['Items'] ?? value['predictions'])
        : value;
    if (raw is! List) return const <GeoAutocompleteItem>[];
    return raw
        .whereType<Map>()
        .map((e) => GeoAutocompleteItem.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.placeId.isNotEmpty || e.hasCoordinates)
        .toList();
  });

  /// Detalle de lugar (lat/lng) al elegir una sugerencia.
  Future<Result<GeoPlaceDetails>> placeDetails({
    required String placeId,
    String? sessionToken,
  }) => _guard(() async {
    final response = await _client.dio.get<dynamic>(
      '/api/geo/place',
      queryParameters: {
        'placeId': placeId,
        if (sessionToken != null && sessionToken.isNotEmpty)
          'sessionToken': sessionToken,
      },
    );
    return GeoPlaceDetails.fromJson(unwrapApiMap(response.data));
  });

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
