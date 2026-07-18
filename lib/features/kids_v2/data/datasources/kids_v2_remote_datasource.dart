import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../../domain/models/kids_v2_models.dart';

abstract interface class KidsV2RemoteDataSource {
  Future<KidSession> login(KidLoginCommand command);
  Future<KidSession> refresh(KidRefreshCommand command);
  Future<KidProfile> profile();
  Future<KidSettings> settings();
  Future<KidNfcStatus> nfcStatus();
  Future<List<KidsCommerceItem>> searchCommerce({
    String? name,
    String? city,
    String? category,
  });
  Future<KidsCommerceItem> commerce(int commerceId);
  Future<KidsCommerceItem> readCommerceQr(CommerceQrReadRequest request);
  Future<KidsCommerceItem> validateCommerceId(
    CommerceIdValidateRequest request,
  );
  Future<ReservationPolicy> reservationPolicy(int commerceId);
  Future<ShieldDecision> validateShield(KidsRulesValidateRequest request);
  Future<void> registerSecurityAttempt(KidSecurityAttemptRequest request);
  Future<PaymentRequest> createPaymentRequest(PayForMeCommand command);
  Future<List<PaymentRequest>> sentPaymentRequests();
  Future<void> cancelPaymentRequest(int id);
  Future<KidsQrScanResponse> scanQr(KidsQrScanRequest request);
  Future<KidsQrConfirmResponse> confirmQr(KidsQrConfirmRequest request);
  Future<KidsPaymentStatusSnapshot> tracking(String paymentSessionId);
  Future<KidsPaymentStatusSnapshot> approval(String paymentSessionId);
  Future<KidsRealtimeEventPage> pollEvents(
    String paymentSessionId, {
    required int cursor,
    int take,
  });
  Stream<KidsRealtimeEvent> streamEvents(
    String paymentSessionId, {
    required int cursor,
  });
}

class DioKidsV2RemoteDataSource implements KidsV2RemoteDataSource {
  const DioKidsV2RemoteDataSource(this._client);

  final NetworkClient _client;
  Dio get _dio => _client.dio;
  static const _kids = '/api/v1/kids';
  static const _commerce = '/api/v1/commerce';
  static const _qr = '/api/kids/payments';

  @override
  Future<KidSession> login(KidLoginCommand command) async {
    final response = await _dio.post<dynamic>(
      '$_kids/auth/login',
      data: command.toJson(),
    );
    return KidSession.fromJson(_map(response.data));
  }

  @override
  Future<KidSession> refresh(KidRefreshCommand command) async {
    final response = await _dio.post<dynamic>(
      '$_kids/auth/refresh',
      data: command.toJson(),
    );
    return KidSession.fromJson(_map(response.data));
  }

  @override
  Future<KidProfile> profile() async {
    final response = await _dio.get<dynamic>('$_kids/profile');
    return KidProfile.fromJson(_map(response.data));
  }

  @override
  Future<KidSettings> settings() async {
    final response = await _dio.get<dynamic>('$_kids/settings');
    return KidSettings.fromJson(_map(response.data));
  }

  @override
  Future<KidNfcStatus> nfcStatus() async {
    final response = await _dio.get<dynamic>('$_kids/nfc/status');
    return KidNfcStatus.fromJson(_map(response.data));
  }

  @override
  Future<List<KidsCommerceItem>> searchCommerce({
    String? name,
    String? city,
    String? category,
  }) async {
    final response = await _dio.get<dynamic>(
      '$_commerce/search',
      queryParameters: {
        if (name != null && name.isNotEmpty) 'name': name,
        if (city != null && city.isNotEmpty) 'city': city,
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );
    return _list(
      response.data,
    ).map(KidsCommerceItem.fromJson).toList(growable: false);
  }

  @override
  Future<KidsCommerceItem> commerce(int commerceId) async {
    final response = await _dio.get<dynamic>('$_commerce/$commerceId');
    return KidsCommerceItem.fromJson(_map(response.data));
  }

  @override
  Future<KidsCommerceItem> readCommerceQr(CommerceQrReadRequest request) async {
    final response = await _dio.post<dynamic>(
      '$_commerce/read-qr',
      data: request.toJson(),
    );
    return KidsCommerceItem.fromJson(_map(response.data));
  }

  @override
  Future<KidsCommerceItem> validateCommerceId(
    CommerceIdValidateRequest request,
  ) async {
    final response = await _dio.post<dynamic>(
      '$_commerce/validate-id',
      data: request.toJson(),
    );
    return KidsCommerceItem.fromJson(_map(response.data));
  }

  @override
  Future<ReservationPolicy> reservationPolicy(int commerceId) async {
    final response = await _dio.get<dynamic>(
      '$_commerce/$commerceId/reservation-policy',
    );
    return ReservationPolicy.fromJson(_map(response.data));
  }

  @override
  Future<ShieldDecision> validateShield(
    KidsRulesValidateRequest request,
  ) async {
    final response = await _dio.post<dynamic>(
      '$_kids/shield/validate',
      data: request.toJson(),
    );
    return ShieldDecision.fromJson(_map(response.data));
  }

  @override
  Future<void> registerSecurityAttempt(
    KidSecurityAttemptRequest request,
  ) async {
    await _dio.post<void>('$_kids/security/attempt', data: request.toJson());
  }

  @override
  Future<PaymentRequest> createPaymentRequest(PayForMeCommand command) async {
    final response = await _dio.post<dynamic>(
      '$_kids/payment-requests',
      data: command.toJson(),
    );
    return PaymentRequest.fromJson(_map(response.data));
  }

  @override
  Future<List<PaymentRequest>> sentPaymentRequests() async {
    final response = await _dio.get<dynamic>('$_kids/payment-requests');
    return _list(
      response.data,
    ).map(PaymentRequest.fromJson).toList(growable: false);
  }

  @override
  Future<void> cancelPaymentRequest(int id) async {
    await _dio.put<void>('$_kids/payment-requests/$id/cancel');
  }

  @override
  Future<KidsQrScanResponse> scanQr(KidsQrScanRequest request) async {
    final response = await _dio.post<dynamic>(
      '$_qr/scan',
      data: request.toJson(),
    );
    return KidsQrScanResponse.fromJson(_map(response.data));
  }

  @override
  Future<KidsQrConfirmResponse> confirmQr(KidsQrConfirmRequest request) async {
    final response = await _dio.post<dynamic>(
      '$_qr/confirm',
      data: request.toJson(),
    );
    return KidsQrConfirmResponse.fromJson(_map(response.data));
  }

  @override
  Future<KidsPaymentStatusSnapshot> tracking(String paymentSessionId) async {
    final response = await _dio.get<dynamic>('$_qr/$paymentSessionId/tracking');
    return KidsPaymentStatusSnapshot.fromJson(_map(response.data));
  }

  @override
  Future<KidsPaymentStatusSnapshot> approval(String paymentSessionId) async {
    final response = await _dio.get<dynamic>('$_qr/$paymentSessionId/approval');
    return KidsPaymentStatusSnapshot.fromJson(_map(response.data));
  }

  @override
  Future<KidsRealtimeEventPage> pollEvents(
    String paymentSessionId, {
    required int cursor,
    int take = 100,
  }) async {
    final response = await _dio.get<dynamic>(
      '$_qr/$paymentSessionId/events/poll',
      queryParameters: {'cursor': cursor, 'take': take.clamp(1, 200)},
    );
    return KidsRealtimeEventPage.fromJson(_map(response.data));
  }

  @override
  Stream<KidsRealtimeEvent> streamEvents(
    String paymentSessionId, {
    required int cursor,
  }) async* {
    final response = await _dio.get<ResponseBody>(
      '$_qr/$paymentSessionId/events',
      queryParameters: {'cursor': cursor},
      options: Options(
        responseType: ResponseType.stream,
        headers: const {
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
        },
      ),
    );
    final body = response.data;
    if (body == null) return;

    String? id;
    String? type;
    final data = StringBuffer();
    await for (final line
        in body.stream
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      if (line.isEmpty) {
        if (data.isNotEmpty) {
          final payload = jsonMap(jsonDecode(data.toString()));
          yield KidsRealtimeEvent.fromJson({
            ...payload,
            if (id != null && !payload.containsKey('cursor')) 'cursor': id,
            if (type != null && !payload.containsKey('type')) 'type': type,
          });
        }
        id = null;
        type = null;
        data.clear();
      } else if (line.startsWith('id:')) {
        id = line.substring(3).trim();
      } else if (line.startsWith('event:')) {
        type = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        if (data.isNotEmpty) data.write('\n');
        data.write(line.substring(5).trimLeft());
      }
    }
  }

  Json _map(Object? data) => jsonMap(unwrapApiResponse(data));
  List<Json> _list(Object? data) => jsonMaps(unwrapApiResponse(data));
}
