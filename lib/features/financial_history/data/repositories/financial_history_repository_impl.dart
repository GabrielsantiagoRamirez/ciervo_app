import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/financial_history_item.dart';
import '../../domain/repositories/financial_history_repository.dart';
import '../datasources/financial_history_remote_datasource.dart';

class FinancialHistoryRepositoryImpl implements FinancialHistoryRepository {
  const FinancialHistoryRepositoryImpl(this._remoteDataSource);
  final FinancialHistoryRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<FinancialHistoryItem>>> history() async {
    try {
      final items = await _remoteDataSource.history();
      return Success(items.map((item) => item.toDomain()).toList());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
