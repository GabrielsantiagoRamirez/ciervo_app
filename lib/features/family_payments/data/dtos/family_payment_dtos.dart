import '../../domain/entities/family_payment_card.dart';
import '../../domain/entities/family_payment_record.dart';
import '../../domain/entities/kid_parental_rules.dart';
import '../../domain/entities/pending_parent_payment.dart';

class FamilyPaymentCardDto {
  const FamilyPaymentCardDto({
    required this.id,
    required this.brand,
    required this.lastFour,
    required this.status,
    required this.isPrimary,
    required this.isBackup,
    required this.expirationMonth,
    required this.expirationYear,
    required this.alias,
    required this.isFrozen,
  });

  final String id;
  final String brand;
  final String lastFour;
  final String status;
  final bool isPrimary;
  final bool isBackup;
  final String expirationMonth;
  final String expirationYear;
  final String alias;
  final bool isFrozen;

  factory FamilyPaymentCardDto.fromJson(Map<String, dynamic> json) {
    return FamilyPaymentCardDto(
      id: _string(json['id'] ?? json['cardId']),
      brand: _string(json['brand'] ?? json['paymentMethodId'] ?? json['cardBrand']),
      lastFour: _string(
        json['lastFour'] ??
            json['last4'] ??
            json['lastFourDigits'] ??
            json['maskedLastFour'],
      ),
      status: _string(json['status'] ?? json['cardStatus'] ?? 'active'),
      isPrimary: json['isPrimary'] == true || json['primary'] == true,
      isBackup: json['isBackup'] == true || json['backup'] == true,
      expirationMonth: _string(
        json['expirationMonth'] ?? json['expMonth'] ?? json['expiryMonth'],
      ),
      expirationYear: _string(
        json['expirationYear'] ?? json['expYear'] ?? json['expiryYear'],
      ),
      alias: _string(json['alias'] ?? json['displayName'] ?? json['nickname']),
      isFrozen: json['isFrozen'] == true ||
          json['frozen'] == true ||
          _string(json['status']).toLowerCase().contains('frozen'),
    );
  }

  FamilyPaymentCard toDomain() => FamilyPaymentCard(
        id: id,
        brand: brand,
        lastFour: lastFour,
        status: status,
        isPrimary: isPrimary,
        isBackup: isBackup,
        expirationMonth: expirationMonth,
        expirationYear: expirationYear,
        alias: alias,
        isFrozen: isFrozen,
      );

  static List<FamilyPaymentCardDto> listFrom(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => FamilyPaymentCardDto.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    }
    if (value is Map) {
      final items = value['items'] ?? value['cards'];
      if (items is List) return listFrom(items);
      if (value.isNotEmpty) {
        return [FamilyPaymentCardDto.fromJson(Map<String, dynamic>.from(value))];
      }
    }
    return const [];
  }
}

class AddFamilyCardResponseDto {
  const AddFamilyCardResponseDto({
    required this.card,
    required this.requires3ds,
    this.verificationUrl,
  });

  factory AddFamilyCardResponseDto.fromJson(Map<String, dynamic> json) {
    final cardJson = json['card'] ?? json;
    final requires3ds = json['requires3ds'] == true ||
        json['requires3DS'] == true ||
        json['requiresVerification'] == true ||
        json['status']?.toString().toLowerCase() == 'pending_verification';
    return AddFamilyCardResponseDto(
      card: FamilyPaymentCardDto.fromJson(
        Map<String, dynamic>.from(cardJson is Map ? cardJson : json),
      ),
      requires3ds: requires3ds,
      verificationUrl: _nullableString(
        json['verificationUrl'] ??
            json['threeDsUrl'] ??
            json['authenticationUrl'],
      ),
    );
  }

  AddFamilyCardResult toDomain() => AddFamilyCardResult(
        card: card.toDomain(),
        requires3ds: requires3ds,
        verificationUrl: verificationUrl,
      );

  final FamilyPaymentCardDto card;
  final bool requires3ds;
  final String? verificationUrl;
}

class FamilyPaymentRecordDto {
  const FamilyPaymentRecordDto({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.merchantName,
    this.createdAt,
    this.kidId,
    this.kidName,
    this.fundingSource,
    this.cardAlias,
    this.cardLastFour,
    this.city,
    this.usedParentCard = false,
    this.requiresParentApproval = false,
    this.publicReceiptUrl,
  });

  factory FamilyPaymentRecordDto.fromJson(Map<String, dynamic> json) {
    return FamilyPaymentRecordDto(
      id: _string(json['paymentId'] ?? json['id']),
      amount: _num(json['amount'] ?? json['totalAmount']),
      currency: _string(json['currency'] ?? 'COP'),
      status: _string(json['status'] ?? json['paymentStatus']),
      merchantName: _string(
        json['merchantName'] ??
            json['businessName'] ??
            json['storeName'] ??
            'Comercio',
      ),
      createdAt: _date(json['createdAt'] ?? json['paidAt'] ?? json['requestedAt']),
      kidId: _nullableString(json['kidId'] ?? json['childProfileId']),
      kidName: _nullableString(json['kidName'] ?? json['childName']),
      fundingSource: _nullableString(
        json['fundingSource'] ?? json['fundSource'] ?? json['paymentSource'],
      ),
      cardAlias: _nullableString(json['cardAlias'] ?? json['parentCardAlias']),
      cardLastFour: _nullableString(
        json['cardLastFour'] ?? json['parentCardLastFour'],
      ),
      city: _nullableString(json['city'] ?? json['merchantCity']),
      usedParentCard: json['usedParentCard'] == true ||
          json['parentCardUsed'] == true ||
          _string(json['fundingSource']).toLowerCase().contains('parent'),
      requiresParentApproval: json['requiresParentApproval'] == true ||
          json['pendingParentApproval'] == true,
      publicReceiptUrl: _nullableString(
        json['publicReceiptUrl'] ?? json['receiptUrl'],
      ),
    );
  }

  FamilyPaymentRecord toDomain() => FamilyPaymentRecord(
        id: id,
        amount: amount,
        currency: currency,
        status: status,
        merchantName: merchantName,
        createdAt: createdAt,
        kidId: kidId,
        kidName: kidName,
        fundingSource: fundingSource,
        cardAlias: cardAlias,
        cardLastFour: cardLastFour,
        city: city,
      );

  FamilyPaymentDetail toDetailDomain() => FamilyPaymentDetail(
        id: id,
        amount: amount,
        currency: currency,
        status: status,
        merchantName: merchantName,
        createdAt: createdAt,
        kidId: kidId,
        kidName: kidName,
        fundingSource: fundingSource,
        cardAlias: cardAlias,
        cardLastFour: cardLastFour,
        city: city,
        usedParentCard: usedParentCard,
        requiresParentApproval: requiresParentApproval,
        publicReceiptUrl: publicReceiptUrl,
      );

  static List<FamilyPaymentRecordDto> listFrom(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => FamilyPaymentRecordDto.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    }
    if (value is Map) {
      final items = value['items'] ?? value['payments'];
      if (items is List) return listFrom(items);
    }
    return const [];
  }

  final String id;
  final double amount;
  final String currency;
  final String status;
  final String merchantName;
  final DateTime? createdAt;
  final String? kidId;
  final String? kidName;
  final String? fundingSource;
  final String? cardAlias;
  final String? cardLastFour;
  final String? city;
  final bool usedParentCard;
  final bool requiresParentApproval;
  final String? publicReceiptUrl;
}

class PendingParentPaymentDto {
  const PendingParentPaymentDto({
    required this.paymentId,
    required this.kidId,
    required this.kidName,
    required this.merchantName,
    required this.amount,
    required this.currency,
    this.kidPhotoUrl,
    this.city,
    this.requestedAt,
    this.fundingSource,
  });

  factory PendingParentPaymentDto.fromJson(Map<String, dynamic> json) {
    final kid = json['kid'] ?? json['child'];
    final merchant = json['merchant'] ?? json['business'];
    return PendingParentPaymentDto(
      paymentId: _string(json['paymentId'] ?? json['id']),
      kidId: _string(
        json['kidId'] ??
            json['childProfileId'] ??
            (kid is Map ? kid['id'] : null),
      ),
      kidName: _string(
        json['kidName'] ??
            json['childName'] ??
            (kid is Map ? kid['fullName'] ?? kid['name'] : null) ??
            'Menor',
      ),
      kidPhotoUrl: _nullableString(
        json['kidPhotoUrl'] ??
            json['childPhotoUrl'] ??
            (kid is Map ? kid['photoUrl'] ?? kid['imageUrl'] : null),
      ),
      merchantName: _string(
        json['merchantName'] ??
            (merchant is Map ? merchant['name'] : null) ??
            json['businessName'] ??
            'Comercio',
      ),
      city: _nullableString(
        json['city'] ??
            (merchant is Map ? merchant['city'] : null) ??
            json['merchantCity'],
      ),
      amount: _num(json['amount'] ?? json['totalAmount']),
      currency: _string(json['currency'] ?? 'COP'),
      requestedAt: _date(json['requestedAt'] ?? json['createdAt']),
      fundingSource: _nullableString(
        json['fundingSource'] ?? json['fundSource'],
      ),
    );
  }

  PendingParentPayment toDomain() => PendingParentPayment(
        paymentId: paymentId,
        kidId: kidId,
        kidName: kidName,
        kidPhotoUrl: kidPhotoUrl,
        merchantName: merchantName,
        city: city,
        amount: amount,
        currency: currency,
        requestedAt: requestedAt,
        fundingSource: fundingSource,
      );

  final String paymentId;
  final String kidId;
  final String kidName;
  final String? kidPhotoUrl;
  final String merchantName;
  final String? city;
  final double amount;
  final String currency;
  final DateTime? requestedAt;
  final String? fundingSource;
}

class KidPaymentSourceDto {
  factory KidPaymentSourceDto.fromJson(Map<String, dynamic> json) {
    return KidPaymentSourceDto(
      cardId: _nullableString(
        json['cardId'] ?? json['paymentMethodCardId'] ?? json['parentCardId'],
      ),
      mode: KidPaymentApprovalMode.fromApi(
        _nullableString(json['mode'] ?? json['approvalMode']),
      ),
      usePrimaryCard: json['usePrimaryCard'] == true ||
          json['usePrimary'] == true ||
          json['cardId'] == null,
    );
  }

  const KidPaymentSourceDto({
    this.cardId,
    required this.mode,
    required this.usePrimaryCard,
  });

  final String? cardId;
  final KidPaymentApprovalMode mode;
  final bool usePrimaryCard;

  KidPaymentSource toDomain() => KidPaymentSource(
        cardId: cardId,
        mode: mode,
        usePrimaryCard: usePrimaryCard,
      );

  Map<String, dynamic> toJson() => {
        if (cardId != null) 'cardId': cardId,
        'mode': mode.apiValue,
        'usePrimaryCard': usePrimaryCard,
      };
}

class KidSpendingLimitsDto {
  factory KidSpendingLimitsDto.fromJson(Map<String, dynamic> json) {
    return KidSpendingLimitsDto(
      perPurchaseLimit: _nullableNum(
        json['perPurchaseLimit'] ?? json['purchaseLimit'] ?? json['transactionLimit'],
      ),
      dailyLimit: _nullableNum(json['dailyLimit'] ?? json['daily']),
      monthlyLimit: _nullableNum(json['monthlyLimit'] ?? json['monthly']),
    );
  }

  const KidSpendingLimitsDto({
    this.perPurchaseLimit,
    this.dailyLimit,
    this.monthlyLimit,
  });

  final double? perPurchaseLimit;
  final double? dailyLimit;
  final double? monthlyLimit;

  KidSpendingLimits toDomain() => KidSpendingLimits(
        perPurchaseLimit: perPurchaseLimit,
        dailyLimit: dailyLimit,
        monthlyLimit: monthlyLimit,
      );

  Map<String, dynamic> toJson() => {
        if (perPurchaseLimit != null) 'perPurchaseLimit': perPurchaseLimit,
        if (dailyLimit != null) 'dailyLimit': dailyLimit,
        if (monthlyLimit != null) 'monthlyLimit': monthlyLimit,
      };
}

class KidMerchantRulesDto {
  factory KidMerchantRulesDto.fromJson(Map<String, dynamic> json) {
    return KidMerchantRulesDto(
      allowedCategoryIds: _intList(
        json['allowedCategoryIds'] ?? json['allowedCategories'],
      ),
      blockedCategoryIds: _intList(
        json['blockedCategoryIds'] ?? json['blockedCategories'],
      ),
      allowedBusinessIds: _stringList(
        json['allowedBusinessIds'] ?? json['allowedMerchants'],
      ),
      blockedBusinessIds: _stringList(
        json['blockedBusinessIds'] ?? json['blockedMerchants'],
      ),
    );
  }

  const KidMerchantRulesDto({
    required this.allowedCategoryIds,
    required this.blockedCategoryIds,
    required this.allowedBusinessIds,
    required this.blockedBusinessIds,
  });

  final List<int> allowedCategoryIds;
  final List<int> blockedCategoryIds;
  final List<String> allowedBusinessIds;
  final List<String> blockedBusinessIds;

  KidMerchantRules toDomain() => KidMerchantRules(
        allowedCategoryIds: allowedCategoryIds,
        blockedCategoryIds: blockedCategoryIds,
        allowedBusinessIds: allowedBusinessIds,
        blockedBusinessIds: blockedBusinessIds,
      );

  Map<String, dynamic> toJson() => {
        'allowedCategoryIds': allowedCategoryIds,
        'blockedCategoryIds': blockedCategoryIds,
        'allowedBusinessIds': allowedBusinessIds,
        'blockedBusinessIds': blockedBusinessIds,
      };
}

class KidScheduleRulesDto {
  factory KidScheduleRulesDto.fromJson(Map<String, dynamic> json) {
    return KidScheduleRulesDto(
      startTime: _nullableString(json['startTime'] ?? json['fromTime']),
      endTime: _nullableString(json['endTime'] ?? json['toTime']),
      allowedDays: _intList(json['allowedDays'] ?? json['days']),
    );
  }

  const KidScheduleRulesDto({
    this.startTime,
    this.endTime,
    required this.allowedDays,
  });

  final String? startTime;
  final String? endTime;
  final List<int> allowedDays;

  KidScheduleRules toDomain() => KidScheduleRules(
        startTime: startTime,
        endTime: endTime,
        allowedDays: allowedDays,
      );

  Map<String, dynamic> toJson() => {
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
        'allowedDays': allowedDays,
      };
}

class KidAutoPaymentRulesDto {
  factory KidAutoPaymentRulesDto.fromJson(Map<String, dynamic> json) {
    return KidAutoPaymentRulesDto(
      enabled: json['enabled'] == true || json['autoPaymentEnabled'] == true,
      maxAutomaticAmount: _nullableNum(
        json['maxAutomaticAmount'] ?? json['maxAutoAmount'],
      ),
    );
  }

  const KidAutoPaymentRulesDto({
    required this.enabled,
    this.maxAutomaticAmount,
  });

  final bool enabled;
  final double? maxAutomaticAmount;

  KidAutoPaymentRules toDomain() => KidAutoPaymentRules(
        enabled: enabled,
        maxAutomaticAmount: maxAutomaticAmount,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        if (maxAutomaticAmount != null)
          'maxAutomaticAmount': maxAutomaticAmount,
      };
}

class KidApprovalRulesDto {
  factory KidApprovalRulesDto.fromJson(Map<String, dynamic> json) {
    return KidApprovalRulesDto(
      requireApprovalFromAmount: _nullableNum(
        json['requireApprovalFromAmount'] ??
            json['approvalThresholdAmount'],
      ),
      alwaysApprovedCategoryIds: _intList(
        json['alwaysApprovedCategoryIds'] ?? json['autoApprovedCategories'],
      ),
      alwaysManualCategoryIds: _intList(
        json['alwaysManualCategoryIds'] ?? json['manualApprovalCategories'],
      ),
    );
  }

  const KidApprovalRulesDto({
    this.requireApprovalFromAmount,
    required this.alwaysApprovedCategoryIds,
    required this.alwaysManualCategoryIds,
  });

  final double? requireApprovalFromAmount;
  final List<int> alwaysApprovedCategoryIds;
  final List<int> alwaysManualCategoryIds;

  KidApprovalRules toDomain() => KidApprovalRules(
        requireApprovalFromAmount: requireApprovalFromAmount,
        alwaysApprovedCategoryIds: alwaysApprovedCategoryIds,
        alwaysManualCategoryIds: alwaysManualCategoryIds,
      );

  Map<String, dynamic> toJson() => {
        if (requireApprovalFromAmount != null)
          'requireApprovalFromAmount': requireApprovalFromAmount,
        'alwaysApprovedCategoryIds': alwaysApprovedCategoryIds,
        'alwaysManualCategoryIds': alwaysManualCategoryIds,
      };
}

class KidGeofenceRulesDto {
  factory KidGeofenceRulesDto.fromJson(Map<String, dynamic> json) {
    final center = json['center'];
    return KidGeofenceRulesDto(
      enabled: json['enabled'] == true || json['isEnabled'] == true,
      latitude: _nullableNum(
        json['latitude'] ?? (center is Map ? center['latitude'] : null),
      ),
      longitude: _nullableNum(
        json['longitude'] ?? (center is Map ? center['longitude'] : null),
      ),
      radiusMeters: _nullableNum(
        json['radiusMeters'] ?? json['radius'] ?? json['radiusInMeters'],
      ),
    );
  }

  const KidGeofenceRulesDto({
    required this.enabled,
    this.latitude,
    this.longitude,
    this.radiusMeters,
  });

  final bool enabled;
  final double? latitude;
  final double? longitude;
  final double? radiusMeters;

  KidGeofenceRules toDomain() => KidGeofenceRules(
        enabled: enabled,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (radiusMeters != null) 'radiusMeters': radiusMeters,
      };
}

String _string(dynamic value) => value?.toString() ?? '';

String? _nullableString(dynamic value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return null;
  return text;
}

double _num(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value'.replaceAll(',', '.')) ?? 0;
}

double? _nullableNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse('$value'.replaceAll(',', '.'));
}

DateTime? _date(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

List<int> _intList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((item) => int.tryParse('$item'))
      .whereType<int>()
      .toList();
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value.map((item) => '$item').toList();
}
