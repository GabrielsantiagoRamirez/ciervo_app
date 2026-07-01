import '../errors/error_mapper.dart';
import '../network/api_response_unwrapper.dart';
import '../network/network_client.dart';
import '../result/result.dart';
import 'geocode_result.dart';

class GeoRepository {
  const GeoRepository(this._client);

  final NetworkClient _client;

  Future<Result<GeocodeResult>> reverse({
    required double latitude,
    required double longitude,
  }) =>
      _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/geo/reverse',
          queryParameters: {
            'lat': latitude,
            'lng': longitude,
          },
        );
        return GeocodeResult.fromJson(unwrapApiMap(response.data));
      });

  Future<Result<GeocodeResult>> geocodeAddress(String address) => _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/geo/geocode',
          queryParameters: {'address': address.trim()},
        );
        return GeocodeResult.fromJson(unwrapApiMap(response.data));
      });

  Future<Result<GeocodeResult>> resolve({
    String? address,
    double? latitude,
    double? longitude,
  }) =>
      _guard(() async {
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

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
