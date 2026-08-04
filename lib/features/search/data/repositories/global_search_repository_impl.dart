import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/global_search_models.dart';
import '../../domain/repositories/global_search_repository.dart';
import '../datasources/global_search_remote_datasource.dart';

class GlobalSearchRepositoryImpl implements GlobalSearchRepository {
  const GlobalSearchRepositoryImpl(this._remote);

  final GlobalSearchRemoteDataSource _remote;

  @override
  Future<Result<GlobalSearchResult>> search({
    String? query,
    double? latitude,
    double? longitude,
    double? radiusKm,
    int limit = 20,
    String? types,
  }) async {
    try {
      final q = query?.trim() ?? '';
      if (q.length < 2 && (latitude == null || longitude == null)) {
        return Failure(
          Exception(
            'Escribe al menos 2 caracteres o activa la ubicación para buscar cerca.',
          ),
        );
      }
      final result = await _remote.search(
        query: query,
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        limit: limit,
        types: types,
      );
      return Success(result);
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
