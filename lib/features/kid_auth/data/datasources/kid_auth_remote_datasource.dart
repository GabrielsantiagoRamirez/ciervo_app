import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../../../auth/data/dtos/auth_session_dto.dart';

abstract interface class KidAuthRemoteDataSource {
  Future<AuthSessionDto> kidLogin({
    required String username,
    required String pin,
  });
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
}
