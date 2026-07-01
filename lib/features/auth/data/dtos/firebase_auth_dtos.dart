class FirebaseCheckUserResult {
  const FirebaseCheckUserResult({
    required this.exists,
    this.userId,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.countryCode,
    this.phone,
    this.email,
    this.authProvider,
    this.hasFirebaseUid = false,
    this.requiresFirebaseLink = false,
    this.suggestedFlow = 'register',
  });

  factory FirebaseCheckUserResult.fromJson(Map<String, dynamic> json) {
    return FirebaseCheckUserResult(
      exists: json['exists'] == true || json['userExists'] == true,
      userId: json['userId'] is int
          ? json['userId'] as int
          : int.tryParse('${json['userId'] ?? ''}'),
      emailVerified: json['emailVerified'] == true,
      phoneVerified: json['phoneVerified'] == true,
      countryCode: json['countryCode']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      authProvider: json['authProvider']?.toString(),
      hasFirebaseUid: json['hasFirebaseUid'] == true,
      requiresFirebaseLink: json['requiresFirebaseLink'] == true,
      suggestedFlow: json['suggestedFlow']?.toString() ?? 'register',
    );
  }

  final bool exists;
  final int? userId;
  final bool emailVerified;
  final bool phoneVerified;
  final String? countryCode;
  final String? phone;
  final String? email;
  final String? authProvider;
  final bool hasFirebaseUid;
  final bool requiresFirebaseLink;
  final String suggestedFlow;

  bool get shouldUseFirebaseLogin => exists || requiresFirebaseLink;
}

class VerificationSyncResult {
  const VerificationSyncResult({
    required this.userId,
    required this.emailVerified,
    required this.phoneVerified,
    this.countryCode,
    this.phone,
    this.email,
    this.emailVerifiedAt,
    this.phoneVerifiedAt,
  });

  factory VerificationSyncResult.fromJson(Map<String, dynamic> json) {
    return VerificationSyncResult(
      userId: json['userId'] is int
          ? json['userId'] as int
          : int.tryParse('${json['userId'] ?? ''}') ?? 0,
      emailVerified: json['emailVerified'] == true,
      phoneVerified: json['phoneVerified'] == true,
      countryCode: json['countryCode']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      emailVerifiedAt: DateTime.tryParse('${json['emailVerifiedAt'] ?? ''}'),
      phoneVerifiedAt: DateTime.tryParse('${json['phoneVerifiedAt'] ?? ''}'),
    );
  }

  final int userId;
  final bool emailVerified;
  final bool phoneVerified;
  final String? countryCode;
  final String? phone;
  final String? email;
  final DateTime? emailVerifiedAt;
  final DateTime? phoneVerifiedAt;
}
