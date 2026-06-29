import '../../domain/entities/nfc_models.dart';

class NfcPayloadDto {
  const NfcPayloadDto({
    required this.version,
    required this.token,
    required this.sessionId,
    this.expiresAt,
    this.amount,
    this.currency,
  });

  final int version;
  final String token;
  final int sessionId;
  final DateTime? expiresAt;
  final double? amount;
  final String? currency;

  factory NfcPayloadDto.fromJson(Map<String, dynamic> json) {
    return NfcPayloadDto(
      version: _int(json['v'] ?? json['version'], fallback: 1),
      token: '${json['t'] ?? json['token'] ?? ''}',
      sessionId: _int(json['s'] ?? json['sessionId']),
      expiresAt: _date(json['exp'] ?? json['expiresAt']),
      amount: _double(json['amt'] ?? json['amount']),
      currency: _stringOrNull(json['cur'] ?? json['currency']),
    );
  }

  NfcPayload toDomain() => NfcPayload(
    version: version,
    token: token,
    sessionId: sessionId,
    expiresAt: expiresAt,
    amount: amount,
    currency: currency,
  );
}

class NfcSessionDto {
  const NfcSessionDto({
    required this.id,
    required this.token,
    required this.status,
    this.nfcPayload,
    this.expiresAt,
    this.amount,
    this.currency,
    this.businessId,
    this.businessName,
    this.walletCardId,
    this.description,
    this.receiptId,
  });

  final int id;
  final String token;
  final String status;
  final NfcPayloadDto? nfcPayload;
  final DateTime? expiresAt;
  final double? amount;
  final String? currency;
  final int? businessId;
  final String? businessName;
  final int? walletCardId;
  final String? description;
  final int? receiptId;

  factory NfcSessionDto.fromJson(Map<String, dynamic> json) {
    final payloadRaw = json['nfcPayload'];
    return NfcSessionDto(
      id: _int(json['id']),
      token: '${json['token'] ?? ''}',
      status: '${json['status'] ?? 'Active'}',
      nfcPayload: payloadRaw is Map<String, dynamic>
          ? NfcPayloadDto.fromJson(payloadRaw)
          : null,
      expiresAt: _date(json['expiresAt']),
      amount: _double(json['amount'] ?? json['amt']),
      currency: _stringOrNull(json['currency'] ?? json['cur']),
      businessId: _intOrNull(json['businessId']),
      businessName: _stringOrNull(json['businessName']),
      walletCardId: _intOrNull(json['walletCardId']),
      description: _stringOrNull(json['description']),
      receiptId: _intOrNull(json['receiptId']),
    );
  }

  NfcSession toDomain() => NfcSession(
    id: id,
    token: token,
    status: status,
    nfcPayload: nfcPayload?.toDomain(),
    expiresAt: expiresAt ?? nfcPayload?.expiresAt,
    amount: amount ?? nfcPayload?.amount,
    currency: currency ?? nfcPayload?.currency,
    businessId: businessId,
    businessName: businessName,
    walletCardId: walletCardId,
    description: description,
    receiptId: receiptId,
  );
}

class PhysicalNfcCardDto {
  const PhysicalNfcCardDto({
    required this.id,
    required this.cardUid,
    required this.label,
    required this.status,
    this.walletCardId,
    this.createdAt,
  });

  final int id;
  final String cardUid;
  final String label;
  final String status;
  final int? walletCardId;
  final DateTime? createdAt;

  factory PhysicalNfcCardDto.fromJson(Map<String, dynamic> json) {
    return PhysicalNfcCardDto(
      id: _int(json['id']),
      cardUid: '${json['cardUid'] ?? json['uid'] ?? ''}',
      label: '${json['label'] ?? 'Tarjeta CIERVO'}',
      status: '${json['status'] ?? 'Active'}',
      walletCardId: _intOrNull(json['walletCardId']),
      createdAt: _date(json['createdAt']),
    );
  }

  PhysicalNfcCard toDomain() => PhysicalNfcCard(
    id: id,
    cardUid: cardUid,
    label: label,
    status: status,
    walletCardId: walletCardId,
    createdAt: createdAt,
  );

  static List<PhysicalNfcCardDto> listFrom(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map(PhysicalNfcCardDto.fromJson)
          .toList();
    }
    return const [];
  }
}

int _int(dynamic value, {int fallback = 0}) =>
    value is int ? value : int.tryParse('$value') ?? fallback;

int? _intOrNull(dynamic value) {
  if (value == null) return null;
  return _int(value);
}

double? _double(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}

String? _stringOrNull(dynamic value) {
  if (value == null) return null;
  final text = '$value'.trim();
  return text.isEmpty ? null : text;
}

DateTime? _date(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse('$value');
}
