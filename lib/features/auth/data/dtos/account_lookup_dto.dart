class AccountLookupResult {
  const AccountLookupResult({
    required this.exists,
    this.authProvider,
    required this.suggestedFlow,
    this.phoneAvailable,
    this.emailAvailable,
    this.emailVerified,
    this.phoneVerified,
  });

  factory AccountLookupResult.fromJson(Map<String, dynamic> json) {
    return AccountLookupResult(
      exists: json['exists'] == true,
      authProvider: json['authProvider']?.toString(),
      suggestedFlow: json['suggestedFlow']?.toString() ?? 'register',
      phoneAvailable: _nullableBool(json['phoneAvailable']),
      emailAvailable: _nullableBool(json['emailAvailable']),
      emailVerified: _nullableBool(json['emailVerified']),
      phoneVerified: _nullableBool(json['phoneVerified']),
    );
  }

  final bool exists;
  final String? authProvider;
  final String suggestedFlow;
  final bool? phoneAvailable;
  final bool? emailAvailable;
  final bool? emailVerified;
  final bool? phoneVerified;

  bool get isLegacyLogin => suggestedFlow == 'legacy_password';
  bool get isFirebaseLogin =>
      suggestedFlow == 'firebase_password' ||
      suggestedFlow == 'firebase_phone';
  bool get isRegister => !exists || suggestedFlow == 'register';

  /// Cuenta existente cuyo correo aún no está verificado (o estado desconocido).
  bool get shouldOfferEmailVerification =>
      exists && emailVerified != true;

  /// Teléfono ya registrado en otra cuenta.
  bool get isPhoneTaken => phoneAvailable == false;

  /// Teléfono libre para registro.
  bool get isPhoneFree => phoneAvailable == true;
}

bool? _nullableBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  final text = value.toString().toLowerCase();
  if (text == 'true') return true;
  if (text == 'false') return false;
  return null;
}
