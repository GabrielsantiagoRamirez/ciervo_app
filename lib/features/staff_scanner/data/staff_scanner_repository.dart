// ignore_for_file: use_null_aware_elements

import 'dart:io';

import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response_unwrapper.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/result.dart';
import '../domain/entities/staff_scanner_models.dart';

class StaffScannerRepository {
  const StaffScannerRepository(this._client);

  final NetworkClient _client;

  Future<Result<StaffPermissions>> permissions() => _guard(() async {
    final response = await _client.dio.get<dynamic>('/api/staff/me/permissions');
    return _permissionsFromJson(unwrapApiMap(response.data));
  });

  Future<Result<StaffQrValidation>> validate({
    required String payload,
    double? latitude,
    double? longitude,
  }) =>
      _guard(() async {
        final response = await _client.dio.post<dynamic>(
          '/api/qr/validate',
          data: _scanPayload(payload, latitude, longitude),
        );
        return _validationFromJson(unwrapApiMap(response.data));
      });

  Future<Result<StaffQrRedeemResult>> redeem({
    required String payload,
    String? qrId,
    double? latitude,
    double? longitude,
  }) =>
      _guard(() async {
        final response = await _client.dio.post<dynamic>(
          '/api/qr/redeem',
          data: {
            ..._scanPayload(payload, latitude, longitude),
            if (qrId != null && qrId.isNotEmpty) 'qrId': qrId,
          },
        );
        return _redeemFromJson(unwrapApiMap(response.data));
      });

  Future<Result<List<StaffQrScanAudit>>> history() => _guard(() async {
    final response = await _client.dio.get<dynamic>('/api/staff/qr-scans/me');
    return unwrapApiList(response.data)
        .whereType<Map<String, dynamic>>()
        .map(_auditFromJson)
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

Map<String, dynamic> _scanPayload(
  String payload,
  double? latitude,
  double? longitude,
) =>
    {
      'token': payload,
      'payload': payload,
      'qrPayload': payload,
      'scannedAt': DateTime.now().toUtc().toIso8601String(),
      'deviceInfo':
          '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };

StaffPermissions _permissionsFromJson(Map<String, dynamic> json) =>
    StaffPermissions(
      businessId: _int(json['businessId']),
      businessName: _string(json['businessName'] ?? json['business']?['name']),
      staffId: _int(json['staffId']),
      staffName: _string(json['staffName'] ?? json['name']),
      roleName: _string(json['roleName']),
      permissions: _stringList(json['permissions']),
      canUseMobileScanner: json['canUseMobileScanner'] == true ||
          _stringList(json['permissions']).contains('qr.scan'),
    );

StaffQrValidation _validationFromJson(Map<String, dynamic> json) =>
    StaffQrValidation(
      valid: json['valid'] == true,
      qrId: _string(json['qrId']),
      type: _string(json['type']),
      status: _string(json['status']),
      title: _string(json['title']),
      ownerName: _string(json['ownerName']),
      canRedeem: json['canRedeem'] == true,
      requiresConfirmation: json['requiresConfirmation'] != false,
      message: _string(json['message']),
    );

StaffQrRedeemResult _redeemFromJson(Map<String, dynamic> json) =>
    StaffQrRedeemResult(
      redeemed: json['redeemed'] == true,
      status: _string(json['status']),
      redeemedAt: DateTime.tryParse('${json['redeemedAt'] ?? ''}'),
      redeemedBy: _string(json['redeemedBy']),
      message: _string(json['message']),
    );

StaffQrScanAudit _auditFromJson(Map<String, dynamic> json) => StaffQrScanAudit(
  id: '${json['id'] ?? ''}',
  result: '${json['result'] ?? json['status'] ?? 'Unknown'}',
  qrType: _string(json['qrType'] ?? json['type']),
  resourceTitle: _string(json['resourceTitle'] ?? json['title']),
  ownerName: _string(json['ownerName'] ?? json['clientName']),
  failureReason: _string(json['failureReason'] ?? json['message']),
  scannedAt: DateTime.tryParse(
    '${json['scannedAt'] ?? json['createdAt'] ?? ''}',
  ),
);

int? _int(dynamic value) => value is int ? value : int.tryParse('$value');

String? _string(dynamic value) {
  if (value == null || value.toString().isEmpty) return null;
  return value.toString();
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const [];
}
