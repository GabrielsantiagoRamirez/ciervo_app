import 'package:dio/dio.dart';

import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../../../kids_v2/domain/models/kids_v2_models.dart';
import '../../domain/models/master_kids_models.dart';

abstract interface class MasterKidsRemoteDataSource {
  Future<List<PaymentRequest>> pendingPaymentRequests();
  Future<PaymentTokenIssued> approvePaymentRequest(int id);
  Future<void> rejectPaymentRequest(int id, {String? reason});
  Future<void> acceptReservationPolicy(AcceptReservationPolicyCommand command);
  Future<PaymentTokenIssued> createPaymentToken(
    PaymentTokenCreateCommand command,
  );
  Future<PaymentTokenValidation> validatePaymentToken(
    PaymentTokenValidateCommand command,
  );
  Future<KidsBusinessPayment> executePayment(PaymentExecuteCommand command);
  Future<List<KidDeviceRegistration>> devices(int kidId);
  Future<KidDeviceRegistration> registerDevice(
    int kidId,
    RegisterKidDeviceCommand command,
  );
  Future<void> approveDevice(int kidId, int registrationId);
  Future<void> revokeDevice(int kidId, int registrationId);
  Future<KidProfile> createKid(CreateKidCommand command);
  Future<Json> createKidAccount(int kidId, CreateKidAccountCommand command);
  Future<Json> updateLimits(int kidId, ChildSpendingLimitCommand command);
  Future<Json> updateSchedule(int kidId, KidSpendingScheduleCommand command);
  Future<Json> updateCategories(int kidId, KidCategoriesCommand command);
  Future<Json> addGeofence(int kidId, KidGeofenceCommand command);
  Future<KidRulesSnapshot> rules(int kidId);
  Future<Json> addMerchant(int kidId, KidRuleMerchantCommand command);
  Future<void> removeMerchant(int kidId, int merchantId);
  Future<Json> updateGeofence(
    int kidId,
    int geofenceId,
    KidGeofenceCommand command,
  );
  Future<void> removeGeofence(int kidId, int geofenceId);
  Future<Json> addCountry(int kidId, KidRuleCountryCommand command);
  Future<void> removeCountry(int kidId, String countryCode);
  Future<Json> blockMerchant(int kidId, KidRuleMerchantCommand command);
  Future<void> unblockMerchant(int kidId, int merchantId);
  Future<KidLocation> postLocation(int kidId, KidLocationCommand command);
  Future<KidLocation> location(int kidId);
  Future<List<KidLocation>> locationHistory(int kidId, {int take});
  Future<Json> addSecondaryAdmin(int kidId, SecondaryAdminCommand command);
  Future<void> removeSecondaryAdmin(int kidId, int secondaryUserId);
  Future<void> blockAll(KidsSecurityActionCommand command);
  Future<void> unblockAll(KidsSecurityActionCommand command);
  Future<void> resetAttempts(int kidId);
  Future<List<SecurityAttempt>> attempts(int kidId);
  Future<void> enableNfc(int kidId, String physicalCardId);
  Future<void> disableNfc(int kidId, String physicalCardId);
  Future<MasterDashboard> dashboard();
  Future<KidAuditPage> audit({int? kidId, int page, int pageSize});
  Future<AuditExport> exportAudit({int? kidId});
}

class DioMasterKidsRemoteDataSource implements MasterKidsRemoteDataSource {
  const DioMasterKidsRemoteDataSource(this._client);
  final NetworkClient _client;
  Dio get _dio => _client.dio;
  static const _master = '/api/v1/master';

  @override
  Future<List<PaymentRequest>> pendingPaymentRequests() async {
    final response = await _dio.get<dynamic>(
      '$_master/payment-requests/pending',
    );
    return _list(
      response.data,
    ).map(PaymentRequest.fromJson).toList(growable: false);
  }

  @override
  Future<PaymentTokenIssued> approvePaymentRequest(int id) async {
    final response = await _dio.post<dynamic>(
      '$_master/payment-requests/$id/approve',
    );
    return PaymentTokenIssued.fromJson(_map(response.data));
  }

  @override
  Future<void> rejectPaymentRequest(int id, {String? reason}) async {
    await _dio.post<void>(
      '$_master/payment-requests/$id/reject',
      data: {'reason': ?reason},
    );
  }

  @override
  Future<void> acceptReservationPolicy(
    AcceptReservationPolicyCommand command,
  ) async {
    await _dio.post<void>(
      '$_master/reservation-policy/accept',
      data: command.toJson(),
    );
  }

  @override
  Future<PaymentTokenIssued> createPaymentToken(
    PaymentTokenCreateCommand command,
  ) async {
    final response = await _dio.post<dynamic>(
      '/api/v1/payment/token',
      data: command.toJson(),
    );
    return PaymentTokenIssued.fromJson(_map(response.data));
  }

  @override
  Future<PaymentTokenValidation> validatePaymentToken(
    PaymentTokenValidateCommand command,
  ) async {
    final response = await _dio.post<dynamic>(
      '/api/v1/payment/token/validate',
      data: command.toJson(),
    );
    return PaymentTokenValidation.fromJson(_map(response.data));
  }

  @override
  Future<KidsBusinessPayment> executePayment(
    PaymentExecuteCommand command,
  ) async {
    final response = await _dio.post<dynamic>(
      '/api/v1/payment/execute',
      data: command.toJson(),
    );
    return KidsBusinessPayment.fromJson(_map(response.data));
  }

  @override
  Future<List<KidDeviceRegistration>> devices(int kidId) async {
    final response = await _dio.get<dynamic>('$_master/kids/$kidId/devices');
    return _list(
      response.data,
    ).map(KidDeviceRegistration.fromJson).toList(growable: false);
  }

  @override
  Future<KidDeviceRegistration> registerDevice(
    int kidId,
    RegisterKidDeviceCommand command,
  ) async {
    final response = await _dio.post<dynamic>(
      '$_master/kids/$kidId/devices',
      data: command.toJson(),
    );
    return KidDeviceRegistration.fromJson(_map(response.data));
  }

  @override
  Future<void> approveDevice(int kidId, int registrationId) async {
    await _dio.post<void>(
      '$_master/kids/$kidId/devices/$registrationId/approve',
    );
  }

  @override
  Future<void> revokeDevice(int kidId, int registrationId) async {
    await _dio.post<void>(
      '$_master/kids/$kidId/devices/$registrationId/revoke',
    );
  }

  @override
  Future<KidProfile> createKid(CreateKidCommand command) async {
    final response = await _dio.post<dynamic>(
      '$_master/kids',
      data: command.toJson(),
    );
    return KidProfile.fromJson(_map(response.data));
  }

  @override
  Future<Json> createKidAccount(
    int kidId,
    CreateKidAccountCommand command,
  ) async {
    final response = await _dio.post<dynamic>(
      '$_master/kids/$kidId/account',
      data: command.toJson(),
    );
    return _map(response.data);
  }

  @override
  Future<Json> updateLimits(
    int kidId,
    ChildSpendingLimitCommand command,
  ) async {
    final response = await _dio.put<dynamic>(
      '/api/kids/$kidId/rules/limits',
      data: command.toJson(),
    );
    return _map(response.data);
  }

  @override
  Future<Json> updateSchedule(
    int kidId,
    KidSpendingScheduleCommand command,
  ) async {
    final response = await _dio.put<dynamic>(
      '/api/kids/$kidId/rules/schedules',
      data: command.toJson(),
    );
    return _map(response.data);
  }

  @override
  Future<Json> updateCategories(int kidId, KidCategoriesCommand command) async {
    final response = await _dio.post<dynamic>(
      '/api/kids/$kidId/rules/categories',
      data: command.toJson(),
    );
    return _map(response.data);
  }

  @override
  Future<Json> addGeofence(int kidId, KidGeofenceCommand command) async {
    final response = await _dio.post<dynamic>(
      '/api/kids/$kidId/rules/geofences',
      data: command.toJson(),
    );
    return _map(response.data);
  }

  @override
  Future<KidRulesSnapshot> rules(int kidId) async {
    final root = '/api/kids/$kidId/rules';
    final responses = await Future.wait([
      _dio.get<dynamic>('$root/merchants'),
      _dio.get<dynamic>('$root/categories'),
      _dio.get<dynamic>('$root/limits'),
      _dio.get<dynamic>('$root/schedules'),
      _dio.get<dynamic>('$root/geofences'),
      _dio.get<dynamic>('$root/countries'),
      _dio.get<dynamic>('$root/blocked-merchants'),
    ]);
    return KidRulesSnapshot(
      merchants: _maps(
        responses[0].data,
      ).map(KidRuleItem.fromJson).toList(growable: false),
      categories: _maps(
        responses[1].data,
      ).map(KidRuleItem.fromJson).toList(growable: false),
      limits: KidSpendingLimits.fromJson(_map(responses[2].data)),
      schedules: _maps(
        responses[3].data,
        singleton: true,
      ).map(KidSpendingSchedule.fromJson).toList(growable: false),
      geofences: _maps(
        responses[4].data,
      ).map(KidGeofence.fromJson).toList(growable: false),
      countries: _maps(
        responses[5].data,
      ).map(KidRuleCountry.fromJson).toList(growable: false),
      blockedMerchants: _maps(
        responses[6].data,
      ).map(KidRuleItem.fromJson).toList(growable: false),
    );
  }

  @override
  Future<Json> addMerchant(int kidId, KidRuleMerchantCommand command) async {
    final response = await _dio.post<dynamic>(
      '/api/kids/$kidId/rules/merchants',
      data: command.toJson(),
    );
    return _map(response.data);
  }

  @override
  Future<void> removeMerchant(int kidId, int merchantId) =>
      _dio.delete<void>('/api/kids/$kidId/rules/merchants/$merchantId');

  @override
  Future<Json> updateGeofence(
    int kidId,
    int geofenceId,
    KidGeofenceCommand command,
  ) async {
    final response = await _dio.put<dynamic>(
      '/api/kids/$kidId/rules/geofences/$geofenceId',
      data: command.toJson(),
    );
    return _map(response.data);
  }

  @override
  Future<void> removeGeofence(int kidId, int geofenceId) =>
      _dio.delete<void>('/api/kids/$kidId/rules/geofences/$geofenceId');

  @override
  Future<Json> addCountry(int kidId, KidRuleCountryCommand command) async {
    final response = await _dio.post<dynamic>(
      '/api/kids/$kidId/rules/countries',
      data: command.toJson(),
    );
    return _map(response.data);
  }

  @override
  Future<void> removeCountry(int kidId, String countryCode) =>
      _dio.delete<void>(
        '/api/kids/$kidId/rules/countries/${Uri.encodeComponent(countryCode)}',
      );

  @override
  Future<Json> blockMerchant(int kidId, KidRuleMerchantCommand command) async {
    final response = await _dio.post<dynamic>(
      '/api/kids/$kidId/rules/blocked-merchants',
      data: command.toJson(),
    );
    return _map(response.data);
  }

  @override
  Future<void> unblockMerchant(int kidId, int merchantId) =>
      _dio.delete<void>('/api/kids/$kidId/rules/blocked-merchants/$merchantId');

  @override
  Future<KidLocation> postLocation(
    int kidId,
    KidLocationCommand command,
  ) async {
    final response = await _dio.post<dynamic>(
      '/api/kids/$kidId/location',
      data: command.toJson(),
    );
    return KidLocation.fromJson(_map(response.data));
  }

  @override
  Future<KidLocation> location(int kidId) async {
    final response = await _dio.get<dynamic>('/api/kids/$kidId/location');
    return KidLocation.fromJson(_map(response.data));
  }

  @override
  Future<List<KidLocation>> locationHistory(int kidId, {int take = 50}) async {
    final response = await _dio.get<dynamic>(
      '/api/kids/$kidId/location/locations',
      queryParameters: {'take': take.clamp(1, 200)},
    );
    return _maps(
      response.data,
    ).map(KidLocation.fromJson).toList(growable: false);
  }

  @override
  Future<Json> addSecondaryAdmin(
    int kidId,
    SecondaryAdminCommand command,
  ) async {
    final response = await _dio.post<dynamic>(
      '$_master/kids/$kidId/secondary-admin',
      data: command.toJson(),
    );
    return _map(response.data);
  }

  @override
  Future<void> removeSecondaryAdmin(int kidId, int secondaryUserId) async {
    await _dio.delete<void>(
      '$_master/kids/$kidId/secondary-admin/$secondaryUserId',
    );
  }

  @override
  Future<void> blockAll(KidsSecurityActionCommand command) async {
    await _dio.post<void>('/api/v1/security/block-all', data: command.toJson());
  }

  @override
  Future<void> unblockAll(KidsSecurityActionCommand command) async {
    await _dio.post<void>(
      '/api/v1/security/unblock-all',
      data: command.toJson(),
    );
  }

  @override
  Future<void> resetAttempts(int kidId) async {
    await _dio.post<void>(
      '$_master/security/reset-attempts',
      data: {'kidId': kidId},
    );
  }

  @override
  Future<List<SecurityAttempt>> attempts(int kidId) async {
    final response = await _dio.get<dynamic>(
      '/api/v1/kids/security/attempts/$kidId',
    );
    return _list(
      response.data,
    ).map(SecurityAttempt.fromJson).toList(growable: false);
  }

  @override
  Future<void> enableNfc(int kidId, String physicalCardId) async {
    await _dio.post<void>('$_master/kids/$kidId/nfc/$physicalCardId/enable');
  }

  @override
  Future<void> disableNfc(int kidId, String physicalCardId) async {
    await _dio.post<void>('$_master/kids/$kidId/nfc/$physicalCardId/disable');
  }

  @override
  Future<MasterDashboard> dashboard() async {
    final response = await _dio.get<dynamic>('$_master/dashboard');
    return MasterDashboard.fromJson(_map(response.data));
  }

  @override
  Future<KidAuditPage> audit({
    int? kidId,
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await _dio.get<dynamic>(
      '/api/v1/audit/kids',
      queryParameters: {
        'kidId': ?kidId,
        'page': page,
        'pageSize': pageSize.clamp(1, 200),
      },
    );
    return KidAuditPage.fromJson(_map(response.data));
  }

  @override
  Future<AuditExport> exportAudit({int? kidId}) async {
    final response = await _dio.get<List<int>>(
      '/api/v1/audit/export',
      queryParameters: {'kidId': ?kidId},
      options: Options(responseType: ResponseType.bytes),
    );
    return AuditExport(
      bytes: response.data ?? const [],
      fileName: _fileName(response.headers) ?? 'kids-audit.csv',
      contentType: response.headers.value('content-type') ?? 'text/csv',
    );
  }

  Json _map(Object? data) => jsonMap(unwrapApiResponse(data));
  List<Json> _list(Object? data) => jsonMaps(unwrapApiResponse(data));
  List<Json> _maps(Object? data, {bool singleton = false}) {
    final value = unwrapApiResponse(data);
    if (value is List) return jsonMaps(value);
    if (value is Map) {
      final map = jsonMap(value);
      final items =
          map['items'] ??
          map['merchants'] ??
          map['categories'] ??
          map['schedules'] ??
          map['geofences'] ??
          map['countries'] ??
          map['blockedMerchants'] ??
          map['locations'];
      if (items is List) return jsonMaps(items);
      if (singleton) return [map];
    }
    return const [];
  }

  String? _fileName(Headers headers) {
    final disposition = headers.value('content-disposition');
    if (disposition == null) return null;
    final encoded = RegExp(
      r'''filename\*=UTF-8''([^;]+)''',
      caseSensitive: false,
    ).firstMatch(disposition)?.group(1);
    if (encoded != null) return Uri.decodeComponent(encoded);
    return RegExp(
      r'''filename="?([^";]+)"?''',
      caseSensitive: false,
    ).firstMatch(disposition)?.group(1);
  }
}
