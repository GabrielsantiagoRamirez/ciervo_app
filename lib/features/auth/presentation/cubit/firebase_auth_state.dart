enum FirebaseAuthStatus {
  initial,
  loading,
  migrating,
  emailVerificationPending,
  codeSent,
  phoneVerified,
  success,
  failure,
}

/// Canal activo del flujo de registro/login para no mezclar errores SMS vs correo.
enum AuthSignupChannel { none, phone, email }

class FirebaseAuthState {
  const FirebaseAuthState({
    this.status = FirebaseAuthStatus.initial,
    this.channel = AuthSignupChannel.none,
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
    this.lookupExists = false,
    this.lookupRequiresLink = false,
    this.checkUserFirebaseUid,
    this.checkUserPhone,
    this.checkUserEmail,
  });

  final FirebaseAuthStatus status;
  final AuthSignupChannel channel;
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
  final bool lookupExists;
  final bool lookupRequiresLink;
  final String? checkUserFirebaseUid;
  final String? checkUserPhone;
  final String? checkUserEmail;

  bool get isLoading =>
      status == FirebaseAuthStatus.loading ||
      status == FirebaseAuthStatus.migrating;

  bool get isMigrating =>
      status == FirebaseAuthStatus.migrating || lookupRequiresLink;

  bool get shouldFirebaseLogin => userExists || requiresFirebaseLink;

  FirebaseAuthState copyWith({
    FirebaseAuthStatus? status,
    AuthSignupChannel? channel,
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
    bool? lookupExists,
    bool? lookupRequiresLink,
    bool clearLookup = false,
    String? checkUserFirebaseUid,
    String? checkUserPhone,
    String? checkUserEmail,
    bool clearCheckUser = false,
  }) {
    return FirebaseAuthState(
      status: status ?? this.status,
      channel: channel ?? this.channel,
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
      lookupExists: clearLookup ? false : (lookupExists ?? this.lookupExists),
      lookupRequiresLink: clearLookup
          ? false
          : (lookupRequiresLink ?? this.lookupRequiresLink),
      checkUserFirebaseUid: clearCheckUser
          ? null
          : (checkUserFirebaseUid ?? this.checkUserFirebaseUid),
      checkUserPhone: clearCheckUser
          ? null
          : (checkUserPhone ?? this.checkUserPhone),
      checkUserEmail: clearCheckUser
          ? null
          : (checkUserEmail ?? this.checkUserEmail),
    );
  }
}
