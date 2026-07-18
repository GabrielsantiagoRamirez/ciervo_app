import '../../../../core/device/device_installation_service.dart';
import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../../../../core/version/app_version_service.dart';
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
  const DioKidAuthRemoteDataSource(
    this._client,
    this._deviceInstallation,
    this._appVersion,
  );

  final NetworkClient _client;
  final DeviceInstallationService _deviceInstallation;
  final AppVersionService _appVersion;

  @override
  Future<AuthSessionDto> kidLogin({
    required String username,
    required String pin,
  }) async {
    final deviceId = await _deviceInstallation.deviceId();
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/v1/kids/auth/login',
      data: {
        'username': username.trim(),
        'pin': pin.trim(),
        'deviceId': deviceId,
        'platform': _deviceInstallation.platform,
        'appVersion': await _appVersion.version(),
      },
    );
    return AuthSessionDto.fromJson(
      unwrapApiMap(response.data),
      refreshPath: '/api/v1/kids/auth/refresh',
      deviceId: deviceId,
    );
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
