/// Teléfono verificado en Firebase pero perfil Ciervo aún no creado en backend.
class AuthPendingRegistrationStore {
  String? phoneNational;
  String? phoneE164;
  String? countryCode;

  bool get hasPending =>
      phoneNational != null && phoneNational!.trim().isNotEmpty;

  void set({
    required String phoneNational,
    required String phoneE164,
    required String countryCode,
  }) {
    this.phoneNational = phoneNational;
    this.phoneE164 = phoneE164;
    this.countryCode = countryCode;
  }

  void clear() {
    phoneNational = null;
    phoneE164 = null;
    countryCode = null;
  }
}

/// Mensaje de arranque (p. ej. cuenta inactiva) para mostrar en login.
class AuthStartupMessageStore {
  String? message;

  bool get hasMessage => message != null && message!.trim().isNotEmpty;

  void set(String value) => message = value;

  String? consume() {
    final value = message;
    message = null;
    return value;
  }
}
