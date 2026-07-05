import 'package:ciervo_clud/features/auth/presentation/cubit/firebase_login_attempts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirebaseLoginAttempts', () {
    test('prioriza token-only cuando el usuario ya existe', () {
      final attempts = FirebaseLoginAttempts.build(
        userKnownToExist: true,
        phoneE164: '+573214291986',
        phoneNational: '3214291986',
        countryCode: 'CO',
        checkUserPhone: '+573214291986',
        checkUserEmail: 'gabrielsantiao7151@gmail.com',
      );

      expect(attempts.first.phone, isNull);
      expect(attempts.first.email, isNull);
      expect(
        attempts.any((a) => a.phone == '+573214291986' && a.email == null),
        isTrue,
      );
      expect(
        attempts.any((a) => a.email == 'gabrielsantiao7151@gmail.com'),
        isTrue,
      );
    });

    test('sin usuario conocido no incluye intento token-only', () {
      final attempts = FirebaseLoginAttempts.build(
        userKnownToExist: false,
        phoneE164: '+573214291986',
        phoneNational: '3214291986',
        countryCode: 'CO',
      );

      expect(attempts.any((a) => a.phone == null && a.email == null), isFalse);
      expect(attempts.first.phone, '+573214291986');
    });

    test('no duplica intentos iguales', () {
      final attempts = FirebaseLoginAttempts.build(
        userKnownToExist: true,
        phoneE164: '+573214291986',
        phoneNational: '3214291986',
        countryCode: 'CO',
        checkUserPhone: '+573214291986',
        explicitEmail: 'gabrielsantiao7151@gmail.com',
        checkUserEmail: 'gabrielsantiao7151@gmail.com',
      );

      final keys = attempts
          .map((a) => '${a.phone ?? ''}|${a.email ?? ''}|${a.countryCode ?? ''}')
          .toList();
      expect(keys.length, keys.toSet().length);
    });
  });
}
