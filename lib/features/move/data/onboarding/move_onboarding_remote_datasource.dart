import 'package:dio/dio.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_models.dart';
import '../../../../core/network/network_client.dart';
import '../../domain/onboarding/move_onboarding_requests.dart';
import '../../domain/onboarding/move_onboarding_status.dart';

abstract interface class MoveOnboardingRemoteDataSource {
  Future<MoveDriverOnboardingStatus> getStatus();

  Future<MoveDriverOnboardingStatus> saveIdentity(
    MoveIdentityOnboardingRequest request, {
    required String idempotencyKey,
  });

  Future<MoveDriverOnboardingStatus> saveLicense(
    MoveLicenseOnboardingRequest request, {
    required String idempotencyKey,
  });

  Future<MoveDriverOnboardingStatus> saveVehicle(
    MoveVehicleOnboardingRequest request, {
    required String idempotencyKey,
  });

  Future<MoveDriverOnboardingStatus> saveOperations(
    MoveOperationsOnboardingRequest request, {
    required String idempotencyKey,
  });

  Future<MoveDriverOnboardingStatus> submit({required String idempotencyKey});
}

class DioMoveOnboardingRemoteDataSource
    implements MoveOnboardingRemoteDataSource {
  const DioMoveOnboardingRemoteDataSource(this._client);

  final NetworkClient _client;

  static const _base = '/api/v1/move/driver/onboarding';

  @override
  Future<MoveDriverOnboardingStatus> getStatus() async {
    final response = await _client.dio.get<dynamic>('$_base/status');
    return _decode(response.data);
  }

  @override
  Future<MoveDriverOnboardingStatus> saveIdentity(
    MoveIdentityOnboardingRequest request, {
    required String idempotencyKey,
  }) => _put('identity', request.toJson(), idempotencyKey);

  @override
  Future<MoveDriverOnboardingStatus> saveLicense(
    MoveLicenseOnboardingRequest request, {
    required String idempotencyKey,
  }) => _put('license', request.toJson(), idempotencyKey);

  @override
  Future<MoveDriverOnboardingStatus> saveVehicle(
    MoveVehicleOnboardingRequest request, {
    required String idempotencyKey,
  }) => _put('vehicle', request.toJson(), idempotencyKey);

  @override
  Future<MoveDriverOnboardingStatus> saveOperations(
    MoveOperationsOnboardingRequest request, {
    required String idempotencyKey,
  }) => _put('operations', request.toJson(), idempotencyKey);

  @override
  Future<MoveDriverOnboardingStatus> submit({
    required String idempotencyKey,
  }) async {
    final response = await _client.dio.post<dynamic>(
      '$_base/submit',
      options: _idempotencyOptions(idempotencyKey),
    );
    return _decode(response.data);
  }

  Future<MoveDriverOnboardingStatus> _put(
    String segment,
    Map<String, dynamic> body,
    String idempotencyKey,
  ) async {
    final response = await _client.dio.put<dynamic>(
      '$_base/$segment',
      data: body,
      options: _idempotencyOptions(idempotencyKey),
    );
    return _decode(response.data);
  }

  Options _idempotencyOptions(String key) {
    final normalized = key.trim();
    if (normalized.isEmpty || normalized.length > 120) {
      throw const AppException(
        message: 'Idempotency-Key debe tener entre 1 y 120 caracteres.',
        code: 'invalid_idempotency_key',
      );
    }
    return Options(headers: {'Idempotency-Key': normalized});
  }

  MoveDriverOnboardingStatus _decode(Object? raw) {
    if (raw is! Map) {
      throw const AppException(
        message: 'Respuesta MOVE inválida.',
        code: 'invalid_response',
      );
    }
    final envelope = ApiEnvelope<MoveDriverOnboardingStatus?>.fromJson(
      Map<String, dynamic>.from(raw),
      (value) {
        if (value == null) return null;
        if (value is! Map) {
          throw const AppException(
            message: 'Estado MOVE ausente.',
            code: 'invalid_response',
          );
        }
        return MoveDriverOnboardingStatus.fromJson(
          Map<String, dynamic>.from(value),
        );
      },
    );
    if (!envelope.status) {
      throw AppException(
        message: envelope.message ?? 'No pudimos completar la solicitud.',
        code: envelope.errorCode,
      );
    }
    final value = envelope.value;
    if (value == null) {
      throw const AppException(
        message: 'Estado MOVE ausente.',
        code: 'invalid_response',
      );
    }
    return value;
  }
}
