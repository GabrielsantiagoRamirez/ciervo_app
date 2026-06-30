import 'package:dio/dio.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response_unwrapper.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/result.dart';
import '../core/secure_shipment_keys.dart';
import '../domain/models/secure_shipment.dart';

class SecureShipmentRepository {
  const SecureShipmentRepository(this._client);

  final NetworkClient _client;

  Future<Result<SecureShipment>> createShipment({
    required String originAddress,
    required String destinationAddress,
    required double totalAmount,
    String? receiverUserId,
    String? receiverCiervoId,
    String? receiverName,
    String? receiverPhone,
    int? businessId,
    String? city,
    String? country,
    String? logisticsCompany,
    String? trackingNumber,
    double? productValue,
    double? shippingValue,
    double? insuranceValue,
    double? taxValue,
    double? commissionValue,
    String? observations,
    String? idempotencyKey,
  }) =>
      _guard(() async {
        final response = await _client.dio.post<dynamic>(
          '/api/secure-shipments',
          data: {
            'originAddress': originAddress.trim(),
            'destinationAddress': destinationAddress.trim(),
            'totalAmount': totalAmount,
            'currency': 'COP',
            'country': country ?? 'CO',
            if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
            if (receiverUserId != null)
              'receiverUserId': int.tryParse(receiverUserId) ?? receiverUserId,
            if (receiverCiervoId != null && receiverCiervoId.trim().isNotEmpty)
              'receiverCiervoId': receiverCiervoId.trim(),
            if (receiverName != null && receiverName.trim().isNotEmpty)
              'receiverName': receiverName.trim(),
            if (receiverPhone != null && receiverPhone.trim().isNotEmpty)
              'receiverPhone': receiverPhone.trim(),
            if (businessId != null) 'businessId': businessId,
            if (logisticsCompany != null && logisticsCompany.trim().isNotEmpty)
              'logisticsCompany': logisticsCompany.trim(),
            if (trackingNumber != null && trackingNumber.trim().isNotEmpty)
              'trackingNumber': trackingNumber.trim(),
            if (productValue != null) 'productValue': productValue,
            if (shippingValue != null) 'shippingValue': shippingValue,
            if (insuranceValue != null) 'insuranceValue': insuranceValue,
            if (taxValue != null) 'taxValue': taxValue,
            if (commissionValue != null) 'commissionValue': commissionValue,
            if (observations != null && observations.trim().isNotEmpty)
              'observations': observations.trim(),
            'idempotencyKey': idempotencyKey ?? SecureShipmentKeys.create(),
          },
        );
        return SecureShipment.fromJson(unwrapApiMap(response.data));
      });

  Future<Result<List<SecureShipment>>> listShipments({
    int take = 50,
    String? status,
    int? businessId,
    bool sentOnly = false,
    bool receivedOnly = false,
  }) =>
      _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/secure-shipments',
          queryParameters: {
            'take': take,
            if (status != null && status.isNotEmpty) 'status': status,
            if (businessId != null) 'businessId': businessId,
            if (sentOnly) 'role': 'sender',
            if (receivedOnly) 'role': 'receiver',
          },
        );
        return _listFromResponse(response.data);
      });

  Future<Result<SecureShipment>> getShipment(String publicId) => _guard(
        () async {
          final response = await _client.dio.get<dynamic>(
            '/api/secure-shipments/$publicId',
          );
          return SecureShipment.fromJson(unwrapApiMap(response.data));
        },
      );

  Future<Result<SecureShipment>> acceptShipment(String publicId) =>
      _action(publicId, 'accept');

  Future<Result<SecureShipment>> rejectShipment(String publicId) =>
      _action(publicId, 'reject');

  Future<Result<SecureShipment>> cancelShipment(String publicId) =>
      _action(publicId, 'cancel');

  Future<Result<Map<String, dynamic>>> createHold({
    required String publicId,
    required String walletCardId,
    String? idempotencyKey,
  }) =>
      _guard(() async {
        final response = await _client.dio.post<dynamic>(
          '/api/secure-shipments/$publicId/hold',
          data: {
            'walletCardId': int.tryParse(walletCardId) ?? walletCardId,
            'idempotencyKey': idempotencyKey ?? SecureShipmentKeys.hold(),
          },
        );
        return unwrapApiMap(response.data);
      });

  Future<Result<Map<String, dynamic>>> getHold(String publicId) =>
      _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/secure-shipments/$publicId/hold',
        );
        return unwrapApiMap(response.data);
      });

  Future<Result<SecureShipmentPinResult>> generatePins({
    required String publicId,
    int expirationMinutes = 10,
  }) =>
      _guard(() async {
        final response = await _client.dio.post<dynamic>(
          '/api/secure-shipments/$publicId/pins/generate',
          data: {'expirationMinutes': expirationMinutes},
        );
        return SecureShipmentPinResult.fromJson(unwrapApiMap(response.data));
      });

  Future<Result<Map<String, dynamic>>> validatePin({
    required String publicId,
    required String pin,
    required String role,
  }) =>
      _guard(() async {
        final response = await _client.dio.post<dynamic>(
          '/api/secure-shipments/$publicId/pins/validate',
          data: {'pin': pin, 'role': role},
        );
        return unwrapApiMap(response.data);
      });

  Future<Result<SecureShipment>> synchronizePins({
    required String publicId,
    String? idempotencyKey,
  }) =>
      _guard(() async {
        final response = await _client.dio.post<dynamic>(
          '/api/secure-shipments/$publicId/pins/synchronize',
          data: {
            'idempotencyKey': idempotencyKey ?? SecureShipmentKeys.sync(),
          },
        );
        return SecureShipment.fromJson(unwrapApiMap(response.data));
      });

  Future<Result<SecureShipmentPinResult>> regeneratePins(String publicId) =>
      _guard(() async {
        final response = await _client.dio.post<dynamic>(
          '/api/secure-shipments/$publicId/pins/regenerate',
        );
        return SecureShipmentPinResult.fromJson(unwrapApiMap(response.data));
      });

  Future<Result<Map<String, dynamic>>> executePayment({
    required String publicId,
    String? idempotencyKey,
  }) =>
      _guard(() async {
        final response = await _client.dio.post<dynamic>(
          '/api/secure-shipments/$publicId/execute-payment',
          data: {'idempotencyKey': idempotencyKey ?? SecureShipmentKeys.pay()},
        );
        return unwrapApiMap(response.data);
      });

  Future<Result<Map<String, dynamic>>> getReceipt(String publicId) =>
      _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/secure-shipments/$publicId/receipt',
        );
        return unwrapApiMap(response.data);
      });

  Future<Result<void>> openDispute({
    required String publicId,
    required String reason,
  }) =>
      _guard(() async {
        await _client.dio.post<void>(
          '/api/secure-shipments/$publicId/disputes',
          data: {'reason': reason.trim()},
        );
      });

  Future<Result<List<Map<String, dynamic>>>> listDisputes(String publicId) =>
      _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/secure-shipments/$publicId/disputes',
        );
        return unwrapApiList(response.data)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      });

  Future<Result<SecureShipmentReport>> userReport() => _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/secure-shipments/reports/user',
        );
        return SecureShipmentReport.fromJson(unwrapApiMap(response.data));
      });

  Future<Result<SecureShipment>> updateTracking({
    required String publicId,
    String? trackingNumber,
    String? logisticsCompany,
    String? observations,
  }) =>
      _guard(() async {
        final response = await _client.dio.patch<dynamic>(
          '/api/secure-shipments/$publicId',
          data: {
            if (trackingNumber != null) 'trackingNumber': trackingNumber,
            if (logisticsCompany != null) 'logisticsCompany': logisticsCompany,
            if (observations != null) 'observations': observations,
          },
        );
        return SecureShipment.fromJson(unwrapApiMap(response.data));
      });

  Future<Result<SecureShipment>> _action(String publicId, String action) =>
      _guard(() async {
        final response = await _client.dio.post<dynamic>(
          '/api/secure-shipments/$publicId/$action',
        );
        return SecureShipment.fromJson(unwrapApiMap(response.data));
      });

  List<SecureShipment> _listFromResponse(Object? data) {
    final value = unwrapApiResponse(data);
    final items = value is List
        ? value
        : value is Map && value['items'] is List
        ? value['items'] as List
        : const [];
    return items
        .whereType<Map>()
        .map((e) => SecureShipment.fromJson(Map<String, dynamic>.from(e)))
        .where((s) => s.publicId.isNotEmpty)
        .toList();
  }

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Success(await run());
    } on DioException catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
