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
      'invalid-verification-code' => 'El código SMS no es válido. Revisa e intenta de nuevo.',
      'session-expired' => 'El código SMS expiró. Solicita uno nuevo.',
      'too-many-requests' =>
        'Demasiados intentos. Espera unos minutos e intenta de nuevo.',
      'invalid-email' => 'El correo electrónico no es válido.',
      'email-already-in-use' => 'Ese correo ya está registrado.',
      'wrong-password' => 'Contraseña incorrecta.',
      'user-not-found' => 'No encontramos una cuenta con esos datos.',
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
    return text;
  }
}
