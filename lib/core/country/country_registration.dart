import 'dart:ui' as ui;

/// Utilidades de país para registro tutor/menor según contrato backend.
abstract final class CountryRegistration {
  static String defaultCountryCode() {
    final locale = ui.PlatformDispatcher.instance.locale;
    final code = locale.countryCode?.toUpperCase();
    if (code == 'CL' || code == 'CO') return code!;
    return 'CO';
  }

  static String inferFromPhone(String phone) {
    final normalized = phone.trim().replaceAll(' ', '');
    if (normalized.startsWith('+56')) return 'CL';
    if (normalized.startsWith('+57')) return 'CO';
    return defaultCountryCode();
  }

  static String currencyForCountry(String countryCode) =>
      countryCode.toUpperCase() == 'CL' ? 'CLP' : 'COP';

  static String countryLabel(String countryCode) => switch (countryCode) {
        'CL' => 'Chile',
        'CO' => 'Colombia',
        _ => countryCode,
      };

  static List<AdultDocumentOption> adultDocumentOptions(String countryCode) {
    return switch (countryCode) {
      'CL' => const [
        AdultDocumentOption('RUN', 'RUN'),
        AdultDocumentOption('RUT', 'RUT'),
        AdultDocumentOption('CE', 'Cédula extranjera'),
      ],
      _ => const [
        AdultDocumentOption('CC', 'Cédula de ciudadanía'),
        AdultDocumentOption('CE', 'Cédula de extranjería'),
        AdultDocumentOption('PASSPORT', 'Pasaporte'),
      ],
    };
  }

  static List<KidDocumentOption> kidDocumentOptions({
    required String countryCode,
    required int age,
  }) {
    if (countryCode == 'CL') {
      if (age < 18) {
        return const [
          KidDocumentOption('TI', 'Tarjeta de identidad'),
          KidDocumentOption('RUN', 'RUN'),
        ];
      }
      return const [
        KidDocumentOption('RUN', 'RUN'),
        KidDocumentOption('RUT', 'RUT'),
        KidDocumentOption('CE', 'Cédula extranjera'),
      ];
    }
    if (age < 18) {
      return const [
        KidDocumentOption('TI', 'Tarjeta de identidad'),
        KidDocumentOption('RC', 'Registro civil'),
      ];
    }
    return const [
      KidDocumentOption('CC', 'Cédula de ciudadanía'),
      KidDocumentOption('CE', 'Cédula de extranjería'),
    ];
  }

  static int? ageFromBirthDate(DateTime birthDate) {
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  static String? validateKidsAge(DateTime birthDate) {
    final age = ageFromBirthDate(birthDate);
    if (age == null) return 'Fecha de nacimiento inválida.';
    if (age < 10) return 'El perfil Kids solo acepta desde 10 años.';
    if (age > 25) return 'El perfil Kids solo acepta hasta 25 años.';
    return null;
  }
}

class AdultDocumentOption {
  const AdultDocumentOption(this.code, this.label);
  final String code;
  final String label;
}

class KidDocumentOption {
  const KidDocumentOption(this.code, this.label);
  final String code;
  final String label;
}
