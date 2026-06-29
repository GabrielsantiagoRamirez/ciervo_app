import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/favorite_business.dart';
import '../../domain/entities/favorite_filters.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/favorites_remote_datasource.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  const FavoritesRepositoryImpl(this._remote);

  final FavoritesRemoteDataSource _remote;

  @override
  Future<Result<List<FavoriteBusiness>>> list(FavoriteFilters filters) =>
      _guard(() async {
        final dtos = await _remote.list(filters);
        return dtos.map((dto) => dto.toEntity()).toList();
      });

  @override
  Future<Result<bool>> check(String businessId) =>
      _guard(() => _remote.check(businessId));

  @override
  Future<Result<void>> add(String businessId) =>
      _guard(() => _remote.add(businessId));

  @override
  Future<Result<void>> remove(String businessId) =>
      _guard(() => _remote.remove(businessId));

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
