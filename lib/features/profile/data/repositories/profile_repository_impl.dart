import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../dtos/update_profile_request_dto.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remoteDataSource);

  final ProfileRemoteDataSource _remoteDataSource;

  @override
  Future<Result<UserProfile>> getMe() async {
    try {
      final profile = await _remoteDataSource.getMe();
      return Success(profile.toDomain());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<UserProfile>> updateMe({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
  }) async {
    try {
      final profile = await _remoteDataSource.updateMe(
        UpdateProfileRequestDto(
          firstName: firstName,
          lastName: lastName,
          email: email,
          phone: phone,
        ),
      );
      return Success(profile.toDomain());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<String>> uploadPhoto({
    required String path,
    required String fileName,
  }) async {
    try {
      return Success(await _remoteDataSource.uploadPhoto(
        path: path,
        fileName: fileName,
      ));
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
