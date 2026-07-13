import 'package:firebase_auth/firebase_auth.dart';

abstract final class FirebaseAuthErrors {
  static String userMessage(Object error) {
    if (error is! FirebaseAuthException) {
      return 'No pudimos completar la autenticación.';
    }
    return switch (error.code) {
      'operation-not-allowed' =>
        'La verificación por teléfono no está disponible en este momento. '
            'Prueba ingresar con tu correo electrónico.',
      'invalid-verification-code' =>
        'Código inválido o vencido. Solicita uno nuevo.',
      'session-expired' => 'Código inválido o vencido. Solicita uno nuevo.',
      'too-many-requests' =>
        'Demasiados intentos. Espera unos minutos e intenta de nuevo.',
      'credential-already-in-use' =>
        'Este número ya está registrado. Iniciaremos sesión con tu código de verificación.',
      'provider-already-linked' =>
        'Este número ya está registrado. Iniciaremos sesión con tu código de verificación.',
      'account-exists-with-different-credential' =>
        'Este número ya está registrado. Iniciaremos sesión con tu código de verificación.',
      'invalid-email' => 'El correo electrónico no es válido.',
      'email-already-in-use' => 'Ese correo ya está registrado.',
      'wrong-password' => 'Contraseña incorrecta.',
      'invalid-credential' =>
        'Correo o contraseña incorrectos. Si tu cuenta es antigua, usa la contraseña de Ciervo Club.',
      'user-not-found' => 'No encontramos una cuenta con esos datos.',
      'missing-email' => 'Ingresa un correo electrónico.',
      'no-user' => 'No pudimos verificar tu sesión. Intenta nuevamente.',
      'no-token' => 'No pudimos verificar tu sesión. Intenta nuevamente.',
      'network-request-failed' =>
        'No hay conexión. Revisa tu internet e intenta de nuevo.',
      _ => _sanitize(error.message),
    };
  }

  static String _sanitize(String? message) {
    final text = message?.trim() ?? '';
    if (text.isEmpty) return 'No pudimos completar la autenticación.';
    if (text.contains('sign-in provider is disabled')) {
      return 'Este método de acceso no está habilitado. Usa tu correo electrónico.';
    }
    if (text.toLowerCase().contains('blocked all requests')) {
      return 'Firebase bloqueó temporalmente los SMS por muchos intentos. '
          'Usa el tab Correo o espera unos minutos.';
    }
    if (text.toLowerCase().contains('play integrity') ||
        text.toLowerCase().contains('valid app identifier') ||
        text.toLowerCase().contains('recaptcha checks were unsuccessful')) {
      return 'No pudimos verificar la app en este dispositivo (Play Integrity). '
          'Revisa en Firebase/Google Cloud: SHA-1 y SHA-256 del keystore con el que '
          'instalaste la app, Play Integrity API habilitada, y teléfono de prueba en '
          'Firebase Auth si estás en desarrollo.';
    }
    return text;
  }
}
