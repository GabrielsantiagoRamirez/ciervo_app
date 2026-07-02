import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/card_brand_detector.dart';
import 'card_brand_logo.dart';

class CardNumberField extends StatefulWidget {
  const CardNumberField({
    required this.controller,
    this.labelText = 'Número de tarjeta',
    super.key,
  });

  final TextEditingController controller;
  final String labelText;

  @override
  State<CardNumberField> createState() => _CardNumberFieldState();
}

class _CardNumberFieldState extends State<CardNumberField> {
  CardBrand _brand = CardBrand.unknown;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncBrand);
    _syncBrand();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncBrand);
    super.dispose();
  }

  void _syncBrand() {
    final next = CardBrandDetector.detect(widget.controller.text);
    if (next != _brand && mounted) {
      setState(() => _brand = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            LengthLimitingTextInputFormatter(19),
            _CardNumberGroupingFormatter(),
          ],
          decoration: InputDecoration(
            labelText: widget.labelText,
            prefixIcon: const Icon(Icons.credit_card),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CardBrandLogo(brand: _brand),
            ),
            suffixIconConstraints: const BoxConstraints(minWidth: 56, minHeight: 32),
          ),
        ),
        if (_brand != CardBrand.unknown) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              CardBrandLogo(brand: _brand, height: 24),
              const SizedBox(width: 8),
              Text(
                'Tarjeta ${_brand.label} detectada',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CardNumberGroupingFormatter extends TextInputFormatter {
  const _CardNumberGroupingFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
