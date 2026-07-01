class AccountLookupResult {
  const AccountLookupResult({
    required this.exists,
    this.userId,
    this.authProvider,
    required this.suggestedFlow,
    this.phoneAvailable,
    this.emailAvailable,
    this.emailVerified,
    this.phoneVerified,
    this.hasFirebaseUid = false,
    this.requiresFirebaseLink = false,
  });

  factory AccountLookupResult.fromJson(Map<String, dynamic> json) {
    return AccountLookupResult(
      exists: json['exists'] == true,
      userId: _optionalInt(json['userId']),
      authProvider: json['authProvider']?.toString(),
      suggestedFlow: json['suggestedFlow']?.toString() ?? 'register',
      phoneAvailable: _nullableBool(json['phoneAvailable']),
      emailAvailable: _nullableBool(json['emailAvailable']),
      emailVerified: _nullableBool(json['emailVerified']),
      phoneVerified: _nullableBool(json['phoneVerified']),
      hasFirebaseUid: json['hasFirebaseUid'] == true,
      requiresFirebaseLink: json['requiresFirebaseLink'] == true,
    );
  }

  final bool exists;
  final int? userId;
  final String? authProvider;
  final String suggestedFlow;
  final bool? phoneAvailable;
  final bool? emailAvailable;
  final bool? emailVerified;
  final bool? phoneVerified;
  final bool hasFirebaseUid;
  final bool requiresFirebaseLink;

  bool get isLegacyLogin => suggestedFlow == 'legacy_password';
  bool get isFirebaseLogin =>
      suggestedFlow == 'firebase_password' ||
      suggestedFlow == 'firebase_phone' ||
      suggestedFlow == 'firebase_login';
  bool get isRegister => !exists && suggestedFlow == 'register';

  bool get shouldOfferEmailVerification =>
      exists && emailVerified != true;

  bool get isPhoneTaken => phoneAvailable == false;

  bool get isPhoneFree => phoneAvailable == true;

  bool get shouldLinkLegacy => exists && requiresFirebaseLink;
}

int? _optionalInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse('$value');
}

bool? _nullableBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  final text = value.toString().toLowerCase();
  if (text == 'true') return true;
  if (text == 'false') return false;
  return null;
}
