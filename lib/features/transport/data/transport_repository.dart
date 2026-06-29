import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response_unwrapper.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/result.dart';

class TransportCard {
  const TransportCard({
    required this.id,
    required this.status,
    this.cardNumber,
    this.balance,
    this.currency,
  });

  final String id;
  final String status;
  final String? cardNumber;
  final num? balance;
  final String? currency;
}

class TransportRepository {
  const TransportRepository(this._client);

  final NetworkClient _client;

  Future<Result<List<TransportCard>>> cards() => _guard(() async {
    final response = await _client.dio.get<dynamic>('/api/transport/cards/me');
    return unwrapApiList(response.data)
        .whereType<Map<String, dynamic>>()
        .map(_cardFromJson)
        .toList();
  });

  Future<Result<void>> createCard() => _guard(() async {
    await _client.dio.post<dynamic>('/api/transport/cards');
  });

  Future<Result<Map<String, dynamic>>> validateMock(String cardId) =>
      _guard(() async {
        final response = await _client.dio.post<dynamic>(
          '/api/transport/validate',
          data: {'cardId': cardId},
        );
        return unwrapApiMap(response.data);
      });

  Future<Result<List<Map<String, dynamic>>>> discounts() => _guard(() async {
    final response = await _client.dio.get<dynamic>('/api/transport/discounts');
    return unwrapApiList(response.data)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  });

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}

TransportCard _cardFromJson(Map<String, dynamic> json) => TransportCard(
  id: '${json['id'] ?? json['cardId'] ?? ''}',
  status: '${json['status'] ?? 'Active'}',
  cardNumber: _s(json['cardNumber'] ?? json['number']),
  balance: json['balance'] is num
      ? json['balance'] as num
      : num.tryParse('${json['balance'] ?? ''}'),
  currency: _s(json['currency']),
);

String? _s(dynamic value) =>
    value == null || value.toString().isEmpty ? null : value.toString();
