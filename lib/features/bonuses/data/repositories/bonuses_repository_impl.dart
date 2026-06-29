import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/bonus.dart';
import '../../domain/repositories/bonuses_repository.dart';
import '../datasources/bonuses_remote_datasource.dart';

class BonusesRepositoryImpl implements BonusesRepository {
  const BonusesRepositoryImpl(this._remote);

  final BonusesRemoteDataSource _remote;

  @override
  Future<Result<List<Bonus>>> catalog(BonusFilters filters) =>
      _guard(() async {
        final dtos = await _remote.catalog(filters);
        return dtos.map((dto) => dto.toEntity()).toList();
      });

  @override
  Future<Result<Bonus>> detail(String bonusId) => _guard(() async {
        final dto = await _remote.detail(bonusId);
        return dto.toEntity();
      });

  @override
  Future<Result<Bonus>> claim(String bonusId) => _guard(() async {
        final dto = await _remote.claim(bonusId);
        return dto.toEntity();
      });

  @override
  Future<Result<Bonus>> redeem(String bonusId) => _guard(() async {
        final dto = await _remote.redeem(bonusId);
        return dto.toEntity();
      });

  @override
  Future<Result<List<Bonus>>> myBonuses({int page = 1, int pageSize = 30}) =>
      _guard(() async {
        final dtos = await _remote.myBonuses(page: page, pageSize: pageSize);
        return dtos.map((dto) => dto.toEntity()).toList();
      });

  @override
  Future<Result<List<Bonus>>> history({int page = 1, int pageSize = 30}) =>
      _guard(() async {
        final dtos = await _remote.history(page: page, pageSize: pageSize);
        return dtos.map((dto) => dto.toEntity()).toList();
      });

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
