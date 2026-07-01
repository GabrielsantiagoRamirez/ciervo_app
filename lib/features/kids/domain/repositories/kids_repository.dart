import '../../../../core/result/result.dart';
import '../entities/child_profile.dart';

abstract interface class KidsRepository {
  Future<Result<List<ChildProfile>>> children();
  Future<Result<ChildProfile>> child(String childId);
  Future<Result<ChildProfile>> createChild(Map<String, dynamic> data);
  Future<Result<ChildProfile>> updateChild(
    String childId,
    Map<String, dynamic> data,
  );
  Future<Result<void>> deleteChild(String childId);
  Future<Result<Map<String, dynamic>>> childOverview(String childId);
  Future<Result<List<dynamic>>> allowedBusinesses(String childId);
  Future<Result<List<dynamic>>> businessCandidates(
    String childId, {
    String? query,
    String? city,
    int? categoryId,
  });
  Future<Result<void>> saveAllowedBusinesses(
    String childId,
    List<String> businessIds,
  );
  Future<Result<List<dynamic>>> allowedCategories(String childId);
  Future<Result<List<dynamic>>> categoryCandidates(String childId);
  Future<Result<void>> saveAllowedCategories(
    String childId,
    List<int> categoryIds,
  );
  Future<Result<Map<String, dynamic>>> spendingLimits(String childId);
  Future<Result<Map<String, dynamic>>> updateSpendingLimits(
    String childId,
    Map<String, dynamic> data,
  );
  Future<Result<Map<String, dynamic>>> childWallet(String childId);
  Future<Result<List<dynamic>>> childWalletCards(String childId);
  Future<Result<List<dynamic>>> childWalletHistory(String childId);
  Future<Result<Map<String, dynamic>>> rechargeChildWallet({
    required String childId,
    required String cardId,
    required double amount,
    String? currency,
  });
  Future<Result<Map<String, dynamic>>> createChildWalletCard({
    required String childId,
    required String displayName,
    required String currency,
  });
  Future<Result<Map<String, dynamic>>> payKidsBusiness({
    required String childProfileId,
    required String businessId,
    required double amount,
    String? walletCardId,
    String? idempotencyKey,
    String? currency,
  });
  Future<Result<List<dynamic>>> payForMeRequests();
  Future<Result<void>> approvePayForMeRequest(int requestId);
  Future<Result<void>> rejectPayForMeRequest(int requestId, {String? reason});
  Future<Result<ChildProfile>> linkChild({
    required String kidsPublicId,
    required int relationshipType,
    bool isPrimaryGuardian = false,
  });
  Future<Result<ChildProfile>> uploadChildPhoto({
    required String childId,
    required String path,
    required String fileName,
  });

  Future<Result<Map<String, dynamic>>> createKidAccount({
    required String childId,
    required String username,
    required String pin,
  });

  Future<Result<void>> updateKidPin({
    required String childId,
    required String pin,
  });
}
