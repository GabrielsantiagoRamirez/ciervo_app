import '../../../core/network/api_response_unwrapper.dart';
import '../../../core/network/network_client.dart';
import '../domain/business_nfc_models.dart';

abstract interface class BusinessNfcRemoteDataSource {
  Future<BusinessNfcValidation> validate(BusinessNfcValidateCommand command);
  Future<BusinessNfcCharge> charge(BusinessNfcChargeCommand command);
}

class DioBusinessNfcRemoteDataSource implements BusinessNfcRemoteDataSource {
  const DioBusinessNfcRemoteDataSource(this._client);
  final NetworkClient _client;

  @override
  Future<BusinessNfcValidation> validate(
    BusinessNfcValidateCommand command,
  ) async {
    final response = await _client.dio.post<dynamic>(
      '/api/wallet/nfc/validate',
      data: command.toJson(),
    );
    return BusinessNfcValidation.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<BusinessNfcCharge> charge(BusinessNfcChargeCommand command) async {
    final response = await _client.dio.post<dynamic>(
      '/api/wallet/nfc/charge',
      data: command.toJson(),
    );
    return BusinessNfcCharge.fromJson(unwrapApiMap(response.data));
  }
}
