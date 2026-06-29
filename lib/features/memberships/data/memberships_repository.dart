import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response_unwrapper.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/result.dart';
import '../domain/entities/membership_plan.dart';

class MembershipsRepository {
  const MembershipsRepository(this._client);

  final NetworkClient _client;

  Future<Result<List<MembershipPlan>>> clientPlans({String? countryCode}) =>
      _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/memberships/plans',
          queryParameters: {
            'audience': 'client',
            if (countryCode != null && countryCode.isNotEmpty)
              'countryCode': countryCode,
          },
        );
        final plans = _list(response.data).map(_planFromJson).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        return plans;
      });

  Future<Result<Map<String, dynamic>>> myMembership() => _guard(
        () async => unwrapApiMap(
          (await _client.dio.get<dynamic>('/api/memberships/me')).data,
        ),
      );

  Future<Result<Map<String, dynamic>>> benefits() => _guard(
        () async => unwrapApiMap(
          (await _client.dio.get<dynamic>('/api/memberships/benefits')).data,
        ),
      );

  Future<Result<List<Map<String, dynamic>>>> invoices() => _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/memberships/invoices',
        );
        return _list(response.data);
      });

  Future<Result<Map<String, dynamic>>> subscribeFree({
    required String planId,
  }) => _guard(() async {
        final parsed = int.tryParse(planId);
        final response = await _client.dio.post<dynamic>(
          '/api/memberships/subscribe',
          data: {'planId': parsed ?? planId},
        );
        return unwrapApiMap(response.data);
      });

  Future<Result<void>> cancel() => _guard(() async {
        await _client.dio.post<void>('/api/memberships/cancel');
      });

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}

MembershipPlan _planFromJson(Map<String, dynamic> json) {
  final code = _string(json, const ['code', 'planCode']).toUpperCase();
  final benefitsRaw = json['benefits'];
  final benefits = benefitsRaw is List
      ? benefitsRaw
          .map((item) => item is Map
              ? '${item['name'] ?? item['description'] ?? item['code'] ?? ''}'
              : '$item')
          .where((item) => item.trim().isNotEmpty)
          .map((item) => item.toString())
          .toList()
      : _features(json);

  return MembershipPlan(
    id: _string(json, const ['id', 'planId']),
    code: code.isEmpty ? _string(json, const ['name']).toUpperCase() : code,
    name: _string(json, const ['name', 'displayName']),
    description: _string(json, const ['description', 'summary']),
    priceUsd: _double(json, const ['priceUsd', 'price']),
    baseCurrency: _string(json, const ['baseCurrency']).isEmpty
        ? 'USD'
        : _string(json, const ['baseCurrency']),
    estimatedLocalPrice: _optionalDouble(json, const [
      'estimatedLocalPrice',
    ]),
    estimatedLocalCurrency: _stringOrNull(json, const [
      'estimatedLocalCurrency',
    ]),
    billingCurrency: _stringOrNull(json, const ['billingCurrency']),
    countryCode: _stringOrNull(json, const ['countryCode']),
    paymentProvider: _stringOrNull(json, const ['paymentProvider']),
    benefits: benefits,
    limits: _limits(json),
    supportsCheckout: _bool(json, const ['supportsCheckout'], defaultValue: true),
    requiresCustomQuote: _bool(json, const [
      'requiresCustomQuote',
      'requiresQuote',
    ]),
    audience: _string(json, const ['audience']).isEmpty
        ? 'client'
        : _string(json, const ['audience']),
    cashbackMultiplier: _double(json, const [
      'cashbackMultiplier',
      'cashbackPercent',
      'multiplier',
    ]),
    isCurrent: _bool(json, const ['isCurrent', 'current', 'activeForUser']),
    status: _stringOrNull(json, const ['status', 'membershipStatus']),
    expiresAt: DateTime.tryParse(
      _string(json, const ['expiresAt', 'expirationDate', 'validUntil']),
    ),
    sortOrder: _int(json['sortOrder'] ?? _fallbackSort(code)),
  );
}

List<String> _features(Map<String, dynamic> json) {
  final value = json['features'];
  if (value is List) {
    return value
        .map((item) => item is Map
            ? '${item['name'] ?? item['description'] ?? item['code'] ?? ''}'
            : '$item')
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }
  return const [];
}

Map<String, String> _limits(Map<String, dynamic> json) {
  final value = json['limits'] ?? json['featureLimits'];
  if (value is Map) {
    return value.map((key, value) => MapEntry('$key', '$value'));
  }
  if (value is List) {
    return {
      for (final item in value.whereType<Map>())
        '${item['name'] ?? item['code'] ?? item['feature'] ?? ''}':
            '${item['value'] ?? item['limit'] ?? ''}',
    }..removeWhere((key, value) => key.isEmpty || value.isEmpty);
  }
  return const {};
}

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

String _string(Map<String, dynamic> json, List<String> keys) =>
    _stringOrNull(json, keys) ?? '';

String? _stringOrNull(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().isNotEmpty) return value.toString();
  }
  return null;
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

double? _optionalDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toDouble();
    final parsed = double.tryParse('${value ?? ''}');
    if (parsed != null) return parsed;
  }
  return null;
}

bool _bool(
  Map<String, dynamic> json,
  List<String> keys, {
  bool defaultValue = false,
}) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) return value;
    if (value != null) return value.toString().toLowerCase() == 'true';
  }
  return defaultValue;
}

int _int(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;

int _fallbackSort(String code) => switch (code.toLowerCase()) {
      'free' => 0,
      'plus' || 'silver' => 1,
      'gold' => 2,
      'platinum' || 'black' => 3,
      'family' => 4,
      _ => 99,
    };
