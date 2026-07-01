import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../domain/entities/kid_registration.dart';
import '../datasources/kid_auth_remote_datasource.dart';

abstract interface class KidAuthRepository {
  Future<Result<AuthSession>> kidLogin({
    required String username,
    required String pin,
  });

  Future<Result<GuardianVerifyResult>> verifyGuardian({
    required String guardianEmail,
    String? guardianCiervoCode,
    int? guardianUserId,
  });

  Future<Result<AuthSession>> registerKid(KidSelfRegisterRequest request);
}

class KidAuthRepositoryImpl implements KidAuthRepository {
  const KidAuthRepositoryImpl(this._remoteDataSource);

  final KidAuthRemoteDataSource _remoteDataSource;

  @override
  Future<Result<AuthSession>> kidLogin({
    required String username,
    required String pin,
  }) async {
    try {
      return Success(
        (await _remoteDataSource.kidLogin(username: username, pin: pin))
            .toDomain(),
      );
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<GuardianVerifyResult>> verifyGuardian({
    required String guardianEmail,
    String? guardianCiervoCode,
    int? guardianUserId,
  }) async {
    try {
      return Success(
        await _remoteDataSource.verifyGuardian(
          KidVerifyGuardianRequest(
            guardianEmail: guardianEmail,
            guardianCiervoCode: guardianCiervoCode,
            guardianUserId: guardianUserId,
          ),
        ),
      );
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<AuthSession>> registerKid(
    KidSelfRegisterRequest request,
  ) async {
    try {
      return Success(
        (await _remoteDataSource.registerKid(request)).toDomain(),
      );
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
