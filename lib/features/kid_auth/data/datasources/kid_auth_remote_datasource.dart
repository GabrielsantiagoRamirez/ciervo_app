import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../../../auth/data/dtos/auth_session_dto.dart';
import '../../domain/entities/kid_registration.dart';

abstract interface class KidAuthRemoteDataSource {
  Future<AuthSessionDto> kidLogin({
    required String username,
    required String pin,
  });

  Future<GuardianVerifyResult> verifyGuardian(KidVerifyGuardianRequest request);

  Future<AuthSessionDto> registerKid(KidSelfRegisterRequest request);
}

class DioKidAuthRemoteDataSource implements KidAuthRemoteDataSource {
  const DioKidAuthRemoteDataSource(this._client);

  final NetworkClient _client;

  @override
  Future<AuthSessionDto> kidLogin({
    required String username,
    required String pin,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/auth/kid-login',
      data: {'username': username.trim(), 'pin': pin.trim()},
    );
    return AuthSessionDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<GuardianVerifyResult> verifyGuardian(
    KidVerifyGuardianRequest request,
  ) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/auth/kid/verify-guardian',
      data: request.toJson(),
    );
    return GuardianVerifyResult.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<AuthSessionDto> registerKid(KidSelfRegisterRequest request) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/auth/kid/register',
      data: request.toJson(),
    );
    return AuthSessionDto.fromJson(unwrapApiMap(response.data));
  }
}
