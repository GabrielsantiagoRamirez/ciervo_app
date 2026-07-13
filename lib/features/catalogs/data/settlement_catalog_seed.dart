import '../../../core/country/country_registration.dart';
import '../domain/entities/settlement_catalog.dart';

/// Catálogos locales de liquidación cuando el backend aún no expone CO/CL.
abstract final class SettlementCatalogSeed {
  static const supportedCountryCodes = {'CO', 'CL'};

  static const countries = [
    SettlementCountry(code: 'CO', name: 'Colombia', currency: 'COP'),
    SettlementCountry(code: 'CL', name: 'Chile', currency: 'CLP'),
  ];

  static List<SettlementCountry> mergeCountries(List<SettlementCountry> api) {
    final byCode = {for (final country in countries) country.code: country};

    for (final country in api) {
      final code = country.code.toUpperCase();
      if (!supportedCountryCodes.contains(code)) continue;

      final seed = byCode[code];
      final name = _resolveCountryName(code, country.name);
      byCode[code] = SettlementCountry(
        code: code,
        name: name,
        currency: country.currency ?? seed?.currency,
      );
    }

    return byCode.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  static String _resolveCountryName(String code, String apiName) {
    final trimmed = apiName.trim();
    if (trimmed.isEmpty || trimmed == code) {
      return CountryRegistration.countryLabel(code);
    }
    if (trimmed.length <= 3 && trimmed.toUpperCase() == code) {
      return CountryRegistration.countryLabel(code);
    }
    return trimmed;
  }

  static List<BankOption> banksFor(String countryCode) {
    return switch (countryCode.toUpperCase()) {
      'CL' => const [
        BankOption(id: 'bancoestado', name: 'BancoEstado'),
        BankOption(id: 'banco_chile', name: 'Banco de Chile'),
        BankOption(id: 'santander_cl', name: 'Banco Santander'),
        BankOption(id: 'bci', name: 'BCI'),
        BankOption(id: 'scotiabank_cl', name: 'Scotiabank Chile'),
        BankOption(id: 'itau_cl', name: 'Itaú Chile'),
        BankOption(id: 'security', name: 'Banco Security'),
        BankOption(id: 'falabella', name: 'Banco Falabella'),
        BankOption(id: 'ripley', name: 'Banco Ripley'),
        BankOption(id: 'coopeuch', name: 'Coopeuch'),
      ],
      'CO' => const [
        BankOption(id: 'bancolombia', name: 'Bancolombia'),
        BankOption(id: 'davivienda', name: 'Davivienda'),
        BankOption(id: 'bbva_co', name: 'BBVA Colombia'),
        BankOption(id: 'bogota', name: 'Banco de Bogotá'),
        BankOption(id: 'occidente', name: 'Banco de Occidente'),
        BankOption(id: 'popular', name: 'Banco Popular'),
        BankOption(id: 'av_villas', name: 'AV Villas'),
        BankOption(id: 'colpatria', name: 'Scotiabank Colpatria'),
        BankOption(id: 'nequi', name: 'Nequi'),
        BankOption(id: 'daviplata', name: 'Daviplata'),
      ],
      _ => const [],
    };
  }

  static List<SettlementMethodOption> methodsFor(String countryCode) {
    return switch (countryCode.toUpperCase()) {
      'CL' => const [
        SettlementMethodOption(
          code: 'BANK_ACCOUNT',
          name: 'Cuenta bancaria',
          requiredFields: [
            'bankId',
            'accountType',
            'accountNumber',
            'holderName',
            'documentNumber',
          ],
        ),
        SettlementMethodOption(
          code: 'MERCADO_PAGO',
          name: 'Mercado Pago',
          requiredFields: ['phoneNumber', 'holderName', 'documentNumber'],
        ),
      ],
      'CO' => const [
        SettlementMethodOption(
          code: 'BANK_ACCOUNT',
          name: 'Cuenta bancaria',
          requiredFields: [
            'bankId',
            'accountType',
            'accountNumber',
            'holderName',
            'documentNumber',
          ],
        ),
        SettlementMethodOption(
          code: 'NEQUI',
          name: 'Nequi',
          requiredFields: ['phoneNumber', 'holderName', 'documentNumber'],
        ),
        SettlementMethodOption(
          code: 'DAVIPLATA',
          name: 'Daviplata',
          requiredFields: ['phoneNumber', 'holderName', 'documentNumber'],
        ),
        SettlementMethodOption(
          code: 'MERCADO_PAGO',
          name: 'Mercado Pago',
          requiredFields: ['phoneNumber', 'holderName', 'documentNumber'],
        ),
      ],
      _ => const [],
    };
  }

  static List<({String value, String label})> accountTypesFor(
    String countryCode,
  ) {
    return switch (countryCode.toUpperCase()) {
      'CL' => const [
        (value: 'Checking', label: 'Cuenta corriente'),
        (value: 'Savings', label: 'Cuenta de ahorro'),
        (value: 'Vista', label: 'Cuenta vista'),
        (value: 'Rut', label: 'Cuenta RUT'),
      ],
      _ => const [
        (value: 'Savings', label: 'Ahorros'),
        (value: 'Checking', label: 'Corriente'),
      ],
    };
  }
}
