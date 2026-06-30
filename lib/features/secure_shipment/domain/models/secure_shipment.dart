enum SecureShipmentRole { sender, receiver, none }

String? _str(dynamic value) {
  if (value == null) return null;
  final text = '$value'.trim();
  return text.isEmpty ? null : text;
}

class SecureShipment {
  const SecureShipment({
    required this.publicId,
    required this.statusName,
    this.senderUserId,
    this.receiverUserId,
    this.senderName,
    this.receiverName,
    this.receiverPhone,
    this.originAddress = '',
    this.destinationAddress = '',
    this.totalAmount = 0,
    this.currency = 'COP',
    this.productValue,
    this.shippingValue,
    this.insuranceValue,
    this.taxValue,
    this.commissionValue,
    this.trackingNumber,
    this.logisticsCompany,
    this.observations,
    this.hasActiveHold = false,
    this.hasActiveDispute = false,
    this.pinsGenerated = false,
    this.businessId,
    this.city,
    this.country,
    this.estimatedDeliveryDate,
    this.createdAt,
  });

  final String publicId;
  final String statusName;
  final int? senderUserId;
  final int? receiverUserId;
  final String? senderName;
  final String? receiverName;
  final String? receiverPhone;
  final String originAddress;
  final String destinationAddress;
  final double totalAmount;
  final String currency;
  final double? productValue;
  final double? shippingValue;
  final double? insuranceValue;
  final double? taxValue;
  final double? commissionValue;
  final String? trackingNumber;
  final String? logisticsCompany;
  final String? observations;
  final bool hasActiveHold;
  final bool hasActiveDispute;
  final bool pinsGenerated;
  final int? businessId;
  final String? city;
  final String? country;
  final String? estimatedDeliveryDate;
  final String? createdAt;

  SecureShipmentRole roleFor(String? currentUserId) {
    if (currentUserId == null || currentUserId.isEmpty) {
      return SecureShipmentRole.none;
    }
    final me = int.tryParse(currentUserId) ?? currentUserId;
    if ('$senderUserId' == '$me') return SecureShipmentRole.sender;
    if ('$receiverUserId' == '$me') return SecureShipmentRole.receiver;
    return SecureShipmentRole.none;
  }

  String get counterpartyLabel {
    return receiverName ?? senderName ?? 'Contraparte';
  }

  factory SecureShipment.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

    int? intOrNull(dynamic v) {
      if (v is int) return v;
      return int.tryParse('$v');
    }

    return SecureShipment(
      publicId: '${json['publicId'] ?? json['id'] ?? ''}',
      statusName: '${json['statusName'] ?? json['status'] ?? 'PendingAcceptance'}',
      senderUserId: intOrNull(json['senderUserId']),
      receiverUserId: intOrNull(json['receiverUserId']),
      senderName: _str(json['senderName']),
      receiverName: _str(json['receiverName']),
      receiverPhone: _str(json['receiverPhone']),
      originAddress: '${json['originAddress'] ?? ''}',
      destinationAddress: '${json['destinationAddress'] ?? ''}',
      totalAmount: asDouble(json['totalAmount']),
      currency: '${json['currency'] ?? 'COP'}',
      productValue: json['productValue'] != null ? asDouble(json['productValue']) : null,
      shippingValue:
          json['shippingValue'] != null ? asDouble(json['shippingValue']) : null,
      insuranceValue:
          json['insuranceValue'] != null ? asDouble(json['insuranceValue']) : null,
      taxValue: json['taxValue'] != null ? asDouble(json['taxValue']) : null,
      commissionValue:
          json['commissionValue'] != null ? asDouble(json['commissionValue']) : null,
      trackingNumber: _str(json['trackingNumber']),
      logisticsCompany: _str(json['logisticsCompany']),
      observations: _str(json['observations']),
      hasActiveHold: json['hasActiveHold'] == true,
      hasActiveDispute: json['hasActiveDispute'] == true,
      pinsGenerated: json['pinsGenerated'] == true,
      businessId: intOrNull(json['businessId']),
      city: _str(json['city']),
      country: _str(json['country']),
      estimatedDeliveryDate: _str(json['estimatedDeliveryDate']),
      createdAt: _str(json['createdAt']),
    );
  }
}

class SecureShipmentPinResult {
  const SecureShipmentPinResult({
    this.pin,
    this.pinHint,
    this.expiresAt,
    this.role,
  });

  final String? pin;
  final String? pinHint;
  final String? expiresAt;
  final String? role;

  factory SecureShipmentPinResult.fromJson(Map<String, dynamic> json) =>
      SecureShipmentPinResult(
        pin: _str(json['pin']),
        pinHint: _str(json['pinHint']),
        expiresAt: _str(json['expiresAt']),
        role: _str(json['role']),
      );
}

class SecureShipmentReport {
  const SecureShipmentReport({
    this.totalCount = 0,
    this.completedCount = 0,
    this.disputedCount = 0,
    this.totalVolume = 0,
    this.currency = 'COP',
  });

  final int totalCount;
  final int completedCount;
  final int disputedCount;
  final double totalVolume;
  final String currency;

  factory SecureShipmentReport.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
    int count(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
    return SecureShipmentReport(
      totalCount: count(json['totalCount']),
      completedCount: count(json['completedCount']),
      disputedCount: count(json['disputedCount']),
      totalVolume: asDouble(json['totalVolume']),
      currency: '${json['currency'] ?? 'COP'}',
    );
  }
}
