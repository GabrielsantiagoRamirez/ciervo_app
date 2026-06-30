import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../dtos/ciervo_pin_dto.dart';

abstract interface class PinsRemoteDataSource {
  Future<CiervoPinDto> createPin({
    required String walletCardId,
    required String businessId,
    required double amount,
    bool kidsMode = false,
    bool requireParentApproval = false,
    String? childProfileId,
    String? childWalletCardId,
  });

  Future<List<CiervoPinDto>> myPins({bool activeOnly = true});

  Future<CiervoPinDto> pin(String id);

  Future<CiervoPinDto> cancelPin(String id);
}

class DioPinsRemoteDataSource implements PinsRemoteDataSource {
  const DioPinsRemoteDataSource(this._client);

  final NetworkClient _client;

  @override
  Future<CiervoPinDto> createPin({
    required String walletCardId,
    required String businessId,
    required double amount,
    bool kidsMode = false,
    bool requireParentApproval = false,
    String? childProfileId,
    String? childWalletCardId,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/pins',
      data: {
        if (!kidsMode)
          'walletCardId': int.tryParse(walletCardId) ?? walletCardId,
        'businessId': int.tryParse(businessId) ?? businessId,
        'amount': amount,
        'currency': 'COP',
        'expirationMinutes': 30,
        'allowedUses': 1,
        'idempotencyKey': _idempotencyKey('pin', walletCardId),
        'kidsMode': kidsMode,
        'requireParentApproval': requireParentApproval,
        if (kidsMode && childProfileId != null)
          'childProfileId':
              int.tryParse(childProfileId) ?? childProfileId,
        if (kidsMode && childWalletCardId != null)
          'childWalletCardId':
              int.tryParse(childWalletCardId) ?? childWalletCardId,
      },
    );
    return CiervoPinDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<List<CiervoPinDto>> myPins({bool activeOnly = true}) async {
    final response = await _client.dio.get<dynamic>(
      '/api/pins/me',
      queryParameters: {'activeOnly': activeOnly},
    );
    return CiervoPinDto.listFrom(unwrapApiResponse(response.data));
  }

  @override
  Future<CiervoPinDto> pin(String id) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/pins/$id',
    );
    return CiervoPinDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<CiervoPinDto> cancelPin(String id) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/pins/$id/cancel',
    );
    return CiervoPinDto.fromJson(unwrapApiMap(response.data));
  }

  String _idempotencyKey(String prefix, String seed) {
    return '$prefix-$seed-${DateTime.now().microsecondsSinceEpoch}';
  }
}
