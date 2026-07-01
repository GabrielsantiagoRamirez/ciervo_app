import 'package:dio/dio.dart';

import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../dtos/account_lookup_dto.dart';
import '../dtos/auth_session_dto.dart';
import '../dtos/firebase_auth_dtos.dart';
import '../dtos/login_request_dto.dart';
import '../dtos/register_request_dto.dart';

abstract interface class AuthRemoteDataSource {
  Future<AuthSessionDto> login(LoginRequestDto request);

  Future<void> register(RegisterRequestDto request);

  Future<void> logout(String refreshToken);

  Future<FirebaseCheckUserResult> firebaseCheckUser({
    required String firebaseIdToken,
    String? phone,
    String? email,
    String? countryCode,
  });

  Future<AuthSessionDto> firebaseLogin({
    required String firebaseIdToken,
    String? phone,
    String? email,
    String? countryCode,
  });

  Future<AuthSessionDto> firebaseRegister({
    required String firebaseIdToken,
    required Map<String, dynamic> profile,
  });

  Future<VerificationSyncResult> firebaseSyncVerification({
    required String firebaseIdToken,
    String? phone,
    String? email,
    String? countryCode,
  });

  Future<AccountLookupResult> lookupAccount({
    String? email,
    String? phone,
    String? countryCode,
  });

  Future<void> sendEmailVerificationCode(String email);

  Future<void> verifyEmailCode({
    required String email,
    required String code,
  });
}

Map<String, dynamic> _firebaseContactPayload({
  String? phone,
  String? email,
  String? countryCode,
}) {
  final data = <String, dynamic>{};
  final phoneText = phone?.trim();
  final emailText = email?.trim();
  final country = countryCode?.trim().toUpperCase();
  if (phoneText != null && phoneText.isNotEmpty) {
    data['phone'] = phoneText;
  }
  if (emailText != null && emailText.isNotEmpty) {
    data['email'] = emailText;
  }
  if (country != null && country.isNotEmpty) {
    data['countryCode'] = country;
  }
  return data;
}

class DioAuthRemoteDataSource implements AuthRemoteDataSource {
  const DioAuthRemoteDataSource(this._client);

  final NetworkClient _client;

  @override
  Future<AuthSessionDto> login(LoginRequestDto request) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/auth/user/login',
      data: request.toJson(),
      options: Options(extra: const {'skipAuth': true}),
    );
    return AuthSessionDto.fromJson(
      unwrapApiMap(response.data),
    );
  }

  @override
  Future<void> logout(String refreshToken) async {
    await _client.dio.post<void>(
      '/api/auth/logout',
      data: {'refreshToken': refreshToken},
      options: Options(extra: const {'skipAuth': true}),
    );
  }

  @override
  Future<void> register(RegisterRequestDto request) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/auth/user/register',
      data: request.toJson(),
      options: Options(extra: const {'skipAuth': true}),
    );
    unwrapApiResponse(response.data);
  }

  @override
  Future<FirebaseCheckUserResult> firebaseCheckUser({
    required String firebaseIdToken,
    String? phone,
    String? email,
    String? countryCode,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/auth/firebase/check-user',
      data: {
        'firebaseIdToken': firebaseIdToken,
        ..._firebaseContactPayload(
          phone: phone,
          email: email,
          countryCode: countryCode,
        ),
      },
      options: Options(extra: const {'skipAuth': true}),
    );
    return FirebaseCheckUserResult.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<AuthSessionDto> firebaseLogin({
    required String firebaseIdToken,
    String? phone,
    String? email,
    String? countryCode,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/auth/firebase/login',
      data: {
        'firebaseIdToken': firebaseIdToken,
        ..._firebaseContactPayload(
          phone: phone,
          email: email,
          countryCode: countryCode,
        ),
      },
      options: Options(extra: const {'skipAuth': true}),
    );
    return AuthSessionDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<AuthSessionDto> firebaseRegister({
    required String firebaseIdToken,
    required Map<String, dynamic> profile,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/auth/firebase/register',
      data: {'firebaseIdToken': firebaseIdToken, ...profile},
      options: Options(extra: const {'skipAuth': true}),
    );
    return AuthSessionDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<VerificationSyncResult> firebaseSyncVerification({
    required String firebaseIdToken,
    String? phone,
    String? email,
    String? countryCode,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/auth/firebase/sync-verification',
      data: {
        'firebaseIdToken': firebaseIdToken,
        ..._firebaseContactPayload(
          phone: phone,
          email: email,
          countryCode: countryCode,
        ),
      },
      options: Options(extra: const {'skipAuth': true}),
    );
    return VerificationSyncResult.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<AccountLookupResult> lookupAccount({
    String? email,
    String? phone,
    String? countryCode,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/auth/account-lookup',
      data: _firebaseContactPayload(
        email: email,
        phone: phone,
        countryCode: countryCode,
      ),
      options: Options(extra: const {'skipAuth': true}),
    );
    return AccountLookupResult.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<void> sendEmailVerificationCode(String email) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/auth/send-verification-code',
      data: {'email': email.trim()},
      options: Options(extra: const {'skipAuth': true}),
    );
    unwrapApiResponse(response.data);
  }

  @override
  Future<void> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/auth/verify-code',
      data: {
        'email': email.trim(),
        'code': code.trim(),
      },
      options: Options(extra: const {'skipAuth': true}),
    );
    unwrapApiResponse(response.data);
  }
}
