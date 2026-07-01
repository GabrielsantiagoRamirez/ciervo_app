import '../../../../core/result/result.dart';
import '../../data/dtos/account_lookup_dto.dart';
import '../../data/dtos/firebase_auth_dtos.dart';
import '../entities/auth_session.dart';

abstract interface class AuthRepository {
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  });

  Future<Result<AuthSession>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String identityDocument,
    required String documentType,
    required String countryCode,
  });

  Future<Result<AuthSession>> firebaseLogin({
    required String firebaseIdToken,
    String? phone,
    String? email,
    String? countryCode,
  });

  Future<Result<AuthSession>> firebaseRegister({
    required String firebaseIdToken,
    required Map<String, dynamic> profile,
  });

  Future<Result<FirebaseCheckUserResult>> firebaseCheckUser({
    required String firebaseIdToken,
    String? phone,
    String? email,
    String? countryCode,
  });

  Future<Result<VerificationSyncResult>> firebaseSyncVerification({
    required String firebaseIdToken,
    String? phone,
    String? email,
    String? countryCode,
  });

  Future<Result<AccountLookupResult>> lookupAccount({
    String? email,
    String? phone,
    String? countryCode,
  });

  Future<Result<void>> sendEmailVerificationCode(String email);

  Future<Result<void>> verifyEmailCode({
    required String email,
    required String code,
  });

  Future<Result<void>> logout();
}
