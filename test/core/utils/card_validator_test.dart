import 'package:ciervo_clud/core/utils/card_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CardValidator', () {
    test('valida Luhn para Visa de prueba', () {
      expect(CardValidator.isLuhnValid('4111111111111111'), isTrue);
    });

    test('rechaza número inválido', () {
      expect(CardValidator.isLuhnValid('4111111111111112'), isFalse);
    });

    test('valida CVV', () {
      expect(CardValidator.validateCvv('123'), isNull);
      expect(CardValidator.validateCvv('12'), isNotNull);
    });
  });
}
