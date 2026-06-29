import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../../domain/entities/bonus.dart';
import '../dtos/bonus_dto.dart';

abstract interface class BonusesRemoteDataSource {
  Future<List<BonusDto>> catalog(BonusFilters filters);

  Future<BonusDto> detail(String bonusId);

  Future<BonusDto> claim(String bonusId);

  Future<BonusDto> redeem(String bonusId);

  Future<List<BonusDto>> myBonuses({int page = 1, int pageSize = 30});

  Future<List<BonusDto>> history({int page = 1, int pageSize = 30});
}

class DioBonusesRemoteDataSource implements BonusesRemoteDataSource {
  const DioBonusesRemoteDataSource(this._client);

  final NetworkClient _client;

  @override
  Future<List<BonusDto>> catalog(BonusFilters filters) async {
    final response = await _client.dio.get<dynamic>(
      '/api/bonuses',
      queryParameters: filters.toQueryParameters(),
    );
    return BonusDto.listFromResponse(response.data);
  }

  @override
  Future<BonusDto> detail(String bonusId) async {
    final response = await _client.dio.get<dynamic>('/api/bonuses/$bonusId');
    return BonusDto.fromJson(_map(unwrapApiResponse(response.data)));
  }

  @override
  Future<BonusDto> claim(String bonusId) async {
    final response =
        await _client.dio.post<dynamic>('/api/bonuses/$bonusId/claim');
    return BonusDto.fromJson(_map(unwrapApiResponse(response.data)));
  }

  @override
  Future<BonusDto> redeem(String bonusId) async {
    final response =
        await _client.dio.post<dynamic>('/api/bonuses/$bonusId/redeem');
    return BonusDto.fromJson(_map(unwrapApiResponse(response.data)));
  }

  @override
  Future<List<BonusDto>> myBonuses({int page = 1, int pageSize = 30}) async {
    final response = await _client.dio.get<dynamic>(
      '/api/users/me/bonuses',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return BonusDto.listFromResponse(response.data);
  }

  @override
  Future<List<BonusDto>> history({int page = 1, int pageSize = 30}) async {
    final response = await _client.dio.get<dynamic>(
      '/api/users/me/bonuses/history',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return BonusDto.listFromResponse(response.data);
  }
}

Map<String, dynamic> _map(dynamic value) => value is Map<String, dynamic>
    ? value
    : value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{'id': '$value'};
