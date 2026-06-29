import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../dtos/receipt_dto.dart';

abstract interface class ReceiptsRemoteDataSource {
  Future<List<ReceiptDto>> receipts();
  Future<ReceiptDto> receipt(String id);
}

class DioReceiptsRemoteDataSource implements ReceiptsRemoteDataSource {
  const DioReceiptsRemoteDataSource(this._client);

  final NetworkClient _client;

  @override
  Future<List<ReceiptDto>> receipts() async {
    final response = await _client.dio.get<dynamic>('/api/receipts');
    return ReceiptDto.listFrom(unwrapApiResponse(response.data));
  }

  @override
  Future<ReceiptDto> receipt(String id) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/receipts/$id',
    );
    return ReceiptDto.fromJson(unwrapApiMap(response.data));
  }
}
