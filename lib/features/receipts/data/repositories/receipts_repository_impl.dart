import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/receipt.dart';
import '../../domain/repositories/receipts_repository.dart';
import '../datasources/receipts_remote_datasource.dart';

class ReceiptsRepositoryImpl implements ReceiptsRepository {
  const ReceiptsRepositoryImpl(this._remoteDataSource);
  final ReceiptsRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<Receipt>>> receipts() async {
    try {
      final items = await _remoteDataSource.receipts();
      return Success(items.map((item) => item.toDomain()).toList());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<Receipt>> receipt(String id) async {
    try {
      return Success((await _remoteDataSource.receipt(id)).toDomain());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
