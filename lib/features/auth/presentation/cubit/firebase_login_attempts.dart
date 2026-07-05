/// Orden de payloads para POST /api/auth/firebase/login.
abstract final class FirebaseLoginAttempts {
  static List<({String? phone, String? email, String? countryCode})> build({
    required bool userKnownToExist,
    required String phoneE164,
    required String? phoneNational,
    required String countryCode,
    String? checkUserPhone,
    String? checkUserEmail,
    String? explicitEmail,
  }) {
    final seen = <String>{};
    final attempts = <({String? phone, String? email, String? countryCode})>[];

    void add(String? phone, String? email, String? countryCode) {
      final key = '${phone ?? ''}|${email ?? ''}|${countryCode ?? ''}';
      if (seen.add(key)) {
        attempts.add((phone: phone, email: email, countryCode: countryCode));
      }
    }

    if (userKnownToExist) {
      add(null, null, null);
    }

    if (phoneE164.isNotEmpty) {
      add(phoneE164, null, null);
    }

    final normalizedCheckPhone = checkUserPhone?.trim();
    if (normalizedCheckPhone != null && normalizedCheckPhone.isNotEmpty) {
      add(
        normalizedCheckPhone,
        null,
        normalizedCheckPhone.startsWith('+') ? null : countryCode,
      );
    }

    final national = phoneNational?.trim();
    if (national != null && national.isNotEmpty) {
      add(national, null, countryCode);
    }

    final email = explicitEmail?.trim();
    if (email != null && email.isNotEmpty) {
      add(null, email, null);
    }

    final checkEmail = checkUserEmail?.trim();
    if (checkEmail != null && checkEmail.isNotEmpty) {
      add(null, checkEmail, null);
    }

    return attempts;
  }
}
