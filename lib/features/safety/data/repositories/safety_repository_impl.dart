import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/repositories/safety_repository.dart';
import '../datasources/safety_remote_datasource.dart';
import '../models/safety_models.dart';
import '../services/safety_filter_cache.dart';

class SafetyRepositoryImpl implements SafetyRepository {
  SafetyRepositoryImpl(this._remote, this._cache);

  final SafetyRemoteDataSource _remote;
  final SafetyFilterCache _cache;

  @override
  Future<Result<UserReportModel>> createReport({
    required ReportTargetType targetType,
    String? targetId,
    int? reportedUserId,
    required ReportReason reason,
    String? description,
  }) =>
      _guard(() => _remote.createReport(
            targetType: targetType,
            targetId: targetId,
            reportedUserId: reportedUserId,
            reason: reason,
            description: description,
          ));

  @override
  Future<Result<void>> blockUser(int userId) => _guard(() async {
        await _remote.blockUser(userId);
        _cache.addBlockedUser(userId);
      });

  @override
  Future<Result<void>> unblockUser(int userId) => _guard(() async {
        await _remote.unblockUser(userId);
        _cache.removeBlockedUser(userId);
      });

  @override
  Future<Result<List<BlockedUserModel>>> blockedUsers() =>
      _guard(_remote.blockedUsers);

  @override
  Future<Result<ContentBlockModel>> blockContent({
    required ReportTargetType targetType,
    required String targetId,
  }) =>
      _guard(() async {
        final block = await _remote.blockContent(
          targetType: targetType,
          targetId: targetId,
        );
        _cache.addContentBlock(block);
        return block;
      });

  @override
  Future<Result<void>> unblockContent({
    required ReportTargetType targetType,
    required String targetId,
  }) =>
      _guard(() async {
        await _remote.unblockContent(
          targetType: targetType,
          targetId: targetId,
        );
        _cache.removeContentBlock(targetType, targetId);
      });

  @override
  Future<Result<void>> refreshLocalFilters() => _guard(() async {
        final users = await _remote.blockedUsers();
        final content = await _remote.myContentBlocks();
        _cache.replaceAll(
          blockedUserIds: users.map((e) => e.userId).toSet(),
          contentBlocks: content,
        );
      });

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
