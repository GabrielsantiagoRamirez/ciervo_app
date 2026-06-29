import '../../../../core/result/result.dart';
import '../entities/user_profile.dart';

abstract interface class ProfileRepository {
  Future<Result<UserProfile>> getMe();

  Future<Result<UserProfile>> updateMe({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
  });

  Future<Result<String>> uploadPhoto({
    required String path,
    required String fileName,
  });
}
