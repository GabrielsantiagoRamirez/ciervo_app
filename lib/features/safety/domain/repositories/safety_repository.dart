import '../../../../core/result/result.dart';
import '../../data/models/safety_models.dart';

abstract interface class SafetyRepository {
  Future<Result<UserReportModel>> createReport({
    required ReportTargetType targetType,
    String? targetId,
    int? reportedUserId,
    required ReportReason reason,
    String? description,
  });

  Future<Result<void>> blockUser(int userId);

  Future<Result<void>> unblockUser(int userId);

  Future<Result<List<BlockedUserModel>>> blockedUsers();

  Future<Result<ContentBlockModel>> blockContent({
    required ReportTargetType targetType,
    required String targetId,
  });

  Future<Result<void>> unblockContent({
    required ReportTargetType targetType,
    required String targetId,
  });

  Future<Result<void>> refreshLocalFilters();
}
