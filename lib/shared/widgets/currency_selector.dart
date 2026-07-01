import 'package:flutter/material.dart';

import '../../core/country/country_registration.dart';
import '../../core/di/service_locator.dart';
import '../../features/exchange/data/exchange_rate_repository.dart';

/// Monedas admitidas — cargadas desde `/api/catalogs/currencies`.
class CurrencySelector extends StatefulWidget {
  const CurrencySelector({
    required this.value,
    required this.onChanged,
    this.countryCode,
    super.key,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String? countryCode;

  @override
  State<CurrencySelector> createState() => _CurrencySelectorState();
}

class _CurrencySelectorState extends State<CurrencySelector> {
  List<String> _currencies = const ['COP', 'CLP', 'USD'];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    final result = await getIt<ExchangeRateRepository>().getCurrencies();
    if (!mounted) return;
    result.when(
      success: (catalog) {
        final codes = catalog.currencyCodes;
        setState(() {
          _loading = false;
          if (codes.isNotEmpty) _currencies = codes;
        });
      },
      failure: (_) => setState(() => _loading = false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final suggested = defaultCurrencyForCountry(widget.countryCode);
    final selected =
        _currencies.contains(widget.value) ? widget.value : suggested;

    return DropdownButtonFormField<String>(
      value: selected,
      decoration: InputDecoration(
        labelText: _loading ? 'Moneda (cargando…)' : 'Moneda',
        prefixIcon: const Icon(Icons.payments_outlined),
      ),
      items: _currencies
          .map(
            (code) => DropdownMenuItem(
              value: code,
              child: Text(_label(code)),
            ),
          )
          .toList(),
      onChanged: _loading
          ? null
          : (selectedCode) {
              if (selectedCode != null) widget.onChanged(selectedCode);
            },
    );
  }

  static String _label(String code) => switch (code) {
        'COP' => 'Peso colombiano (COP)',
        'CLP' => 'Peso chileno (CLP)',
        'USD' => 'Dólar (USD)',
        _ => code,
      };
}

String defaultCurrencyForCountry(String? countryCode) =>
    CountryRegistration.currencyForCountry(countryCode ?? 'CO');

/// Alias legacy para imports existentes.
const kSupportedCurrencies = ['COP', 'CLP', 'USD'];
