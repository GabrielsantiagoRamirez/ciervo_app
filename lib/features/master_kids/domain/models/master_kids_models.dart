import '../../../kids_v2/domain/models/kids_v2_models.dart';

class AcceptReservationPolicyCommand {
  const AcceptReservationPolicyCommand({
    required this.paymentRequestId,
    required this.commerceId,
    required this.policyVersion,
    required this.idempotencyKey,
  });
  final int paymentRequestId;
  final int commerceId;
  final int policyVersion;
  final String idempotencyKey;
  Json toJson() => {
    'paymentRequestId': paymentRequestId,
    'commerceId': commerceId,
    'policyVersion': policyVersion,
    'idempotencyKey': idempotencyKey,
  };
}

class PaymentTokenCreateCommand {
  const PaymentTokenCreateCommand({
    required this.paymentRequestId,
    required this.idempotencyKey,
  });
  final int paymentRequestId;
  final String idempotencyKey;
  Json toJson() => {
    'paymentRequestId': paymentRequestId,
    'idempotencyKey': idempotencyKey,
  };
}

class PaymentTokenIssued {
  const PaymentTokenIssued({
    required this.authorizationId,
    required this.paymentRequestId,
    required this.commerceId,
    required this.amount,
    required this.currency,
    required this.expiresAt,
    required this.secretShown,
    this.token,
    this.pin,
  });
  final int authorizationId;
  final int paymentRequestId;
  final int commerceId;
  final double amount;
  final String currency;
  final String? token;
  final String? pin;
  final DateTime expiresAt;
  final bool secretShown;

  factory PaymentTokenIssued.fromJson(Json json) => PaymentTokenIssued(
    authorizationId: integer(json['authorizationId']),
    paymentRequestId: integer(json['paymentRequestId']),
    commerceId: integer(json['commerceId']),
    amount: number(json['amount']),
    currency: json['currency']?.toString() ?? '',
    token: json['token']?.toString(),
    pin: json['pin']?.toString(),
    expiresAt: utcDate(json['expiresAt']),
    secretShown: json['secretShown'] == true,
  );
}

class PaymentTokenValidateCommand {
  const PaymentTokenValidateCommand({required this.token, required this.pin});
  final String token;
  final String pin;
  Json toJson() => {'token': token, 'pin': pin};
}

class PaymentTokenValidation {
  const PaymentTokenValidation({
    required this.valid,
    this.authorizationId,
    this.paymentRequestId,
    this.commerceId,
    this.amount,
    this.currency,
    this.expiresAt,
    this.reason,
  });
  final bool valid;
  final int? authorizationId;
  final int? paymentRequestId;
  final int? commerceId;
  final double? amount;
  final String? currency;
  final DateTime? expiresAt;
  final String? reason;

  factory PaymentTokenValidation.fromJson(Json json) => PaymentTokenValidation(
    valid: json['valid'] == true,
    authorizationId: (json['authorizationId'] as num?)?.toInt(),
    paymentRequestId: (json['paymentRequestId'] as num?)?.toInt(),
    commerceId: (json['commerceId'] as num?)?.toInt(),
    amount: (json['amount'] as num?)?.toDouble(),
    currency: json['currency']?.toString(),
    expiresAt: utcDateOrNull(json['expiresAt']),
    reason: json['reason']?.toString(),
  );
}

class PaymentExecuteCommand {
  const PaymentExecuteCommand({
    required this.token,
    required this.pin,
    required this.idempotencyKey,
    this.latitude,
    this.longitude,
  }) : assert(
         (latitude == null) == (longitude == null),
         'latitude y longitude deben enviarse juntas',
       );
  final String token;
  final String pin;
  final String idempotencyKey;
  final double? latitude;
  final double? longitude;
  Json toJson() => {
    'token': token,
    'pin': pin,
    'idempotencyKey': idempotencyKey,
    'latitude': latitude,
    'longitude': longitude,
  };
}

class KidsBusinessPayment {
  const KidsBusinessPayment({
    required this.id,
    required this.guardianUserId,
    required this.childProfileId,
    required this.childWalletId,
    required this.childWalletCardId,
    required this.businessId,
    required this.paymentIntentId,
    required this.paymentTransactionId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.idempotencyKey,
    required this.createdAt,
    this.childWalletTransactionId,
    this.childReceiptId,
    this.guardianReceiptId,
    this.businessReceiptId,
    this.description,
    this.rejectionReason,
  });
  final int id;
  final int guardianUserId;
  final int childProfileId;
  final int childWalletId;
  final int childWalletCardId;
  final int businessId;
  final int paymentIntentId;
  final int paymentTransactionId;
  final int? childWalletTransactionId;
  final int? childReceiptId;
  final int? guardianReceiptId;
  final int? businessReceiptId;
  final double amount;
  final String currency;
  final int status;
  final String idempotencyKey;
  final String? description;
  final String? rejectionReason;
  final DateTime createdAt;

  factory KidsBusinessPayment.fromJson(Json json) => KidsBusinessPayment(
    id: integer(json['id']),
    guardianUserId: integer(json['guardianUserId']),
    childProfileId: integer(json['childProfileId']),
    childWalletId: integer(json['childWalletId']),
    childWalletCardId: integer(json['childWalletCardId']),
    businessId: integer(json['businessId']),
    paymentIntentId: integer(json['paymentIntentId']),
    paymentTransactionId: integer(json['paymentTransactionId']),
    childWalletTransactionId: (json['childWalletTransactionId'] as num?)
        ?.toInt(),
    childReceiptId: (json['childReceiptId'] as num?)?.toInt(),
    guardianReceiptId: (json['guardianReceiptId'] as num?)?.toInt(),
    businessReceiptId: (json['businessReceiptId'] as num?)?.toInt(),
    amount: number(json['amount']),
    currency: json['currency']?.toString() ?? '',
    status: integer(json['status']),
    idempotencyKey: json['idempotencyKey']?.toString() ?? '',
    description: json['description']?.toString(),
    rejectionReason: json['rejectionReason']?.toString(),
    createdAt: utcDate(json['createdAt']),
  );
}

class RegisterKidDeviceCommand {
  const RegisterKidDeviceCommand({
    required this.firebaseUid,
    required this.deviceId,
    required this.platform,
    required this.appVersion,
  });
  final String firebaseUid;
  final String deviceId;
  final String platform;
  final String appVersion;
  Json toJson() => {
    'firebaseUid': firebaseUid,
    'deviceId': deviceId,
    'platform': platform,
    'appVersion': appVersion,
  };
}

class KidDeviceRegistration {
  const KidDeviceRegistration({
    required this.id,
    required this.kidId,
    required this.deviceId,
    required this.approved,
    required this.revoked,
    required this.registeredAt,
    this.platform,
    this.appVersion,
    this.approvedAt,
    this.lastSeenAt,
  });
  final int id;
  final int kidId;
  final String deviceId;
  final String? platform;
  final String? appVersion;
  final bool approved;
  final bool revoked;
  final DateTime registeredAt;
  final DateTime? approvedAt;
  final DateTime? lastSeenAt;

  factory KidDeviceRegistration.fromJson(Json json) => KidDeviceRegistration(
    id: integer(json['id']),
    kidId: integer(json['kidId']),
    deviceId: json['deviceId']?.toString() ?? '',
    platform: json['platform']?.toString(),
    appVersion: json['appVersion']?.toString(),
    approved: json['approved'] == true,
    revoked: json['revoked'] == true,
    registeredAt: utcDate(json['registeredAt']),
    approvedAt: utcDateOrNull(json['approvedAt']),
    lastSeenAt: utcDateOrNull(json['lastSeenAt']),
  );
}

class CreateKidCommand {
  const CreateKidCommand({required this.name, this.birthDate, this.photoUrl});
  final String name;
  final DateTime? birthDate;
  final String? photoUrl;
  Json toJson() => {
    'name': name,
    'birthDate': birthDate?.toUtc().toIso8601String(),
    'photoUrl': photoUrl,
  };
}

class CreateKidAccountCommand {
  const CreateKidAccountCommand({
    required this.username,
    required this.pin,
    this.firebaseUid,
  });
  final String username;
  final String pin;
  final String? firebaseUid;
  Json toJson() => {
    'username': username,
    'pin': pin,
    'firebaseUid': firebaseUid,
  };
}

class ChildSpendingLimitCommand {
  const ChildSpendingLimitCommand({
    this.dailyLimit,
    this.weeklyLimit,
    this.monthlyLimit,
    required this.currency,
  });
  final double? dailyLimit;
  final double? weeklyLimit;
  final double? monthlyLimit;
  final String currency;
  Json toJson() => {
    'dailyLimit': dailyLimit,
    'weeklyLimit': weeklyLimit,
    'monthlyLimit': monthlyLimit,
    'currency': currency,
  };
}

class KidSpendingScheduleCommand {
  const KidSpendingScheduleCommand({
    this.timezone = 'America/Bogota',
    required this.scheduleJson,
    required this.isActive,
  });
  final String timezone;
  final String scheduleJson;
  final bool isActive;
  Json toJson() => {
    'timezone': timezone,
    'scheduleJson': scheduleJson,
    'isActive': isActive,
  };
}

class KidCategoriesCommand {
  const KidCategoriesCommand(this.categoryIds);
  final List<int> categoryIds;
  Json toJson() => {'categoryIds': categoryIds};
}

class KidGeofenceCommand {
  const KidGeofenceCommand({
    required this.name,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.radiusMeters,
  });
  final String name;
  final double centerLatitude;
  final double centerLongitude;
  final double radiusMeters;
  Json toJson() => {
    'name': name,
    'centerLatitude': centerLatitude,
    'centerLongitude': centerLongitude,
    'radiusMeters': radiusMeters,
  };
}

class KidRuleMerchantCommand {
  const KidRuleMerchantCommand(this.merchantId);
  final int merchantId;
  Json toJson() => {'merchantId': merchantId};
}

class KidRuleCountriesCommand {
  const KidRuleCountriesCommand(this.countryCodes);
  final List<String> countryCodes;
  Json toJson() => {'countryCodes': countryCodes};
}

class KidRuleCountryCommand {
  const KidRuleCountryCommand(this.countryCode);
  final String countryCode;
  Json toJson() => {'countryCode': countryCode.toUpperCase()};
}

class KidRuleItem {
  const KidRuleItem({
    required this.id,
    required this.label,
    this.code,
    this.isActive = true,
  });
  final int id;
  final String label;
  final String? code;
  final bool isActive;

  factory KidRuleItem.fromJson(Json json) {
    final id = integer(
      json['merchantId'] ??
          json['businessId'] ??
          json['categoryId'] ??
          json['id'],
    );
    return KidRuleItem(
      id: id,
      label:
          json['merchantName']?.toString() ??
          json['businessName']?.toString() ??
          json['categoryName']?.toString() ??
          json['name']?.toString() ??
          (id == 0 ? 'Sin nombre' : 'Elemento $id'),
      code: json['code']?.toString() ?? json['countryCode']?.toString(),
      isActive: json['isActive'] != false,
    );
  }
}

class KidRuleCountry {
  const KidRuleCountry({required this.code, required this.name});
  final String code;
  final String name;

  factory KidRuleCountry.fromJson(Json json) {
    final code =
        json['countryCode']?.toString() ?? json['code']?.toString() ?? '';
    return KidRuleCountry(
      code: code.toUpperCase(),
      name:
          json['countryName']?.toString() ??
          json['name']?.toString() ??
          code.toUpperCase(),
    );
  }
}

class KidSpendingLimits {
  const KidSpendingLimits({
    this.dailyLimit,
    this.weeklyLimit,
    this.monthlyLimit,
    required this.currency,
  });
  final double? dailyLimit;
  final double? weeklyLimit;
  final double? monthlyLimit;
  final String currency;

  factory KidSpendingLimits.fromJson(Json json) => KidSpendingLimits(
    dailyLimit: _optionalNumber(json['dailyLimit']),
    weeklyLimit: _optionalNumber(json['weeklyLimit']),
    monthlyLimit: _optionalNumber(json['monthlyLimit']),
    currency: json['currency']?.toString() ?? 'COP',
  );
}

class KidSpendingSchedule {
  const KidSpendingSchedule({
    required this.timezone,
    required this.scheduleJson,
    required this.isActive,
  });
  final String timezone;
  final String scheduleJson;
  final bool isActive;

  factory KidSpendingSchedule.fromJson(Json json) => KidSpendingSchedule(
    timezone: json['timezone']?.toString() ?? 'America/Bogota',
    scheduleJson:
        json['scheduleJson']?.toString() ?? json['schedule']?.toString() ?? '',
    isActive: json['isActive'] != false,
  );
}

class KidGeofence {
  const KidGeofence({
    required this.id,
    required this.name,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.radiusMeters,
    this.isActive = true,
  });
  final int id;
  final String name;
  final double centerLatitude;
  final double centerLongitude;
  final double radiusMeters;
  final bool isActive;

  factory KidGeofence.fromJson(Json json) => KidGeofence(
    id: integer(json['geofenceId'] ?? json['id']),
    name: json['name']?.toString() ?? 'Geocerca',
    centerLatitude: number(json['centerLatitude'] ?? json['latitude']),
    centerLongitude: number(json['centerLongitude'] ?? json['longitude']),
    radiusMeters: number(json['radiusMeters'] ?? json['radius']),
    isActive: json['isActive'] != false,
  );
}

class KidRulesSnapshot {
  const KidRulesSnapshot({
    required this.merchants,
    required this.categories,
    required this.limits,
    required this.schedules,
    required this.geofences,
    required this.countries,
    required this.blockedMerchants,
  });
  final List<KidRuleItem> merchants;
  final List<KidRuleItem> categories;
  final KidSpendingLimits limits;
  final List<KidSpendingSchedule> schedules;
  final List<KidGeofence> geofences;
  final List<KidRuleCountry> countries;
  final List<KidRuleItem> blockedMerchants;
}

class KidLocationCommand {
  const KidLocationCommand({
    required this.latitude,
    required this.longitude,
    this.label,
    this.paymentSessionId,
  });
  final double latitude;
  final double longitude;
  final String? label;
  final String? paymentSessionId;
  Json toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    if (label != null && label!.trim().isNotEmpty) 'label': label!.trim(),
    if (paymentSessionId != null) 'paymentSessionId': paymentSessionId,
  };
}

class KidLocation {
  const KidLocation({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.label,
    this.paymentSessionId,
  });
  final double latitude;
  final double longitude;
  final DateTime recordedAt;
  final String? label;
  final String? paymentSessionId;

  factory KidLocation.fromJson(Json json) => KidLocation(
    latitude: number(json['latitude']),
    longitude: number(json['longitude']),
    recordedAt: utcDate(
      json['recordedAt'] ?? json['createdAt'] ?? json['timestamp'],
    ),
    label: json['label']?.toString(),
    paymentSessionId: json['paymentSessionId']?.toString(),
  );
}

class SecondaryAdminCommand {
  const SecondaryAdminCommand(this.secondaryUserId);
  final int secondaryUserId;
  Json toJson() => {'secondaryUserId': secondaryUserId};
}

class KidsSecurityActionCommand {
  const KidsSecurityActionCommand({required this.kidId, this.reason});
  final int kidId;
  final String? reason;
  Json toJson() => {'kidId': kidId, 'reason': reason};
}

class SecurityAttempt {
  const SecurityAttempt({
    required this.id,
    required this.kidId,
    required this.attemptType,
    required this.restrictive,
    required this.createdAt,
    this.resourceId,
    this.reasonCode,
  });
  final int id;
  final int kidId;
  final String attemptType;
  final String? resourceId;
  final bool restrictive;
  final String? reasonCode;
  final DateTime createdAt;
  factory SecurityAttempt.fromJson(Json json) => SecurityAttempt(
    id: integer(json['id']),
    kidId: integer(json['kidId']),
    attemptType: json['attemptType']?.toString() ?? '',
    resourceId: json['resourceId']?.toString(),
    restrictive: json['restrictive'] == true,
    reasonCode: json['reasonCode']?.toString(),
    createdAt: utcDate(json['createdAt']),
  );
}

class MasterDashboard {
  const MasterDashboard({
    required this.availableBalance,
    required this.currency,
    required this.pendingRequests,
    required this.approvedRequests,
    required this.rejectedRequests,
    required this.paymentAttempts,
    required this.restrictiveAttempts,
    required this.blockedAccounts,
    required this.frequentBusinesses,
    required this.authorizedLocations,
    required this.alerts,
    required this.spendByCategory,
    required this.generatedAt,
    this.averageApprovalMinutes,
  });
  final double availableBalance;
  final String currency;
  final int pendingRequests;
  final int approvedRequests;
  final int rejectedRequests;
  final int paymentAttempts;
  final int restrictiveAttempts;
  final int blockedAccounts;
  final double? averageApprovalMinutes;
  final List<Json> frequentBusinesses;
  final List<Json> authorizedLocations;
  final List<Json> alerts;
  final List<Json> spendByCategory;
  final DateTime generatedAt;

  factory MasterDashboard.fromJson(Json json) => MasterDashboard(
    availableBalance: number(json['availableBalance']),
    currency: json['currency']?.toString() ?? '',
    pendingRequests: integer(json['pendingRequests']),
    approvedRequests: integer(json['approvedRequests']),
    rejectedRequests: integer(json['rejectedRequests']),
    paymentAttempts: integer(json['paymentAttempts']),
    restrictiveAttempts: integer(json['restrictiveAttempts']),
    blockedAccounts: integer(json['blockedAccounts']),
    averageApprovalMinutes: (json['averageApprovalMinutes'] as num?)
        ?.toDouble(),
    frequentBusinesses: jsonMaps(json['frequentBusinesses']),
    authorizedLocations: jsonMaps(json['authorizedLocations']),
    alerts: jsonMaps(json['alerts']),
    spendByCategory: jsonMaps(json['spendByCategory']),
    generatedAt: utcDate(json['generatedAt']),
  );
}

class KidAuditEntry {
  const KidAuditEntry({
    required this.id,
    required this.kidId,
    required this.action,
    required this.createdAt,
    this.actorUserId,
    this.detail,
    this.correlationId,
  });
  final int id;
  final int kidId;
  final int? actorUserId;
  final String action;
  final String? detail;
  final String? correlationId;
  final DateTime createdAt;
  factory KidAuditEntry.fromJson(Json json) => KidAuditEntry(
    id: integer(json['id']),
    kidId: integer(json['kidId']),
    actorUserId: (json['actorUserId'] as num?)?.toInt(),
    action: json['action']?.toString() ?? json['eventType']?.toString() ?? '',
    detail: json['detail']?.toString() ?? json['description']?.toString(),
    correlationId: json['correlationId']?.toString(),
    createdAt: utcDate(json['createdAt']),
  );
}

class KidAuditPage {
  const KidAuditPage({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.items,
  });
  final int page;
  final int pageSize;
  final int total;
  final List<KidAuditEntry> items;
  factory KidAuditPage.fromJson(Json json) => KidAuditPage(
    page: integer(json['page']),
    pageSize: integer(json['pageSize']),
    total: integer(json['total']),
    items: jsonMaps(
      json['items'],
    ).map(KidAuditEntry.fromJson).toList(growable: false),
  );
}

class AuditExport {
  const AuditExport({
    required this.bytes,
    required this.fileName,
    this.contentType = 'text/csv',
  });
  final List<int> bytes;
  final String fileName;
  final String contentType;
}

double? _optionalNumber(Object? value) => value is num
    ? value.toDouble()
    : value == null
    ? null
    : double.tryParse(value.toString());
