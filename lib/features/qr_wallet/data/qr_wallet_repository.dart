import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response_unwrapper.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/result.dart';
import '../domain/entities/ciervo_qr_item.dart';

class QrWalletRepository {
  const QrWalletRepository(this._client);

  final NetworkClient _client;

  Future<Result<CiervoQrItem>> getQr(String id) => _guard(() async {
    final response = await _client.dio.get<dynamic>('/api/qr/$id');
    final data = unwrapApiMap(response.data);
    return _qrFromJson(data);
  });

  Future<Result<List<CiervoQrItem>>> bookings() => _guard(() async {
    final response = await _client.dio.get<dynamic>('/api/bookings/me');
    return unwrapApiList(response.data)
        .whereType<Map<String, dynamic>>()
        .map(_bookingQrFromJson)
        .toList();
  });

  Future<Result<List<CiervoQrItem>>> tickets() => _guard(() async {
    final response = await _client.dio.get<dynamic>('/api/tickets/me');
    return _list(response.data).map(_ticketFromJson).toList();
  });

  Future<Result<CiervoQrItem>> ticket(String ticketId) => _guard(() async {
    final response = await _client.dio.get<dynamic>('/api/tickets/$ticketId');
    return _ticketFromJson(unwrapApiMap(response.data));
  });

  Future<Result<List<CiervoQrItem>>> giftCards() => _guard(() async {
    final response =
        await _client.dio.get<dynamic>('/api/gift-cards/me/history');
    return _list(response.data).map(_giftCardFromJson).toList();
  });

  Future<Result<List<CiervoQrItem>>> rewardHistory() => _guard(() async {
    final response = await _client.dio.get<dynamic>('/api/rewards/me/history');
    return _list(response.data).map(_benefitFromJson).toList();
  });

  Future<Result<CiervoQrItem?>> validateToken(String token) => _guard(() async {
    final response = await _client.dio.post<dynamic>(
      '/api/qr/validate',
      data: {'token': token},
    );
    final data = unwrapApiMap(response.data);
    final benefit = data['benefit'];
    if (benefit is Map<String, dynamic>) {
      return _benefitFromJson({
        ...benefit,
        'token': token,
        'qrPayload': token,
      });
    }
    if (data.isNotEmpty) return _qrFromJson(data);
    return null;
  });

  Future<Result<CiervoQrItem?>> redeemToken(String token) => _guard(() async {
    final response = await _client.dio.post<dynamic>(
      '/api/qr/redeem',
      data: {'token': token},
    );
    final data = unwrapApiMap(response.data);
    if (data.isEmpty) return null;
    return _benefitFromJson(data);
  });

  Future<Result<List<CiervoQrItem>>> publicBenefits(int businessId) =>
      _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/businesses/$businessId/benefits/public',
        );
        return _list(response.data)
            .map(
              (item) => _catalogBenefitFromJson({
                ...item,
                'qrPayload': item['qrToken'] ?? item['token'],
              }, 'rewards'),
            )
            .toList();
      });

  Future<Result<int?>> rewardPoints() => _guard(() async {
    final response =
        await _client.dio.get<dynamic>('/api/wallet/loyalty/summary');
    final data = unwrapApiMap(response.data);
    return _intOrNull(
      data['pointsAvailable'] ?? data['points'] ?? data['balance'],
    );
  });

  Future<Result<List<CiervoQrItem>>> rewardsCatalog() => _guard(() async {
    final response = await _client.dio.get<dynamic>('/api/rewards/catalog');
    return _list(response.data)
        .map((item) => _catalogBenefitFromJson(item, 'rewards'))
        .toList();
  });

  Future<Result<List<CiervoQrItem>>> couponsCatalog() => _guard(() async {
    final response = await _client.dio.get<dynamic>('/api/coupons');
    return _list(response.data)
        .map((item) => _catalogBenefitFromJson(item, 'coupons'))
        .toList();
  });

  Future<Result<CiervoQrItem?>> redeem(CiervoQrItem item) => _guard(() async {
    if (!item.canRedeemFromCatalog) return null;
    final response = await _client.dio.post<dynamic>(item.redeemPath!);
    final data = unwrapApiMap(response.data);
    return data.isEmpty ? null : _benefitFromJson(data);
  });

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}

CiervoQrItem _qrFromJson(Map<String, dynamic> json) {
  final type = _type(json['type'] ?? json['qrType'] ?? json['sourceType']);
  return CiervoQrItem(
    id: _string(json, const ['id', 'qrId']),
    type: type,
    status: _status(json['status']),
    reference: _string(json, const ['code', 'publicCode', 'reference']),
    title: _stringOrNull(json, const ['title', 'name', 'description']),
    subtitle: _stringOrNull(json, const ['businessName', 'eventName']),
    qrId: _stringOrNull(json, const ['qrId', 'id']),
    qrPayload: _stringOrNull(json, const [
      'payload',
      'qrPayload',
      'qrContent',
      'content',
      'data',
      'signedToken',
      'token',
    ]),
    expiresAt: _date(json, const ['expiresAt', 'expirationDate', 'validUntil']),
    rawStatus: json['status']?.toString(),
  );
}

CiervoQrItem _bookingQrFromJson(Map<String, dynamic> json) => CiervoQrItem(
  id: _string(json, const ['id']),
  type: CiervoQrType.booking,
  status: _status(json['qrStatus'] ?? json['status']),
  reference: _string(json, const ['publicCode', 'code']),
  title: _stringOrNull(json, const ['businessName']) ?? 'Reserva',
  subtitle: _stringOrNull(json, const ['bookingType', 'type']),
  qrId: _stringOrNull(json, const ['qrId', 'universalQrId']),
  qrPayload: _stringOrNull(
    json,
    const ['signedToken', 'qrPayload', 'qrContent', 'token', 'publicCode'],
  ),
  expiresAt: _date(json, const ['qrExpiresAt', 'expiresAt']),
  eventDate: _date(json, const ['bookingDate']),
  rawStatus: json['status']?.toString(),
);

CiervoQrItem _ticketFromJson(Map<String, dynamic> json) => CiervoQrItem(
  id: _string(json, const ['id', 'ticketId', 'eventTicketId']),
  type: CiervoQrType.ticket,
  status: _status(json['status'] ?? json['ticketStatus'] ?? json['qrStatus']),
  reference: _string(json, const [
    'publicCode',
    'ticketCode',
    'code',
    'qrCode',
    'id',
  ]),
  title: _stringOrNull(json, const ['eventName', 'title', 'name']) ?? 'Entrada',
  subtitle: _stringOrNull(json, const ['businessName', 'venueName']),
  qrId: _stringOrNull(json, const ['qrId', 'universalQrId']),
  qrPayload: _stringOrNull(json, const [
    'signedToken',
    'qrPayload',
    'qrContent',
    'payload',
    'token',
  ]),
  expiresAt: _date(json, const ['expiresAt', 'validUntil', 'endsAt']),
  eventDate: _date(json, const ['eventDate', 'startsAt', 'date']),
  rawStatus: json['status']?.toString(),
);

CiervoQrItem _giftCardFromJson(Map<String, dynamic> json) => CiervoQrItem(
  id: _string(json, const ['id', 'giftCardId']),
  type: CiervoQrType.giftCard,
  status: _status(json['status']),
  reference: _string(json, const ['code', 'publicCode', 'giftCardCode']),
  title:
      _stringOrNull(json, const ['title', 'name']) ?? 'Tarjeta regalo',
  subtitle: _stringOrNull(json, const ['businessName', 'description']),
  qrId: _stringOrNull(json, const ['qrId', 'universalQrId']),
  qrPayload: _stringOrNull(
    json,
    const ['signedToken', 'qrPayload', 'qrContent', 'token'],
  ),
  expiresAt: _date(json, const ['expiresAt', 'expirationDate', 'validUntil']),
  pin: _stringOrNull(json, const ['pin', 'pinCode']),
  rawStatus: json['status']?.toString(),
);

CiervoQrItem _benefitFromJson(Map<String, dynamic> json) => CiervoQrItem(
  id: _string(json, const ['id', 'redemptionId', 'rewardId', 'couponId']),
  type: CiervoQrType.benefit,
  status: _status(json['status']),
  reference: _string(json, const ['code', 'publicCode', 'redemptionCode']),
  title:
      _stringOrNull(json, const ['title', 'name', 'rewardName', 'couponName']) ??
          'Beneficio',
  subtitle: _stringOrNull(json, const ['description', 'businessName']),
  qrId: _stringOrNull(json, const ['qrId', 'universalQrId']),
  qrPayload: _stringOrNull(
    json,
    const ['signedToken', 'qrPayload', 'qrContent', 'token'],
  ),
  expiresAt: _date(json, const ['expiresAt', 'expirationDate', 'validUntil']),
  points: _intOrNull(json['points'] ?? json['pointsCost']),
  redeemPath: _stringOrNull(json, const ['redeemPath']),
  rawStatus: json['status']?.toString(),
);

CiervoQrItem _catalogBenefitFromJson(Map<String, dynamic> json, String source) =>
    _benefitFromJson({
      ...json,
      'status': json['status'] ?? 'Activo',
      'redemptionCode': json['code'] ?? json['publicCode'] ?? json['id'],
      'redeemPath': '/api/$source/${json['id']}/redeem',
    });

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

CiervoQrType _type(dynamic value) {
  final text = '${value ?? ''}'.toLowerCase();
  if (text.contains('ticket')) return CiervoQrType.ticket;
  if (text.contains('gift')) return CiervoQrType.giftCard;
  if (text.contains('reward') || text.contains('coupon')) {
    return CiervoQrType.benefit;
  }
  return CiervoQrType.booking;
}

CiervoQrStatus _status(dynamic value) {
  final text = '${value ?? ''}'.toLowerCase();
  if (text.contains('used') || text.contains('redeemed')) {
    return CiervoQrStatus.used;
  }
  if (text.contains('expired')) return CiervoQrStatus.expired;
  if (text.contains('cancel')) return CiervoQrStatus.cancelled;
  if (text.contains('active') ||
      text.contains('pending') ||
      text.contains('confirmed')) {
    return CiervoQrStatus.active;
  }
  return CiervoQrStatus.unknown;
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

DateTime? _date(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    final parsed = DateTime.tryParse('${value ?? ''}');
    if (parsed != null) return parsed;
  }
  return null;
}

int? _intOrNull(dynamic value) => value is int ? value : int.tryParse('$value');
