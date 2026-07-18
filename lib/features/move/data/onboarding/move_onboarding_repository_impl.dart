import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/onboarding/move_onboarding_repository.dart';
import '../../domain/onboarding/move_onboarding_requests.dart';
import '../../domain/onboarding/move_onboarding_status.dart';
import 'move_onboarding_remote_datasource.dart';

class MoveOnboardingRepositoryImpl implements MoveOnboardingRepository {
  const MoveOnboardingRepositoryImpl(this._remote);

  final MoveOnboardingRemoteDataSource _remote;

  @override
  Future<Result<MoveDriverOnboardingStatus>> getStatus() =>
      _guard(_remote.getStatus);

  @override
  Future<Result<MoveDriverOnboardingStatus>> saveIdentity(
    MoveIdentityOnboardingRequest request, {
    required String idempotencyKey,
  }) => _guard(
    () => _remote.saveIdentity(request, idempotencyKey: idempotencyKey),
  );

  @override
  Future<Result<MoveDriverOnboardingStatus>> saveLicense(
    MoveLicenseOnboardingRequest request, {
    required String idempotencyKey,
  }) => _guard(
    () => _remote.saveLicense(request, idempotencyKey: idempotencyKey),
  );

  @override
  Future<Result<MoveDriverOnboardingStatus>> saveVehicle(
    MoveVehicleOnboardingRequest request, {
    required String idempotencyKey,
  }) => _guard(
    () => _remote.saveVehicle(request, idempotencyKey: idempotencyKey),
  );

  @override
  Future<Result<MoveDriverOnboardingStatus>> saveOperations(
    MoveOperationsOnboardingRequest request, {
    required String idempotencyKey,
  }) => _guard(
    () => _remote.saveOperations(request, idempotencyKey: idempotencyKey),
  );

  @override
  Future<Result<MoveDriverOnboardingStatus>> submit({
    required String idempotencyKey,
  }) => _guard(() => _remote.submit(idempotencyKey: idempotencyKey));

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
