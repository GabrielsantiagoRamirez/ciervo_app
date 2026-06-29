import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response_unwrapper.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/result.dart';
import '../domain/staff_order.dart';

class StaffOrdersRepository {
  const StaffOrdersRepository(this._client);

  final NetworkClient _client;

  Future<Result<List<StaffOrder>>> orders({
    required int businessId,
    String? status,
    String? search,
    DateTime? date,
  }) => _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/businesses/$businessId/delivery-orders',
          queryParameters: {
            if (status != null && status.isNotEmpty) 'status': status,
            if (search != null && search.trim().isNotEmpty)
              'search': search.trim(),
            if (date != null) 'date': date.toIso8601String().substring(0, 10),
            'page': 1,
            'pageSize': 50,
          },
        );
        return unwrapApiList(response.data)
            .whereType<Map<String, dynamic>>()
            .map(StaffOrder.fromJson)
            .toList();
      });

  Future<Result<StaffOrder>> order({
    required int businessId,
    required String orderId,
  }) => _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/businesses/$businessId/delivery-orders/$orderId',
        );
        return StaffOrder.fromJson(unwrapApiMap(response.data));
      });

  Future<Result<StaffOrder>> updateStatus({
    required int businessId,
    required String orderId,
    required String status,
    String? notes,
  }) => _guard(() async {
        final response = await _client.dio.put<dynamic>(
          '/api/businesses/$businessId/delivery-orders/$orderId/status',
          data: {
            'status': status,
            if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
          },
        );
        return StaffOrder.fromJson(unwrapApiMap(response.data));
      });

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
