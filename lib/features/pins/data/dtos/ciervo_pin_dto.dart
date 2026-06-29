import '../../domain/entities/ciervo_pin.dart';

class CiervoPinDto {
  const CiervoPinDto({
    required this.id,
    required this.amount,
    required this.status,
    required this.statusName,
    this.pin,
    this.currency,
    this.expiresAt,
    this.walletHoldId,
    this.businessId,
  });

  factory CiervoPinDto.fromJson(Map<String, dynamic> json) {
    return CiervoPinDto(
      id: _string(json, const ['id', 'pinId']),
      pin: _optionalString(json, const ['pin', 'pinCode']),
      amount: _double(json, const ['amount']),
      currency: _optionalString(json, const ['currency']) ?? 'COP',
      status: _string(json, const ['status', 'statusId']),
      statusName: _string(json, const ['statusName']),
      expiresAt: DateTime.tryParse('${json['expiresAt'] ?? ''}'),
      walletHoldId: _optionalString(json, const ['walletHoldId']),
      businessId: _optionalString(json, const ['businessId']),
    );
  }

  final String id;
  final String? pin;
  final double amount;
  final String? currency;
  final String status;
  final String statusName;
  final DateTime? expiresAt;
  final String? walletHoldId;
  final String? businessId;

  CiervoPin toDomain({String? revealedPin}) => CiervoPin(
    id: id,
    pin: revealedPin ?? pin,
    amount: amount,
    currency: currency ?? 'COP',
    status: status,
    statusName: statusName,
    expiresAt: expiresAt,
    walletHoldId: walletHoldId,
    businessId: businessId,
  );

  static List<CiervoPinDto> listFrom(dynamic value) {
    final items = value is List
        ? value
        : value is Map<String, dynamic> && value['items'] is List
        ? value['items'] as List
        : const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(CiervoPinDto.fromJson)
        .toList();
  }

  static String _string(Map<String, dynamic> json, List<String> keys) {
    return _optionalString(json, keys) ?? '';
  }

  static String? _optionalString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().isNotEmpty) return value.toString();
    }
    return null;
  }

  static double _double(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return 0;
  }
}
