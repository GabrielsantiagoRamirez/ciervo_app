import 'dart:ui' as ui;

import 'country_context.dart';

/// Utilidades de país para registro, pagos y tokenización Mercado Pago.
abstract final class CountryRegistration {
  /// Países con soporte de pagos / Mercado Pago en la app.
  static const paymentCountryCodes = ['CO', 'CL', 'MX', 'PE', 'AR'];

  static String defaultCountryCode() {
    final locale = ui.PlatformDispatcher.instance.locale;
    final code = locale.countryCode?.toUpperCase();
    if (code != null && paymentCountryCodes.contains(code)) return code;
    return 'CO';
  }

  /// Inferencia offline por coordenadas cuando el reverse-geocode falla.
  /// Evita sincronizar GPS real con un país por defecto incorrecto.
  static String? inferCountryCodeFromCoordinates({
    required double latitude,
    required double longitude,
  }) {
    // Chile continental aprox.
    if (latitude >= -56.0 &&
        latitude <= -17.0 &&
        longitude >= -76.0 &&
        longitude <= -66.0) {
      return 'CL';
    }
    // Colombia aprox.
    if (latitude >= -4.3 &&
        latitude <= 13.5 &&
        longitude >= -79.1 &&
        longitude <= -66.8) {
      return 'CO';
    }
    // México aprox.
    if (latitude >= 14.5 &&
        latitude <= 32.7 &&
        longitude >= -118.5 &&
        longitude <= -86.5) {
      return 'MX';
    }
    // Perú aprox.
    if (latitude >= -18.4 &&
        latitude <= -0.0 &&
        longitude >= -81.4 &&
        longitude <= -68.6) {
      return 'PE';
    }
    // Argentina aprox.
    if (latitude >= -55.1 &&
        latitude <= -21.7 &&
        longitude >= -73.6 &&
        longitude <= -53.6) {
      return 'AR';
    }
    return null;
  }

  static CountryContext defaultContext() =>
      contextForCode(defaultCountryCode());

  static CountryContext contextForCode(String countryCode) =>
      switch (countryCode.toUpperCase()) {
        'CL' => CountryContext.chile,
        'MX' => const CountryContext(
          countryCode: 'MX',
          city: 'Ciudad de Mexico',
        ),
        'PE' => const CountryContext(countryCode: 'PE', city: 'Lima'),
        'AR' => const CountryContext(countryCode: 'AR', city: 'Buenos Aires'),
        _ => CountryContext.colombia,
      };

  static String inferFromPhone(String phone) {
    final normalized = phone.trim().replaceAll(' ', '');
    if (normalized.startsWith('+56')) return 'CL';
    if (normalized.startsWith('+57')) return 'CO';
    if (normalized.startsWith('+52')) return 'MX';
    if (normalized.startsWith('+51')) return 'PE';
    if (normalized.startsWith('+54')) return 'AR';
    return defaultCountryCode();
  }

  /// Interpreta el país desde reverse-geocode (código ISO o nombre).
  static String? resolveCountryCodeFromGeo({String? country, String? city}) {
    final raw = (country ?? '').trim().toUpperCase();
    if (paymentCountryCodes.contains(raw)) return raw;
    if (raw == 'CHILE') return 'CL';
    if (raw == 'COLOMBIA') return 'CO';
    if (raw == 'MEXICO' || raw == 'MÉXICO') return 'MX';
    if (raw == 'PERU' || raw == 'PERÚ') return 'PE';
    if (raw == 'ARGENTINA') return 'AR';

    final lower = (country ?? '').trim().toLowerCase();
    if (lower.contains('chile')) return 'CL';
    if (lower.contains('colombia')) return 'CO';
    if (lower.contains('mexico') || lower.contains('méxico')) return 'MX';
    if (lower.contains('peru') || lower.contains('perú')) return 'PE';
    if (lower.contains('argentina')) return 'AR';

    final cityLower = (city ?? '').trim().toLowerCase();
    if (cityLower.contains('santiago') ||
        cityLower.contains('valparaíso') ||
        cityLower.contains('valparaiso') ||
        cityLower.contains('concepción') ||
        cityLower.contains('concepcion')) {
      return 'CL';
    }
    if (cityLower.contains('bogota') ||
        cityLower.contains('bogotá') ||
        cityLower.contains('medellin') ||
        cityLower.contains('medellín') ||
        cityLower.contains('cali')) {
      return 'CO';
    }
    if (cityLower.contains('ciudad de mexico') ||
        cityLower.contains('cdmx') ||
        cityLower.contains('guadalajara') ||
        cityLower.contains('monterrey')) {
      return 'MX';
    }
    if (cityLower.contains('lima') || cityLower.contains('arequipa')) {
      return 'PE';
    }
    if (cityLower.contains('buenos aires') ||
        cityLower.contains('cordoba') ||
        cityLower.contains('córdoba')) {
      return 'AR';
    }
    return null;
  }

  /// Moneda ISO a partir del país del usuario / cuenta.
  static String currencyForCountry(String countryCode) =>
      switch (countryCode.toUpperCase()) {
        'CL' => 'CLP',
        'MX' => 'MXN',
        'PE' => 'PEN',
        'AR' => 'ARS',
        'CO' => 'COP',
        _ => 'COP',
      };

  /// País a partir de la moneda de Mercado Pago / wallet.
  static String? countryCodeFromCurrency(String? currency) {
    final code = (currency ?? '').trim().toUpperCase();
    return switch (code) {
      'CLP' => 'CL',
      'MXN' => 'MX',
      'PEN' => 'PE',
      'ARS' => 'AR',
      'COP' => 'CO',
      _ => null,
    };
  }

  /// Tipo de documento por defecto para tokenización Mercado Pago.
  static String mercadoPagoIdentificationType(String countryCode) =>
      switch (countryCode.toUpperCase()) {
        'CL' => 'RUT',
        'MX' => 'CURP',
        'PE' => 'DNI',
        'AR' => 'DNI',
        _ => 'CC',
      };

  static String countryLabel(String countryCode) =>
      switch (countryCode.toUpperCase()) {
        'CL' => 'Chile',
        'CO' => 'Colombia',
        'MX' => 'México',
        'PE' => 'Perú',
        'AR' => 'Argentina',
        _ => countryCode,
      };

  static String documentHelperText(String countryCode) => switch (countryCode
      .toUpperCase()) {
    'CL' =>
      'Usa el RUT de tu tarjeta (p. ej. Cuenta RUT Visa) para tokenizar en Mercado Pago Chile.',
    'MX' => 'Usa CURP o RFC del titular según tu cuenta Mercado Pago México.',
    'PE' => 'Usa el DNI del titular para Mercado Pago Perú.',
    'AR' => 'Usa DNI o CUIL del titular para Mercado Pago Argentina.',
    _ => 'Usa el documento del titular según tu país (Colombia: CC).',
  };

  static List<AdultDocumentOption> adultDocumentOptions(String countryCode) {
    return switch (countryCode.toUpperCase()) {
      'CL' => const [
        AdultDocumentOption('RUT', 'RUT'),
        AdultDocumentOption('RUN', 'RUN'),
        AdultDocumentOption('CE', 'Cédula extranjera'),
      ],
      'MX' => const [
        AdultDocumentOption('CURP', 'CURP'),
        AdultDocumentOption('RFC', 'RFC'),
      ],
      'PE' => const [
        AdultDocumentOption('DNI', 'DNI'),
        AdultDocumentOption('CE', 'Carné de extranjería'),
        AdultDocumentOption('RUC', 'RUC'),
      ],
      'AR' => const [
        AdultDocumentOption('DNI', 'DNI'),
        AdultDocumentOption('CUIL', 'CUIL'),
        AdultDocumentOption('CUIT', 'CUIT'),
      ],
      _ => const [
        AdultDocumentOption('CC', 'Cédula de ciudadanía'),
        AdultDocumentOption('CE', 'Cédula de extranjería'),
        AdultDocumentOption('NIT', 'NIT'),
        AdultDocumentOption('PP', 'Pasaporte'),
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
