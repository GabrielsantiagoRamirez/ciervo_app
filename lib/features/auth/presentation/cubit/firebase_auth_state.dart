enum FirebaseAuthStatus {
  initial,
  loading,
  codeSent,
  phoneVerified,
  success,
  failure,
}

class FirebaseAuthState {
  const FirebaseAuthState({
    this.status = FirebaseAuthStatus.initial,
    this.errorMessage,
    this.verificationId,
    this.resendToken,
    this.phoneE164,
    this.phoneNational,
    this.countryCode = 'CO',
    this.latitude,
    this.longitude,
    this.city,
    this.userExists = false,
    this.requiresFirebaseLink = false,
    this.authAction,
    this.linkedLegacy = false,
  });

  final FirebaseAuthStatus status;
  final String? errorMessage;
  final String? verificationId;
  final int? resendToken;
  final String? phoneE164;
  final String? phoneNational;
  final String countryCode;
  final double? latitude;
  final double? longitude;
  final String? city;
  final bool userExists;
  final bool requiresFirebaseLink;
  final String? authAction;
  final bool linkedLegacy;

  bool get isLoading => status == FirebaseAuthStatus.loading;

  bool get shouldFirebaseLogin => userExists || requiresFirebaseLink;

  FirebaseAuthState copyWith({
    FirebaseAuthStatus? status,
    String? errorMessage,
    bool clearError = false,
    String? verificationId,
    int? resendToken,
    String? phoneE164,
    String? phoneNational,
    String? countryCode,
    double? latitude,
    double? longitude,
    String? city,
    bool? userExists,
    bool? requiresFirebaseLink,
    String? authAction,
    bool? linkedLegacy,
    bool clearAuthMeta = false,
  }) {
    return FirebaseAuthState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      verificationId: verificationId ?? this.verificationId,
      resendToken: resendToken ?? this.resendToken,
      phoneE164: phoneE164 ?? this.phoneE164,
      phoneNational: phoneNational ?? this.phoneNational,
      countryCode: countryCode ?? this.countryCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      userExists: userExists ?? this.userExists,
      requiresFirebaseLink: requiresFirebaseLink ?? this.requiresFirebaseLink,
      authAction: clearAuthMeta ? null : (authAction ?? this.authAction),
      linkedLegacy: clearAuthMeta ? false : (linkedLegacy ?? this.linkedLegacy),
    );
  }
}
