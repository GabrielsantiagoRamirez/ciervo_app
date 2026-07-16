import '../../../../core/errors/error_mapper.dart';
import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../../../../core/result/result.dart';
import '../../../../core/utils/idempotency_key.dart';
import '../domain/entities/pin_p2p_result.dart';

/// Cobro persona a persona con PIN semanal (`/api/pins/p2p/*`).
class PinP2PService {
  const PinP2PService(this._client);

  final NetworkClient _client;

  Future<Result<PinP2PVerifyResult>> verify({
    required String paymentPinId,
    required String pin,
    double? amount,
  }) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/api/pins/p2p/verify',
        data: {
          'paymentPinId': int.tryParse(paymentPinId) ?? paymentPinId,
          'pin': pin.trim(),
          if (amount != null) 'amount': amount,
        },
      );
      return Success(
        PinP2PVerifyResult.fromJson(unwrapApiMap(response.data)),
      );
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  Future<Result<PinP2PPayResult>> pay({
    required String paymentPinId,
    required String pin,
    required double amount,
    String? description,
    String? idempotencyKey,
  }) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/api/pins/p2p/pay',
        data: {
          'paymentPinId': int.tryParse(paymentPinId) ?? paymentPinId,
          'pin': pin.trim(),
          'amount': amount,
          'idempotencyKey': idempotencyKey ?? IdempotencyKey.generate(),
          if (description != null && description.trim().isNotEmpty)
            'description': description.trim(),
        },
      );
      return Success(PinP2PPayResult.fromJson(unwrapApiMap(response.data)));
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
