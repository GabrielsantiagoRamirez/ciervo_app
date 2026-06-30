import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/child_profile.dart';
import '../../domain/repositories/kids_repository.dart';
import '../datasources/kids_remote_datasource.dart';

class KidsRepositoryImpl implements KidsRepository {
  const KidsRepositoryImpl(this._remoteDataSource);

  final KidsRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<ChildProfile>>> children() async {
    try {
      final items = await _remoteDataSource.children();
      return Success(items.map((item) => item.toDomain()).toList());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<ChildProfile>> child(String childId) async {
    try {
      return Success((await _remoteDataSource.child(childId)).toDomain());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<ChildProfile>> createChild(Map<String, dynamic> data) async {
    try {
      return Success((await _remoteDataSource.createChild(data)).toDomain());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<ChildProfile>> updateChild(
    String childId,
    Map<String, dynamic> data,
  ) async {
    try {
      return Success(
        (await _remoteDataSource.updateChild(childId, data)).toDomain(),
      );
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void>> deleteChild(String childId) async {
    try {
      await _remoteDataSource.deleteChild(childId);
      return const Success<void>(null);
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> childOverview(String childId) async {
    try {
      final results = await Future.wait<dynamic>([
        _remoteDataSource.allowedCategories(childId),
        _remoteDataSource.allowedBusinesses(childId),
      ]);
      return Success({
        'allowedCategories': results[0],
        'allowedBusinesses': results[1],
      });
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<dynamic>>> businessCandidates(
    String childId, {
    String? query,
    String? city,
    int? categoryId,
  }) async {
    try {
      return Success(
        await _remoteDataSource.businessCandidates(
          childId,
          query: query,
          city: city,
          categoryId: categoryId,
        ),
      );
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<dynamic>>> categoryCandidates(String childId) async {
    try {
      return Success(await _remoteDataSource.categoryCandidates(childId));
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<dynamic>>> allowedCategories(String childId) async {
    try {
      return Success(await _remoteDataSource.allowedCategories(childId));
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void>> saveAllowedCategories(
    String childId,
    List<int> categoryIds,
  ) async {
    try {
      await _remoteDataSource.saveAllowedCategories(childId, categoryIds);
      return const Success<void>(null);
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<dynamic>>> allowedBusinesses(String childId) async {
    try {
      return Success(await _remoteDataSource.allowedBusinesses(childId));
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void>> saveAllowedBusinesses(
    String childId,
    List<String> businessIds,
  ) async {
    try {
      await _remoteDataSource.saveAllowedBusinesses(childId, businessIds);
      return const Success<void>(null);
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> spendingLimits(String childId) async {
    try {
      return Success(await _remoteDataSource.spendingLimits(childId));
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> childWallet(String childId) async {
    try {
      return Success(await _remoteDataSource.childWallet(childId));
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> updateSpendingLimits(
    String childId,
    Map<String, dynamic> data,
  ) async {
    try {
      return Success(
        await _remoteDataSource.updateSpendingLimits(childId, data),
      );
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<dynamic>>> childWalletCards(String childId) async {
    try {
      return Success(await _remoteDataSource.childWalletCards(childId));
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<dynamic>>> childWalletHistory(String childId) async {
    try {
      return Success(await _remoteDataSource.childWalletHistory(childId));
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> rechargeChildWallet({
    required String childId,
    required String cardId,
    required double amount,
  }) async {
    try {
      return Success(
        await _remoteDataSource.rechargeChildWallet(
          childId: childId,
          cardId: cardId,
          amount: amount,
        ),
      );
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> createChildWalletCard({
    required String childId,
    required String displayName,
    required String currency,
  }) async {
    try {
      return Success(
        await _remoteDataSource.createChildWalletCard(
          childId: childId,
          displayName: displayName,
          currency: currency,
        ),
      );
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> payKidsBusiness({
    required String childProfileId,
    required String businessId,
    required double amount,
    String? walletCardId,
    String? idempotencyKey,
  }) async {
    try {
      return Success(
        await _remoteDataSource.payKidsBusiness(
          childProfileId: childProfileId,
          businessId: businessId,
          amount: amount,
          walletCardId: walletCardId,
          idempotencyKey: idempotencyKey,
        ),
      );
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
