enum CardBrand {
  visa,
  mastercard,
  unknown;

  String get label => switch (this) {
        CardBrand.visa => 'Visa',
        CardBrand.mastercard => 'Mastercard',
        CardBrand.unknown => '',
      };
}

abstract final class CardBrandDetector {
  static CardBrand detect(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return CardBrand.unknown;

    if (digits.startsWith('4')) return CardBrand.visa;

    if (digits.length >= 2) {
      final prefix2 = int.tryParse(digits.substring(0, 2));
      if (prefix2 != null && prefix2 >= 51 && prefix2 <= 55) {
        return CardBrand.mastercard;
      }
    }

    if (digits.length >= 4) {
      final prefix4 = int.tryParse(digits.substring(0, 4));
      if (prefix4 != null && prefix4 >= 2221 && prefix4 <= 2720) {
        return CardBrand.mastercard;
      }
    }

    return CardBrand.unknown;
  }

  static CardBrand fromBrandString(String? brand) {
    final normalized = brand?.toLowerCase() ?? '';
    if (normalized.contains('visa')) return CardBrand.visa;
    if (normalized.contains('master')) return CardBrand.mastercard;
    return CardBrand.unknown;
  }
}
