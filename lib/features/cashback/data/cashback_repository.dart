import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response_unwrapper.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/result.dart';
import '../domain/entities/cashback_rule.dart';

class CashbackRepository {
  const CashbackRepository(this._client);

  final NetworkClient _client;

  Future<Result<List<CashbackRule>>> rules() => _guard(() async {
        final response = await _client.dio.get<dynamic>('/api/cashback/rules');
        return _list(response.data).map(_ruleFromJson).toList();
      });

  Future<Result<int?>> rewardBalance() => _guard(() async {
        final response = await _client.dio.get<dynamic>('/api/rewards/me/balance');
        final value = unwrapApiResponse(response.data);
        if (value is num) return value.toInt();
        if (value is Map<String, dynamic>) {
          return _intOrNull(value['points'] ?? value['balance'] ?? value['total']);
        }
        return _intOrNull(value);
      });

  Future<Result<List<Map<String, dynamic>>>> rewardTransactions() =>
      _guard(() async {
        final response =
            await _client.dio.get<dynamic>('/api/rewards/me/transactions');
        return _list(response.data);
      });

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}

CashbackRule _ruleFromJson(Map<String, dynamic> json) => CashbackRule(
      id: _string(json, const ['id', 'ruleId']),
      name: _string(json, const ['name', 'title']),
      description: _string(json, const ['description', 'summary']),
      percentage: _double(json, const ['percentage', 'cashbackPercent', 'rate']),
      pointsMultiplier: _double(json, const ['pointsMultiplier', 'multiplier']),
      membershipTier: _string(json, const ['membershipTier', 'planCode', 'tier']),
      isActive: json['isActive'] != false && json['active'] != false,
    );

List<Map<String, dynamic>> _list(dynamic response) {
  final source = unwrapApiResponse(response);
  final items = source is List
      ? source
      : source is Map<String, dynamic> && source['items'] is List
          ? source['items'] as List
          : const [];
  return items
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

String _string(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().isNotEmpty) return value.toString();
  }
  return '';
}

double _double(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toDouble();
    final parsed = double.tryParse('${value ?? ''}');
    if (parsed != null) return parsed;
  }
  return 0;
}

int? _intOrNull(dynamic value) => value is int ? value : int.tryParse('$value');
