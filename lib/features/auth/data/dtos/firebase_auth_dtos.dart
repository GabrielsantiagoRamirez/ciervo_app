class FirebaseCheckUserResult {
  const FirebaseCheckUserResult({
    required this.exists,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.countryCode,
    this.phone,
    this.email,
  });

  factory FirebaseCheckUserResult.fromJson(Map<String, dynamic> json) {
    return FirebaseCheckUserResult(
      exists: json['exists'] == true || json['userExists'] == true,
      emailVerified: json['emailVerified'] == true,
      phoneVerified: json['phoneVerified'] == true,
      countryCode: json['countryCode']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
    );
  }

  final bool exists;
  final bool emailVerified;
  final bool phoneVerified;
  final String? countryCode;
  final String? phone;
  final String? email;
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
