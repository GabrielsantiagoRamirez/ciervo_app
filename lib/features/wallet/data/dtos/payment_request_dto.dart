import '../../domain/entities/payment_request.dart';
import '../../../../core/utils/display_formatters.dart';
import '../../../../core/utils/display_labels.dart';

class PaymentRequestDto {
  const PaymentRequestDto({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.description,
    this.payerName,
    this.targetName,
    this.requesterName,
    this.requesterUsername,
    this.requesterCiervoId,
    this.payerUsername,
    this.payerCiervoId,
    this.statusLabel,
    this.createdAt,
    this.expiresAt,
  });

  factory PaymentRequestDto.fromJson(Map<String, dynamic> json) {
    final requester = _personMap(json, 'requester') ??
        _personMap(json, 'sender') ??
        _personMap(json, 'from');
    final payer = _personMap(json, 'payer') ?? _personMap(json, 'to');

    return PaymentRequestDto(
      id: _string(json, const ['id', 'paymentRequestId']),
      amount: _double(json, const ['amount', 'value', 'amountValue']),
      currency: _string(json, const ['currency', 'currencyCode']).isEmpty
          ? 'COP'
          : _string(json, const ['currency', 'currencyCode']),
      status: _resolveStatus(json),
      description: _string(json, const [
        'description',
        'purpose',
        'message',
        'concept',
        'reason',
      ]),
      payerName: _optionalString(json, const [
        'payerName',
        'payerFullName',
        'targetName',
        'targetFullName',
      ]) ??
          _personName(payer),
      targetName: _optionalString(json, const [
        'targetName',
        'targetFullName',
        'beneficiaryName',
      ]),
      requesterName: _optionalString(json, const [
        'requesterName',
        'requesterFullName',
        'senderName',
        'senderFullName',
        'fromName',
      ]) ??
          _personName(requester),
      requesterUsername: _optionalString(json, const [
        'requesterUsername',
        'senderUsername',
        'fromUsername',
        'username',
      ]) ??
          _personField(requester, const ['username', 'userName']),
      requesterCiervoId: _optionalString(json, const [
        'requesterCiervoUserCode',
        'requesterCiervoId',
        'senderCiervoUserCode',
        'senderCiervoId',
        'fromCiervoUserCode',
      ]) ??
          _personField(requester, const [
            'ciervoUserCode',
            'ciervoId',
            'publicCode',
          ]),
      payerUsername: _optionalString(json, const [
        'payerUsername',
        'targetUsername',
      ]) ??
          _personField(payer, const ['username', 'userName']),
      payerCiervoId: _optionalString(json, const [
        'payerCiervoUserCode',
        'payerCiervoId',
        'targetCiervoUserCode',
      ]) ??
          _personField(payer, const ['ciervoUserCode', 'ciervoId']),
      statusLabel: _optionalString(json, const [
        'statusLabel',
        'statusName',
        'statusText',
      ]),
      createdAt: DateTime.tryParse(_string(json, const ['createdAt', 'date'])),
      expiresAt: DateTime.tryParse(_string(json, const ['expiresAt'])),
    );
  }

  final String id;
  final double amount;
  final String currency;
  final String status;
  final String description;
  final String? payerName;
  final String? targetName;
  final String? requesterName;
  final String? requesterUsername;
  final String? requesterCiervoId;
  final String? payerUsername;
  final String? payerCiervoId;
  final String? statusLabel;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  PaymentRequest toDomain() {
    final resolvedStatus = statusLabel?.trim().isNotEmpty == true
        ? statusLabel!
        : DisplayLabels.paymentRequestStatus(status);
    return PaymentRequest(
      id: id,
      amount: amount,
      currency: currency,
      status: resolvedStatus,
      rawStatus: status,
      description: description,
      payerName: payerName,
      targetName: targetName,
      requesterName: requesterName,
      requesterUsername: requesterUsername,
      requesterCiervoId: requesterCiervoId,
      payerUsername: payerUsername,
      payerCiervoId: payerCiervoId,
      createdAt: createdAt,
      expiresAt: expiresAt,
    );
  }

  static List<PaymentRequestDto> listFrom(dynamic value) {
    final source = value is Map<String, dynamic>
        ? value['value'] ?? value['data'] ?? value
        : value;
    final items = source is List
        ? source
        : source is Map<String, dynamic> && source['items'] is List
        ? source['items'] as List
        : const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(PaymentRequestDto.fromJson)
        .toList();
  }

  static String _resolveStatus(Map<String, dynamic> json) {
    final label = _optionalString(json, const [
      'statusLabel',
      'statusName',
      'statusText',
    ]);
    if (label != null) return label;
    final status = _optionalString(json, const ['status', 'statusName']);
    if (status != null) return status;
    return _string(json, const ['statusId']);
  }

  static Map<String, dynamic>? _personMap(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value is Map<String, dynamic>) return value;
    return null;
  }

  static String? _personName(Map<String, dynamic>? person) {
    if (person == null) return null;
    final display = DisplayFormatters.safeDisplayName(
      displayName: _personField(person, const ['displayName']),
      firstName: _personField(person, const ['firstName', 'name']),
      lastName: _personField(person, const ['lastName']),
      fullName: _personField(person, const ['fullName']),
      username: _personField(person, const ['username', 'userName']),
      ciervoId: _personField(person, const [
        'ciervoUserCode',
        'ciervoId',
        'publicCode',
      ]),
      fallback: '',
    );
    return display.isEmpty ? null : display;
  }

  static String? _personField(
    Map<String, dynamic>? person,
    List<String> keys,
  ) {
    if (person == null) return null;
    return _optionalString(person, keys);
  }

  static String _string(Map<String, dynamic> json, List<String> keys) {
    return _optionalString(json, keys) ?? '';
  }

  static String? _optionalString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().isNotEmpty) {
        final text = value.toString().trim();
        if (text.toLowerCase() != 'null') return text;
      }
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
