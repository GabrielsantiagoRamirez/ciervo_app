import '../../../../core/location/app_location.dart';
import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../../../../core/experience/experience_mode.dart';
import '../dtos/business_summary_dto.dart';

abstract interface class DiscoveryRemoteDataSource {
  Future<List<BusinessSummaryDto>> nearbyBusinesses({
    required AppLocation location,
    required ExperienceMode experienceMode,
    required String countryCode,
    required String city,
    String? category,
    String? search,
    String? kidId,
  });

  Future<List<BusinessSummaryDto>> businessesByCategory(
    String category, {
    AppLocation? location,
    required ExperienceMode experienceMode,
    required String countryCode,
    required String city,
    String? kidId,
  });

  Future<List<BusinessSummaryDto>> businessesByCity(
    String city, {
    AppLocation? location,
    required ExperienceMode experienceMode,
    required String countryCode,
    String? kidId,
  });

  Future<List<BusinessSummaryDto>> searchBusinesses(
    String query, {
    AppLocation? location,
    required ExperienceMode experienceMode,
    required String countryCode,
    required String city,
    String? category,
    String? kidId,
  });
}

class DioDiscoveryRemoteDataSource implements DiscoveryRemoteDataSource {
  const DioDiscoveryRemoteDataSource(this._client);

  final NetworkClient _client;

  @override
  Future<List<BusinessSummaryDto>> nearbyBusinesses({
    required AppLocation location,
    required ExperienceMode experienceMode,
    required String countryCode,
    required String city,
    String? category,
    String? search,
    String? kidId,
  }) async {
    final categoryId = _categoryId(category);
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/businesses',
      queryParameters: {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'radiusKm': 25,
        'experienceMode': experienceMode.apiValue,
        'countryCode': countryCode,
        'page': 1,
        'pageSize': 30,
        'category': ?categoryId,
        'search': ?_nonEmpty(search),
        'kidId': ?kidId,
      },
    );
    return BusinessSummaryDto.listFromResponse(
      unwrapApiResponse(response.data),
    );
  }

  @override
  Future<List<BusinessSummaryDto>> businessesByCategory(
    String category, {
    AppLocation? location,
    required ExperienceMode experienceMode,
    required String countryCode,
    required String city,
    String? kidId,
  }) async {
    final categoryId = _categoryId(category);
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/businesses/by-category',
      queryParameters: {
        'category': ?categoryId,
        'experienceMode': experienceMode.apiValue,
        'countryCode': countryCode,
        if (location == null) 'city': city,
        if (location != null) ...{
          'latitude': location.latitude,
          'longitude': location.longitude,
          'radiusKm': 25,
        },
        'kidId': ?kidId,
      },
    );
    return BusinessSummaryDto.listFromResponse(
      unwrapApiResponse(response.data),
    );
  }

  @override
  Future<List<BusinessSummaryDto>> businessesByCity(
    String city, {
    AppLocation? location,
    required ExperienceMode experienceMode,
    required String countryCode,
    String? kidId,
  }) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/businesses/by-city',
      queryParameters: {
        'city': city,
        'experienceMode': experienceMode.apiValue,
        'countryCode': countryCode,
        if (location != null) ...{
          'latitude': location.latitude,
          'longitude': location.longitude,
          'radiusKm': 25,
        },
        'kidId': ?kidId,
      },
    );
    return BusinessSummaryDto.listFromResponse(
      unwrapApiResponse(response.data),
    );
  }

  @override
  Future<List<BusinessSummaryDto>> searchBusinesses(
    String query, {
    AppLocation? location,
    required ExperienceMode experienceMode,
    required String countryCode,
    required String city,
    String? category,
    String? kidId,
  }) async {
    final categoryId = _categoryId(category);
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/businesses/search',
      queryParameters: {
        'query': query,
        'experienceMode': experienceMode.apiValue,
        'countryCode': countryCode,
        'city': ?(location == null ? city : null),
        'category': ?categoryId,
        if (location != null) ...{
          'latitude': location.latitude,
          'longitude': location.longitude,
          'radiusKm': 25,
        },
        'kidId': ?kidId,
      },
    );
    return BusinessSummaryDto.listFromResponse(
      unwrapApiResponse(response.data),
    );
  }
}

int? _categoryId(String? value) {
  if (value == null || value == 'Top') return null;
  final parsed = int.tryParse(value);
  if (parsed != null) return parsed;
  return switch (value.toLowerCase().trim()) {
    'bar' => 1,
    'hoteles' || 'hotel' => 101,
    'restaurantes' || 'restaurante' => 102,
    'bares' => 103,
    'discotecas' || 'discoteca' => 104,
    'licorerias' || 'licoreria' => 105,
    'farmacias' || 'farmacia' => 106,
    'turismo' => 107,
    'transporte' => 108,
    _ => null,
  };
}

String? _nonEmpty(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
