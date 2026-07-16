import '../../../../core/errors/error_mapper.dart';
import '../../../../core/experience/experience_mode.dart';
import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/business_category.dart';

class BusinessCategoriesRepository {
  const BusinessCategoriesRepository(this._client);

  final NetworkClient _client;

  Future<Result<List<BusinessCategory>>> all({
    ExperienceMode? experienceMode,
  }) async {
    try {
      final response = await _client.dio.get<dynamic>(
        '/api/business-categories',
        queryParameters: {
          if (experienceMode != null)
            'experienceMode': experienceMode.apiValue,
        },
      );
      final categories =
          unwrapApiList(response.data)
              .whereType<Map<String, dynamic>>()
              .map(_fromJson)
              .where((category) => category.active)
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
      return Success(categories);
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}

BusinessCategory _fromJson(Map<String, dynamic> json) => BusinessCategory(
  id: _int(json['id'] ?? json['businessCategoryId']),
  code: _string(json['code']),
  name: _string(json['name'] ?? json['displayName']),
  active: json['active'] != false && json['isActive'] != false,
  experienceBucket: _bucket(
    json['experienceBucket'] ?? json['bucket'] ?? json['experienceMode'],
  ),
);

String _bucket(dynamic value) {
  final raw = value?.toString().trim().toLowerCase() ?? '';
  return switch (raw) {
    'day' || 'dia' || 'día' => 'day',
    'night' || 'noche' => 'night',
    '24h' || 'allday' || 'all_day' || 'todo' => 'allday',
    _ => 'allday',
  };
}

int _int(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;

String _string(dynamic value) => value?.toString() ?? '';
