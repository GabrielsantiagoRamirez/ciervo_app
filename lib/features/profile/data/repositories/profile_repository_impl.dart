import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/firebase/firebase_auth_service.dart';
import '../../../../core/firebase/firebase_storage_service.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/profile_photo_upload_result.dart';
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
  Future<Result<ProfilePhotoUploadResult>> uploadPhoto({
    required String path,
    required String fileName,
  }) async {
    try {
      final profile = await _remoteDataSource.getMe();
      final storage = getIt<FirebaseStorageService>();
      final firebaseUser = getIt<FirebaseAuthService>().currentUser;
      final userKey = firebaseUser?.uid ?? profile.id;

      if (storage.isAvailable) {
        final storagePath = storage.profilePhotoPath(userKey);
        final uploaded = await storage.uploadFile(
          storagePath: storagePath,
          localPath: path,
          contentType: _contentTypeFor(fileName),
        );
        if (uploaded != null) {
          final registered = await _remoteDataSource.registerPhotoFromFirebase(
            imageUrl: uploaded.downloadUrl,
            storagePath: uploaded.storagePath,
            mediaType: uploaded.contentType,
          );
          await _remoteDataSource.getMe();
          return Success(
            ProfilePhotoUploadResult(
              mediaId: registered.mediaId,
              photoUrl: registered.photoUrl ?? registered.imageUrl,
              imageUrl: registered.imageUrl ?? registered.photoUrl,
              storagePath: registered.storagePath,
              photoUpdatedAt: registered.photoUpdatedAt ?? DateTime.now(),
            ),
          );
        }
      }

      final upload = await _remoteDataSource.uploadPhoto(
        path: path,
        fileName: fileName,
      );
      return Success(
        ProfilePhotoUploadResult(
          mediaId: upload.mediaId,
          photoUrl: upload.photoUrl,
          imageUrl: upload.imageUrl ?? upload.photoUrl,
          storagePath: upload.storagePath,
          photoUpdatedAt: upload.photoUpdatedAt,
        ),
      );
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  String? _contentTypeFor(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}
