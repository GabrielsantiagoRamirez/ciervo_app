import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response_unwrapper.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/result.dart';
import '../../loyalty/data/loyalty_repository.dart';
import '../domain/entities/cashback_rule.dart';

class PointsBalance {
  const PointsBalance({
    required this.earned,
    required this.spent,
    required this.reversed,
    required this.balance,
  });

  final int earned;
  final int spent;
  final int reversed;
  final int balance;

  factory PointsBalance.fromJson(Map<String, dynamic> json) => PointsBalance(
    earned: _int(json['earned'] ?? json['pointsEarned'] ?? json['totalEarned']),
    spent: _int(json['spent'] ?? json['pointsSpent'] ?? json['totalSpent']),
    reversed: _int(
      json['reversed'] ?? json['pointsReversed'] ?? json['totalReversed'],
    ),
    balance: _int(
      json['balance'] ??
          json['pointsBalance'] ??
          json['points'] ??
          json['available'],
    ),
  );
}

class CashbackRepository {
  const CashbackRepository(this._client);

  final NetworkClient _client;

  Future<Result<List<CashbackRule>>> rules() => _guard(() async {
    final response = await _client.dio.get<dynamic>('/api/cashback/rules');
    return _list(response.data).map(_ruleFromJson).toList();
  });

  Future<Result<int?>> rewardBalance() => _guard(() async {
    final response = await _client.dio.get<dynamic>(
      '/api/wallet/loyalty/summary',
    );
    final value = unwrapApiMap(response.data);
    return _intOrNull(
      value['cashbackAvailable'] ??
          value['cashback'] ??
          value['pointsAvailable'] ??
          value['points'] ??
          value['balance'],
    );
  });

  Future<Result<List<Map<String, dynamic>>>> rewardTransactions() =>
      _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/rewards/me/transactions',
        );
        return _list(response.data);
      });

  Future<Result<PointsBalance>> pointsBalance() async {
    final primary = await _guard(() async {
      final response = await _client.dio.get<dynamic>('/api/wallet/points');
      return PointsBalance.fromJson(unwrapApiMap(response.data));
    });
    return primary.when(
      success: (value) => Success(value),
      failure: (_) => _guard(() async {
        final response = await _client.dio.get<dynamic>('/api/wallet/cashback');
        return PointsBalance.fromJson(unwrapApiMap(response.data));
      }),
    );
  }

  Future<Result<LoyaltySummary>> loyaltySummary() => _guard(() async {
    final response = await _client.dio.get<dynamic>(
      '/api/wallet/loyalty/summary',
    );
    return LoyaltySummary.fromJson(unwrapApiMap(response.data));
  });

  Future<Result<List<Map<String, dynamic>>>> pointsHistory() async {
    const paths = [
      '/api/wallet/points/history',
      '/api/rewards/history',
      '/api/wallet/history',
    ];
    for (final path in paths) {
      final result = await _guard(() async {
        final response = await _client.dio.get<dynamic>(path);
        return _list(response.data);
      });
      final items = result.when(
        success: (value) => value,
        failure: (_) => const <Map<String, dynamic>>[],
      );
      if (items.isNotEmpty) return Success(items);
    }
    return const Success(<Map<String, dynamic>>[]);
  }

  Future<Result<Map<String, dynamic>>> redeemPoints({
    required int points,
    String? note,
  }) => _guard(() async {
    final response = await _client.dio.post<dynamic>(
      '/api/wallet/points/redeem',
      data: {
        'points': points,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    return unwrapApiMap(response.data);
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

int _int(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

int? _intOrNull(dynamic value) => value is int ? value : int.tryParse('$value');
