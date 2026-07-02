import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response_unwrapper.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/result.dart';
import '../domain/entities/qr_scan_models.dart';

class QrScanRepository {
  const QrScanRepository(this._client);

  final NetworkClient _client;

  Future<Result<QrResolveResult>> resolve(String raw) => _guard(() async {
    final response = await _client.dio.post<dynamic>(
      '/api/qr/resolve',
      data: {'raw': raw.trim()},
    );
    return _resolveFromJson(unwrapApiMap(response.data));
  });

  Future<Result<QrPaymentDetails>> paymentDetails(String token) =>
      _guard(() async {
        final normalized = token.trim();
        final response = await _client.dio.get<dynamic>(
          '/api/payments/qr/${Uri.encodeComponent(normalized)}',
        );
        return _paymentDetailsFromJson(normalized, unwrapApiMap(response.data));
      });

  Future<Result<QrPaymentResult>> payWithWallet({
    required String token,
    required String walletCardId,
    required String idempotencyKey,
  }) =>
      _guard(() async {
        final normalized = token.trim();
        final response = await _client.dio.post<dynamic>(
          '/api/payments/qr/${Uri.encodeComponent(normalized)}/pay',
          data: {
            'paymentMethod': 'wallet',
            'walletCardId': int.tryParse(walletCardId) ?? walletCardId,
            'idempotencyKey': idempotencyKey,
          },
        );
        return _paymentResultFromJson(unwrapApiMap(response.data));
      });

  Future<Result<QrPaymentResult>> payWithMercadoPago({
    required String token,
    required String idempotencyKey,
  }) =>
      _guard(() async {
        final normalized = token.trim();
        final response = await _client.dio.post<dynamic>(
          '/api/payments/qr/${Uri.encodeComponent(normalized)}/pay',
          data: {
            'paymentMethod': 'mercadopago',
            'idempotencyKey': idempotencyKey,
          },
        );
        return _paymentResultFromJson(unwrapApiMap(response.data));
      });

  Future<Result<QrValidatePreview>> validate({
    required String token,
    double? latitude,
    double? longitude,
    String? deviceInfo,
  }) =>
      _guard(() async {
        final response = await _client.dio.post<dynamic>(
          '/api/qr/validate',
          data: {
            'token': token,
            if (latitude != null) 'latitude': latitude,
            if (longitude != null) 'longitude': longitude,
            if (deviceInfo != null && deviceInfo.isNotEmpty)
              'deviceInfo': deviceInfo,
          },
        );
        return _validateFromJson(unwrapApiMap(response.data));
      });

  Future<Result<Map<String, dynamic>>> redeemCoupon(int couponId) =>
      _guard(() async {
        final response = await _client.dio.post<dynamic>(
          '/api/coupons/$couponId/redeem',
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

QrResolveResult _resolveFromJson(Map<String, dynamic> json) {
  final channel = '${json['channel'] ?? 'unknown'}';
  return QrResolveResult(
    channel: channel,
    token: _string(json['token']),
    code: _string(json['code'] ?? json['ciervoUserCode']),
    qrPayload: _string(json['qrPayload']),
    recommendedEndpoint: _string(json['recommendedEndpoint']),
    description: _string(json['description']),
  );
}

QrPaymentDetails _paymentDetailsFromJson(
  String token,
  Map<String, dynamic> json,
) =>
    QrPaymentDetails(
      token: token,
      businessId: _int(json['businessId']),
      businessName: _string(json['businessName']) ?? 'Comercio',
      amount: _double(json['amount']),
      currency: _string(json['currency']) ?? 'COP',
      status: _string(json['status']) ?? 'pending',
      isExpired: json['isExpired'] == true,
      description: _string(json['description']),
      paymentIntentId: _intOrNull(json['paymentIntentId']),
      expiresAt: DateTime.tryParse('${json['expiresAt'] ?? ''}'),
    );

QrPaymentResult _paymentResultFromJson(Map<String, dynamic> json) {
  final receipt = json['receipt'];
  Map<String, dynamic>? receiptMap;
  if (receipt is Map) {
    receiptMap = Map<String, dynamic>.from(receipt);
  }
  return QrPaymentResult(
    status: _string(json['status']) ?? 'unknown',
    paymentMethod: _string(json['paymentMethod']) ?? 'wallet',
    paymentIntentId: _intOrNull(json['paymentIntentId']),
    checkoutUrl: _string(json['checkoutUrl']),
    receiptNumber: receiptMap == null
        ? null
        : _string(receiptMap['receiptNumber'] ?? receiptMap['number']),
    receiptId: receiptMap == null
        ? _string(json['receiptId'])
        : _string(receiptMap['id'] ?? receiptMap['receiptId']),
    amount: receiptMap == null ? null : _double(receiptMap['amount']),
    currency: receiptMap == null ? null : _string(receiptMap['currency']),
  );
}

QrValidatePreview _validateFromJson(Map<String, dynamic> json) {
  final benefit = json['benefit'];
  final coupon = json['coupon'];
  Map<String, dynamic>? benefitMap;
  Map<String, dynamic>? couponMap;
  if (benefit is Map) benefitMap = Map<String, dynamic>.from(benefit);
  if (coupon is Map) couponMap = Map<String, dynamic>.from(coupon);

  return QrValidatePreview(
    valid: json['valid'] == true,
    type: _string(json['type']) ?? 'Generic',
    canRedeem: json['canRedeem'] == true,
    requiresConfirmation: json['requiresConfirmation'] != false,
    qrId: _intOrNull(json['qrId']),
    title: _string(json['title']),
    ownerName: _string(json['ownerName']),
    message: _string(json['message']),
    businessId: _intOrNull(json['businessId']),
    ownerId: _intOrNull(json['ownerId']),
    token: _string(json['token'] ?? json['qrPayload']),
    recommendedRedeemEndpoint: _string(json['recommendedRedeemEndpoint']),
    benefitTitle: benefitMap == null ? null : _string(benefitMap['title']),
    benefitDescription:
        benefitMap == null ? null : _string(benefitMap['description']),
    couponTitle: couponMap == null ? null : _string(couponMap['title']),
    couponDescription:
        couponMap == null ? null : _string(couponMap['description']),
  );
}

String? _string(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int _int(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;

int? _intOrNull(dynamic value) =>
    value is int ? value : int.tryParse('${value ?? ''}');

double _double(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
