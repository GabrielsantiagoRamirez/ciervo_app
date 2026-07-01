/// Códigos telefónicos E.164 para Chile y Colombia.
abstract final class PhoneCountry {
  static const cl = PhoneCountryOption(
    countryCode: 'CL',
    dialCode: '+56',
    label: 'Chile',
    flag: '🇨🇱',
  );

  static const co = PhoneCountryOption(
    countryCode: 'CO',
    dialCode: '+57',
    label: 'Colombia',
    flag: '🇨🇴',
  );

  static const options = [cl, co];

  static PhoneCountryOption byCountryCode(String code) {
    return options.firstWhere(
      (item) => item.countryCode == code.toUpperCase(),
      orElse: () => co,
    );
  }

  static String toE164({
    required String countryCode,
    required String nationalNumber,
  }) {
    final digits = nationalNumber.replaceAll(RegExp(r'\D'), '');
    final dial = byCountryCode(countryCode).dialCode;
    if (digits.startsWith('56') && countryCode == 'CL' && digits.length > 9) {
      return '+$digits';
    }
    if (digits.startsWith('57') && countryCode == 'CO' && digits.length > 10) {
      return '+$digits';
    }
    return '$dial$digits';
  }

  /// Formato legible para UI: `+57 321 4291986`, `+56 9 12345678`.
  static String formatForDisplay(String e164) {
    final normalized = e164.trim();
    final digits = normalized.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return normalized;

    for (final option in options) {
      final dialDigits = option.dialCode.replaceAll('+', '');
      if (!digits.startsWith(dialDigits)) continue;
      final national = digits.substring(dialDigits.length);
      if (option.countryCode == 'CO' && national.length == 10) {
        return '${option.dialCode} ${national.substring(0, 3)} ${national.substring(3)}';
      }
      if (option.countryCode == 'CL' && national.length == 9) {
        return '${option.dialCode} ${national.substring(0, 1)} ${national.substring(1)}';
      }
      return '${option.dialCode} $national';
    }

    return normalized.startsWith('+') ? normalized : '+$digits';
  }
}

class PhoneCountryOption {
  const PhoneCountryOption({
    required this.countryCode,
    required this.dialCode,
    required this.label,
    required this.flag,
  });

  final String countryCode;
  final String dialCode;
  final String label;
  final String flag;
}
