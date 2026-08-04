import 'package:flutter/services.dart';

import '../utils/display_formatters.dart';

/// Formatea el input numérico con separador de miles (punto): `20000` → `20.000`.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  const ThousandsSeparatorInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    // Evitar overflow extremo en el campo.
    final clipped = digits.length > 12 ? digits.substring(0, 12) : digits;
    final value = int.tryParse(clipped) ?? 0;
    final formatted = DisplayFormatters.groupThousands(value);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
