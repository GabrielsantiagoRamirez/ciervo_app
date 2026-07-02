import 'package:ciervo_clud/features/family_payments/data/services/mercado_pago_card_tokenizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MercadoPagoCardExpiration.normalizeYear', () {
    test('convierte años de 2 dígitos a 4 dígitos', () {
      expect(MercadoPagoCardExpiration.normalizeYear(29), 2029);
      expect(MercadoPagoCardExpiration.normalizeYear(8), 2008);
    });

    test('conserva años de 4 dígitos', () {
      expect(MercadoPagoCardExpiration.normalizeYear(2029), 2029);
    });

    test('rechaza años inválidos', () {
      expect(
        () => MercadoPagoCardExpiration.normalizeYear(999),
        throwsA(isA<MercadoPagoTokenizationException>()),
      );
    });
  });

  group('MercadoPagoCardExpiration.parse', () {
    test('acepta mes y año en formato de tarjeta', () {
      final expiration = MercadoPagoCardExpiration.parse('09', '29');

      expect(expiration.month, 9);
      expect(expiration.year, 2029);
    });

    test('acepta mes y año en formato completo', () {
      final expiration = MercadoPagoCardExpiration.parse('12', '2028');

      expect(expiration.month, 12);
      expect(expiration.year, 2028);
    });

    test('rechaza meses fuera de rango', () {
      expect(
        () => MercadoPagoCardExpiration.parse('13', '29'),
        throwsA(isA<MercadoPagoTokenizationException>()),
      );
    });

    test('rechaza tarjetas vencidas', () {
      expect(
        () => MercadoPagoCardExpiration.parse('01', '20'),
        throwsA(isA<MercadoPagoTokenizationException>()),
      );
    });
  });
}
