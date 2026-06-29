import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../dtos/financial_history_item_dto.dart';

abstract interface class FinancialHistoryRemoteDataSource {
  Future<List<FinancialHistoryItemDto>> history();
}

class DioFinancialHistoryRemoteDataSource
    implements FinancialHistoryRemoteDataSource {
  const DioFinancialHistoryRemoteDataSource(this._client);
  final NetworkClient _client;

  @override
  Future<List<FinancialHistoryItemDto>> history() async {
    final response = await _client.dio.get<dynamic>('/api/financial-history');
    return FinancialHistoryItemDto.listFrom(unwrapApiResponse(response.data));
  }
}
