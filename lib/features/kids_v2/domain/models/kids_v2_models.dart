import 'dart:convert';

typedef Json = Map<String, dynamic>;

Json jsonMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<Json> jsonMaps(Object? value) =>
    value is List ? value.map(jsonMap).toList(growable: false) : const <Json>[];

DateTime utcDate(Object? value) => DateTime.parse(value.toString()).toUtc();
DateTime? utcDateOrNull(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString())?.toUtc();
double number(Object? value) => (value as num?)?.toDouble() ?? 0;
int integer(Object? value) => (value as num?)?.toInt() ?? 0;

class ApiEnvelope<T> {
  const ApiEnvelope({
    required this.status,
    this.value,
    this.message,
    this.errorCode,
  });

  final bool status;
  final T? value;
  final String? message;
  final String? errorCode;

  factory ApiEnvelope.fromJson(Json json, T Function(Object?) decode) =>
      ApiEnvelope(
        status: json['status'] == true,
        value: json['value'] == null ? null : decode(json['value']),
        message: json['msg']?.toString(),
        errorCode: json['errorCode']?.toString(),
      );
}

class ProblemDetailsModel {
  const ProblemDetailsModel({
    this.type,
    this.title,
    this.status,
    this.detail,
    this.instance,
    this.correlationId,
    this.errors = const {},
  });

  final String? type;
  final String? title;
  final int? status;
  final String? detail;
  final String? instance;
  final String? correlationId;
  final Map<String, List<String>> errors;

  factory ProblemDetailsModel.fromJson(Json json) => ProblemDetailsModel(
    type: json['type']?.toString(),
    title: json['title']?.toString(),
    status: (json['status'] as num?)?.toInt(),
    detail: json['detail']?.toString(),
    instance: json['instance']?.toString(),
    correlationId: json['correlationId']?.toString(),
    errors: jsonMap(json['errors']).map(
      (key, value) => MapEntry(
        key,
        value is List
            ? value.map((item) => item.toString()).toList(growable: false)
            : <String>[value.toString()],
      ),
    ),
  );
}

sealed class KidLoginCommand {
  const KidLoginCommand({
    required this.deviceId,
    required this.platform,
    required this.appVersion,
  });

  final String deviceId;
  final String platform;
  final String appVersion;
  Json toJson();
}

class KidPinLoginCommand extends KidLoginCommand {
  const KidPinLoginCommand({
    required this.username,
    required this.pin,
    required super.deviceId,
    required super.platform,
    required super.appVersion,
  });

  final String username;
  final String pin;

  @override
  Json toJson() => {
    'username': username,
    'pin': pin,
    'firebaseIdToken': null,
    'deviceId': deviceId,
    'platform': platform,
    'appVersion': appVersion,
  };
}

class KidFirebaseLoginCommand extends KidLoginCommand {
  const KidFirebaseLoginCommand({
    required this.firebaseIdToken,
    required super.deviceId,
    required super.platform,
    required super.appVersion,
  });

  final String firebaseIdToken;

  @override
  Json toJson() => {
    'username': null,
    'pin': null,
    'firebaseIdToken': firebaseIdToken,
    'deviceId': deviceId,
    'platform': platform,
    'appVersion': appVersion,
  };
}

class KidRefreshCommand {
  const KidRefreshCommand({required this.refreshToken, required this.deviceId});
  final String refreshToken;
  final String deviceId;
  Json toJson() => {'refreshToken': refreshToken, 'deviceId': deviceId};
}

class KidUser {
  const KidUser({
    required this.userId,
    required this.kidId,
    required this.role,
    required this.accountKind,
    required this.name,
    required this.familyId,
    this.photoUrl,
  });

  final int userId;
  final int kidId;
  final int role;
  final String accountKind;
  final String name;
  final String? photoUrl;
  final int familyId;

  factory KidUser.fromJson(Json json) => KidUser(
    userId: integer(json['userId']),
    kidId: integer(json['kidId']),
    role: integer(json['role']),
    accountKind: json['accountKind']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    photoUrl: json['photoUrl']?.toString(),
    familyId: integer(json['familyId']),
  );
}

class KidSession {
  const KidSession({
    required this.accessToken,
    required this.expiresAt,
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
    required this.user,
  });

  final String accessToken;
  final DateTime expiresAt;
  final String refreshToken;
  final DateTime refreshTokenExpiresAt;
  final KidUser user;

  factory KidSession.fromJson(Json json) => KidSession(
    accessToken: json['token']?.toString() ?? '',
    expiresAt: utcDate(json['expiresAt']),
    refreshToken: json['refreshToken']?.toString() ?? '',
    refreshTokenExpiresAt: utcDate(json['refreshTokenExpiresAt']),
    user: KidUser.fromJson(jsonMap(json['user'])),
  );
}

class KidProfile {
  const KidProfile({
    required this.kidId,
    required this.userId,
    required this.name,
    this.photoUrl,
    this.familyId,
    this.username,
  });
  final int kidId;
  final int userId;
  final String name;
  final String? photoUrl;
  final int? familyId;
  final String? username;

  factory KidProfile.fromJson(Json json) => KidProfile(
    kidId: integer(json['kidId'] ?? json['id']),
    userId: integer(json['userId']),
    name: json['name']?.toString() ?? '',
    photoUrl: json['photoUrl']?.toString(),
    familyId: (json['familyId'] as num?)?.toInt(),
    username: json['username']?.toString(),
  );
}

class KidSettings {
  const KidSettings({
    required this.rawSchedule,
    required this.rawLimits,
    required this.categories,
    required this.geofences,
    required this.rawWallet,
  });
  final Json rawSchedule;
  final Json rawLimits;
  final List<Json> categories;
  final List<Json> geofences;
  final Json rawWallet;

  factory KidSettings.fromJson(Json json) => KidSettings(
    rawSchedule: jsonMap(json['schedule']),
    rawLimits: jsonMap(json['limits']),
    categories: jsonMaps(json['categories']),
    geofences: jsonMaps(json['geofences']),
    rawWallet: jsonMap(json['wallet']),
  );
}

class KidsCommerceItem {
  const KidsCommerceItem({
    required this.commerceId,
    required this.name,
    required this.acceptsCiervoPayments,
    required this.requiresReservation,
    this.city,
    this.categoryId,
    this.address,
  });
  final int commerceId;
  final String name;
  final String? city;
  final int? categoryId;
  final String? address;
  final bool acceptsCiervoPayments;
  final bool requiresReservation;

  factory KidsCommerceItem.fromJson(Json json) => KidsCommerceItem(
    commerceId: integer(json['commerceId']),
    name: json['name']?.toString() ?? '',
    city: json['city']?.toString(),
    categoryId: (json['categoryId'] as num?)?.toInt(),
    address: json['address']?.toString(),
    acceptsCiervoPayments: json['acceptsCiervoPayments'] == true,
    requiresReservation: json['requiresReservation'] == true,
  );
}

class CommerceQrReadRequest {
  const CommerceQrReadRequest(this.value);
  final String value;
  Json toJson() => {'value': value};
}

class CommerceIdValidateRequest {
  const CommerceIdValidateRequest(this.commerceId);
  final int commerceId;
  Json toJson() => {'commerceId': commerceId};
}

class ReservationPolicy {
  const ReservationPolicy({
    required this.commerceId,
    required this.version,
    required this.acceptanceRequired,
    required this.terms,
  });
  final int commerceId;
  final int version;
  final bool acceptanceRequired;
  final String terms;

  factory ReservationPolicy.fromJson(Json json) => ReservationPolicy(
    commerceId: integer(json['commerceId']),
    version: integer(json['version']),
    acceptanceRequired: json['acceptanceRequired'] == true,
    terms: json['terms']?.toString() ?? '',
  );
}

class KidsRulesValidateRequest {
  const KidsRulesValidateRequest(this.paymentSessionId);
  final String paymentSessionId;
  Json toJson() => {'paymentSessionId': paymentSessionId};
}

class ShieldDecision {
  const ShieldDecision({
    required this.allowed,
    required this.requiresApproval,
    this.ruleMatched,
    this.reason,
  });
  final bool allowed;
  final bool requiresApproval;
  final String? ruleMatched;
  final String? reason;

  factory ShieldDecision.fromJson(Json json) => ShieldDecision(
    allowed: json['allowed'] == true,
    requiresApproval: json['requiresApproval'] == true,
    ruleMatched: json['ruleMatched']?.toString(),
    reason: json['reason']?.toString(),
  );
}

class KidSecurityAttemptRequest {
  const KidSecurityAttemptRequest({
    this.attemptType = 'shield_rejection',
    this.resourceId,
    this.restrictive = true,
    this.reasonCode,
  });
  final String attemptType;
  final String? resourceId;
  final bool restrictive;
  final String? reasonCode;
  Json toJson() => {
    'attemptType': attemptType,
    if (resourceId != null) 'resourceId': resourceId,
    'restrictive': restrictive,
    if (reasonCode != null) 'reasonCode': reasonCode,
  };
}

class PayForMeCommand {
  const PayForMeCommand({
    this.payerUserId,
    this.payerCiervoUserCode,
    this.targetUserId,
    this.businessId,
    required this.amount,
    required this.currency,
    this.description,
    this.purpose = 'PayForMe',
    required this.idempotencyKey,
    this.chatConversationId,
    this.chatMessageId,
    this.bookingId,
    this.expiresAt,
  });
  final int? payerUserId;
  final String? payerCiervoUserCode;
  final int? targetUserId;
  final int? businessId;
  final double amount;
  final String currency;
  final String? description;
  final String purpose;
  final String idempotencyKey;
  final int? chatConversationId;
  final int? chatMessageId;
  final int? bookingId;
  final DateTime? expiresAt;

  Json toJson() => {
    'payerUserId': payerUserId,
    'payerCiervoUserCode': payerCiervoUserCode,
    'targetUserId': targetUserId,
    'businessId': businessId,
    'amount': amount,
    'currency': currency,
    'description': description,
    'purpose': purpose,
    'idempotencyKey': idempotencyKey,
    'chatConversationId': chatConversationId,
    'chatMessageId': chatMessageId,
    'bookingId': bookingId,
    'expiresAt': expiresAt?.toUtc().toIso8601String(),
  };
}

enum PaymentRequestStatus {
  pending(1),
  approved(2),
  rejected(3),
  expired(4),
  cancelled(5),
  paid(6),
  failed(7);

  const PaymentRequestStatus(this.value);
  final int value;
  static PaymentRequestStatus? parse(Object? value) {
    final number = (value as num?)?.toInt();
    for (final item in values) {
      if (item.value == number) return item;
    }
    return null;
  }
}

class PaymentRequest {
  const PaymentRequest({
    required this.id,
    required this.requesterUserId,
    required this.payerUserId,
    required this.amount,
    required this.currency,
    required this.purpose,
    required this.statusCode,
    required this.statusLabel,
    required this.idempotencyKey,
    required this.createdAt,
    this.targetUserId,
    this.businessId,
    this.description,
    this.requesterName,
    this.expiresAt,
    this.receipt,
    this.checkoutUrl,
  });
  final int id;
  final int requesterUserId;
  final int payerUserId;
  final int? targetUserId;
  final int? businessId;
  final double amount;
  final String currency;
  final String? description;
  final String purpose;
  final int statusCode;
  final String statusLabel;
  final String? requesterName;
  final String idempotencyKey;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final Json? receipt;
  final String? checkoutUrl;
  PaymentRequestStatus? get status => PaymentRequestStatus.parse(statusCode);

  factory PaymentRequest.fromJson(Json json) => PaymentRequest(
    id: integer(json['id']),
    requesterUserId: integer(json['requesterUserId']),
    payerUserId: integer(json['payerUserId']),
    targetUserId: (json['targetUserId'] as num?)?.toInt(),
    businessId: (json['businessId'] as num?)?.toInt(),
    amount: number(json['amount']),
    currency: json['currency']?.toString() ?? '',
    description: json['description']?.toString(),
    purpose: json['purpose']?.toString() ?? '',
    statusCode: integer(json['status']),
    statusLabel: json['statusLabel']?.toString() ?? '',
    requesterName:
        json['requesterName']?.toString() ??
        json['requesterDisplayName']?.toString(),
    idempotencyKey: json['idempotencyKey']?.toString() ?? '',
    createdAt: utcDate(json['createdAt']),
    expiresAt: utcDateOrNull(json['expiresAt']),
    receipt: json['receipt'] == null ? null : jsonMap(json['receipt']),
    checkoutUrl: json['checkoutUrl']?.toString(),
  );
}

class KidsQrScanRequest {
  const KidsQrScanRequest({
    required this.kidId,
    required this.deviceId,
    required this.merchantQr,
    required this.amount,
    this.latitude,
    this.longitude,
  });
  final int kidId;
  final String deviceId;
  final String merchantQr;
  final double amount;
  final double? latitude;
  final double? longitude;
  Json toJson() => {
    'kidId': kidId,
    'deviceId': deviceId,
    'merchantQr': merchantQr,
    'amount': amount,
    'latitude': latitude,
    'longitude': longitude,
  };
}

class KidsQrScanResponse {
  const KidsQrScanResponse({
    required this.paymentSessionId,
    required this.merchant,
    required this.amount,
    required this.currency,
    required this.approvalRequired,
    required this.status,
    this.ruleMatched,
    this.reason,
    this.approvalId,
  });
  final String paymentSessionId;
  final Json merchant;
  final double amount;
  final String currency;
  final bool approvalRequired;
  final int status;
  final String? ruleMatched;
  final String? reason;
  final int? approvalId;

  factory KidsQrScanResponse.fromJson(Json json) => KidsQrScanResponse(
    paymentSessionId: json['paymentSessionId']?.toString() ?? '',
    merchant: jsonMap(json['merchant']),
    amount: number(json['amount']),
    currency: json['currency']?.toString() ?? '',
    approvalRequired: json['approvalRequired'] == true,
    status: integer(json['status']),
    ruleMatched: json['ruleMatched']?.toString(),
    reason: json['reason']?.toString(),
    approvalId: (json['approvalId'] as num?)?.toInt(),
  );
}

class KidsQrConfirmRequest {
  const KidsQrConfirmRequest({
    required this.paymentSessionId,
    this.paymentMethod = 'CIERVO_BALANCE',
    this.pin,
    required this.idempotencyKey,
  });
  final String paymentSessionId;
  final String paymentMethod;
  final String? pin;
  final String idempotencyKey;
  Json toJson() => {
    'paymentSessionId': paymentSessionId,
    'paymentMethod': paymentMethod,
    'pin': pin,
    'idempotencyKey': idempotencyKey,
  };
}

class KidsQrConfirmResponse {
  const KidsQrConfirmResponse({
    required this.paymentSessionId,
    required this.status,
    this.childBusinessPaymentId,
    this.receipt,
  });
  final String paymentSessionId;
  final int status;
  final int? childBusinessPaymentId;
  final Json? receipt;

  factory KidsQrConfirmResponse.fromJson(Json json) => KidsQrConfirmResponse(
    paymentSessionId: json['paymentSessionId']?.toString() ?? '',
    status: integer(json['status']),
    childBusinessPaymentId: (json['childBusinessPaymentId'] as num?)?.toInt(),
    receipt: json['receipt'] == null ? null : jsonMap(json['receipt']),
  );
}

class KidsPaymentStatusSnapshot {
  const KidsPaymentStatusSnapshot({
    required this.paymentSessionId,
    required this.status,
    required this.statusLabel,
    required this.terminal,
    this.approved,
    this.reason,
  });

  final String paymentSessionId;
  final int status;
  final String statusLabel;
  final bool terminal;
  final bool? approved;
  final String? reason;

  bool get rejected {
    final normalized = statusLabel.toLowerCase();
    return approved == false ||
        status == 3 ||
        normalized.contains('reject') ||
        normalized.contains('rechaz');
  }

  factory KidsPaymentStatusSnapshot.fromJson(Json json) {
    final status = integer(
      json['status'] ?? json['paymentStatus'] ?? json['approvalStatus'],
    );
    final label =
        json['statusLabel']?.toString() ??
        json['state']?.toString() ??
        json['approvalStatusLabel']?.toString() ??
        '';
    final normalized = label.toLowerCase();
    final inferredTerminal =
        const {3, 4, 5, 6, 7}.contains(status) ||
        normalized.contains('approved') ||
        normalized.contains('aprob') ||
        normalized.contains('reject') ||
        normalized.contains('rechaz') ||
        normalized.contains('paid') ||
        normalized.contains('pagad') ||
        normalized.contains('failed') ||
        normalized.contains('fall') ||
        normalized.contains('expired') ||
        normalized.contains('expir') ||
        normalized.contains('cancel');
    return KidsPaymentStatusSnapshot(
      paymentSessionId: json['paymentSessionId']?.toString() ?? '',
      status: status,
      statusLabel: label.isEmpty ? 'Estado $status' : label,
      terminal: json['terminal'] == true || inferredTerminal,
      approved: json['approved'] is bool ? json['approved'] as bool : null,
      reason: json['reason']?.toString() ?? json['message']?.toString(),
    );
  }
}

class KidNfcStatus {
  const KidNfcStatus({required this.enabled, this.physicalCardId, this.status});
  final bool enabled;
  final String? physicalCardId;
  final String? status;

  factory KidNfcStatus.fromJson(Json json) => KidNfcStatus(
    enabled: json['enabled'] == true,
    physicalCardId: json['physicalCardId']?.toString(),
    status: json['status']?.toString(),
  );
}

class KidsRealtimeEvent {
  const KidsRealtimeEvent({
    required this.cursor,
    required this.type,
    required this.createdAt,
    this.payloadJson,
  });
  final int cursor;
  final String type;
  final String? payloadJson;
  final DateTime createdAt;

  Json? get payload {
    if (payloadJson == null) return null;
    try {
      return jsonMap(jsonDecode(payloadJson!));
    } on FormatException {
      return null;
    }
  }

  factory KidsRealtimeEvent.fromJson(Json json) => KidsRealtimeEvent(
    cursor: integer(json['cursor'] ?? json['id']),
    type: json['type']?.toString() ?? '',
    payloadJson: json['payloadJson']?.toString(),
    createdAt: utcDate(json['createdAt']),
  );
}

class KidsRealtimeEventPage {
  const KidsRealtimeEventPage({
    required this.nextCursor,
    required this.hasMore,
    required this.items,
  });
  final int nextCursor;
  final bool hasMore;
  final List<KidsRealtimeEvent> items;

  factory KidsRealtimeEventPage.fromJson(Json json) => KidsRealtimeEventPage(
    nextCursor: integer(json['nextCursor']),
    hasMore: json['hasMore'] == true,
    items: jsonMaps(
      json['items'],
    ).map(KidsRealtimeEvent.fromJson).toList(growable: false),
  );
}
