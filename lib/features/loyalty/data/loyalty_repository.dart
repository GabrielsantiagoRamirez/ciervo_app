import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response_unwrapper.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/result.dart';

class LoyaltySummary {
  const LoyaltySummary({
    required this.pointsAvailable,
    required this.cashbackAvailable,
    required this.level,
    this.nextLevelAt,
    this.progressPercent = 0,
  });

  final int pointsAvailable;
  final int cashbackAvailable;
  final String level;
  final int? nextLevelAt;
  final int progressPercent;

  factory LoyaltySummary.fromJson(Map<String, dynamic> json) {
    final points = _int(json['pointsAvailable'] ?? json['points'] ?? json['balance']);
    final cashback = _int(
      json['cashbackAvailable'] ?? json['cashback'] ?? points,
    );
    return LoyaltySummary(
      pointsAvailable: points,
      cashbackAvailable: cashback,
      level: '${json['level'] ?? 'Bronce'}',
      nextLevelAt: _optionalInt(json['nextLevelAt']),
      progressPercent: _int(json['progressPercent']),
    );
  }

  static int _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static int? _optionalInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }
}

class LoyaltyPurchaseResult {
  const LoyaltyPurchaseResult({
    required this.pointsGenerated,
    required this.cashbackGenerated,
    this.campaign,
    this.level,
    this.pointsBalance,
  });

  final int pointsGenerated;
  final int cashbackGenerated;
  final String? campaign;
  final String? level;
  final int? pointsBalance;

  factory LoyaltyPurchaseResult.fromJson(Map<String, dynamic> json) =>
      LoyaltyPurchaseResult(
        pointsGenerated: LoyaltySummary._int(
          json['pointsGenerated'] ?? json['pointsEarned'],
        ),
        cashbackGenerated: LoyaltySummary._int(
          json['cashbackGenerated'] ?? json['cashbackEarned'],
        ),
        campaign: json['campaign']?.toString(),
        level: json['level']?.toString(),
        pointsBalance: LoyaltySummary._optionalInt(json['pointsBalance']),
      );

  bool get hasRewards => pointsGenerated > 0 || cashbackGenerated > 0;
}

class LoyaltyRepository {
  const LoyaltyRepository(this._client);

  final NetworkClient _client;

  Future<Result<LoyaltySummary>> summary() => _guard(() async {
        final response =
            await _client.dio.get<dynamic>('/api/wallet/loyalty/summary');
        return LoyaltySummary.fromJson(unwrapApiMap(response.data));
      });

  Future<Result<List<Map<String, dynamic>>>> history({
    int page = 1,
    int pageSize = 20,
  }) =>
      _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/wallet/history',
          queryParameters: {'page': page, 'pageSize': pageSize},
        );
        final value = unwrapApiResponse(response.data);
        if (value is List) {
          return value
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        if (value is Map && value['items'] is List) {
          return (value['items'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        return const <Map<String, dynamic>>[];
      });

  Future<Result<LoyaltyPurchaseResult>> processPurchase({
    required String idempotencyKey,
    required double amount,
    String currency = 'COP',
    int? businessId,
    int? paymentIntentId,
    String eventType = 'wallet_payment',
  }) =>
      _guard(() async {
        final response = await _client.dio.post<dynamic>(
          '/api/loyalty/process-purchase',
          data: {
            'idempotencyKey': idempotencyKey,
            'amount': amount,
            'currency': currency,
            'eventType': eventType,
            if (businessId != null) 'businessId': businessId,
            if (paymentIntentId != null) 'paymentIntentId': paymentIntentId,
          },
        );
        return LoyaltyPurchaseResult.fromJson(unwrapApiMap(response.data));
      });

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Success(await run());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
