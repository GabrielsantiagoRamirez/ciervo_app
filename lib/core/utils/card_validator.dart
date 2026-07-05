/// Validaciones locales de tarjeta antes de tokenizar con Mercado Pago.
abstract final class CardValidator {
  static bool isLuhnValid(String cardNumber) {
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 13 || digits.length > 19) return false;
    var sum = 0;
    var alternate = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var n = int.parse(digits[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  static String? validateCardNumber(String cardNumber) {
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 13) {
      return 'Ingresa un número de tarjeta válido.';
    }
    if (!isLuhnValid(digits)) {
      return 'El número de tarjeta no es válido.';
    }
    return null;
  }

  static String? validateCvv(String cvv) {
    final digits = cvv.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 3 || digits.length > 4) {
      return 'El CVV debe tener 3 o 4 dígitos.';
    }
    return null;
  }

  static String? validateHolderName(String name) {
    if (name.trim().length < 3) {
      return 'Ingresa el nombre del titular como aparece en la tarjeta.';
    }
    return null;
  }
}
