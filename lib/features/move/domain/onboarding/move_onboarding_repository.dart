import '../../../../core/result/result.dart';
import 'move_onboarding_requests.dart';
import 'move_onboarding_status.dart';

abstract interface class MoveOnboardingRepository {
  Future<Result<MoveDriverOnboardingStatus>> getStatus();

  Future<Result<MoveDriverOnboardingStatus>> saveIdentity(
    MoveIdentityOnboardingRequest request, {
    required String idempotencyKey,
  });

  Future<Result<MoveDriverOnboardingStatus>> saveLicense(
    MoveLicenseOnboardingRequest request, {
    required String idempotencyKey,
  });

  Future<Result<MoveDriverOnboardingStatus>> saveVehicle(
    MoveVehicleOnboardingRequest request, {
    required String idempotencyKey,
  });

  Future<Result<MoveDriverOnboardingStatus>> saveOperations(
    MoveOperationsOnboardingRequest request, {
    required String idempotencyKey,
  });

  Future<Result<MoveDriverOnboardingStatus>> submit({
    required String idempotencyKey,
  });
}
