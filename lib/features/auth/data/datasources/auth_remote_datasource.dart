import 'package:dio/dio.dart';

import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../dtos/auth_session_dto.dart';
import '../dtos/login_request_dto.dart';
import '../dtos/register_request_dto.dart';

abstract interface class AuthRemoteDataSource {
  Future<AuthSessionDto> login(LoginRequestDto request);

  Future<void> register(RegisterRequestDto request);

  Future<void> logout(String refreshToken);

  Future<bool> firebaseCheckUser(String firebaseIdToken);

  Future<AuthSessionDto> firebaseLogin({
    required String firebaseIdToken,
    String? phone,
  });

  Future<AuthSessionDto> firebaseRegister({
    required String firebaseIdToken,
    required Map<String, dynamic> profile,
  });
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
  Future<bool> firebaseCheckUser(String firebaseIdToken) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/auth/firebase/check-user',
      data: {'firebaseIdToken': firebaseIdToken},
      options: Options(extra: const {'skipAuth': true}),
    );
    final value = unwrapApiMap(response.data);
    return value['exists'] == true || value['userExists'] == true;
  }

  @override
  Future<AuthSessionDto> firebaseLogin({
    required String firebaseIdToken,
    String? phone,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/auth/firebase/login',
      data: {
        'firebaseIdToken': firebaseIdToken,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
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
}
