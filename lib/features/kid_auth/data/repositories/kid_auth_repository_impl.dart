import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../datasources/kid_auth_remote_datasource.dart';

abstract interface class KidAuthRepository {
  Future<Result<AuthSession>> kidLogin({
    required String username,
    required String pin,
  });
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
}
