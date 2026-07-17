import '../contacts/contacts_matcher.dart';
import '../utils/display_labels.dart';
import 'app_exception.dart';

abstract final class UserErrorMessage {
  static bool isPlanLimitError(Object error) {
    if (error is! AppException) return false;
    final code = error.code?.toUpperCase();
    final message = error.message.toUpperCase();
    return code == 'PLAN_LIMIT_REACHED' ||
        message.contains('PLAN_LIMIT_REACHED');
  }

  static String from(Object error) {
    if (error is AppContactsPermissionException) {
      return error.toString();
    }
    if (error is! AppException) {
      final raw = error.toString();
      if (raw.contains('Provider') && raw.contains('not found')) {
        return 'No pudimos completar la acción. Cierra y vuelve a abrir la pantalla.';
      }
      if (raw.contains('Null check operator')) {
        return 'Ocurrió un error inesperado. Intenta nuevamente.';
      }
      return 'Ocurrió un error inesperado.';
    }

    final statusCode = error.statusCode;
    final code = error.code?.toUpperCase();
    final message = error.message.toLowerCase();
    final sanitized = DisplayLabels.sanitizeBackendMessage(error.message);

    if (isPlanLimitError(error)) {
      return 'Tu plan actual no incluye esta función. Mejora tu membresía.';
    }

    final codeMessage = switch (code) {
      'FILE_TOO_LARGE' => 'La imagen supera el tamaño permitido.',
      'INVALID_FILE_TYPE' => 'Formato de imagen no permitido.',
      'USER_NOT_PARTICIPANT' => 'No tienes acceso a esta conversación.',
      'INSUFFICIENT_BALANCE' =>
        'Saldo insuficiente. Recarga tu wallet con Mercado Pago o transferencia.',
      'NO_WALLET' =>
        'No tienes una wallet activa. Créala o recárgala para pagar tu viaje.',
      'CURRENCY_MISMATCH' =>
        'La moneda de tu wallet no coincide con la del viaje.',
      'PAYMENT_ERROR' =>
        'No pudimos procesar el pago del viaje. Intenta nuevamente.',
      'CONCURRENCY' =>
        'La oferta cambió mientras respondías. Actualiza e intenta de nuevo.',
      'TERMS_NOT_ACCEPTED' =>
        'Debes aceptar los términos de la promoción para continuar.',
      'ALREADY_PREMIUM' => 'Ya tienes un plan premium activo.',
      'PROMOTION_SLOTS_EXHAUSTED' =>
        'La promoción ya no tiene cupos disponibles.',
      'IDEMPOTENCY_CONFLICT' =>
        'No pudimos activar la promoción. Intenta nuevamente.',
      'FRONT_DOCUMENT_MEDIA_REQUIRED' =>
        'La foto del frente del documento es obligatoria.',
      _ => null,
    };
    if (codeMessage != null) return codeMessage;

    // Recuperación de contraseña OTP (mensajes del backend Ciervo).
    final recoveryMessage = _passwordRecoveryMessage(message);
    if (recoveryMessage != null) return recoveryMessage;

    final upperMsg = error.message.toUpperCase();
    if (upperMsg.contains('FRONT_DOCUMENT_MEDIA_REQUIRED')) {
      return 'La foto del frente del documento es obligatoria.';
    }
    if (upperMsg.contains('FILE_TOO_LARGE')) {
      return 'La imagen supera el tamaño permitido.';
    }
    if (upperMsg.contains('INVALID_FILE_TYPE')) {
      return 'Formato de imagen no permitido.';
    }

    if (statusCode == 401) {
      return 'Credenciales inválidas o sesión expirada.';
    }
    if (statusCode == 429) {
      return 'Demasiados intentos. Espera unos segundos e intenta de nuevo.';
    }
    if (statusCode == 403 &&
        (message.contains('limite') ||
            message.contains('límite') ||
            message.contains('plan_limit'))) {
      return 'Tu plan actual no incluye esta función. Mejora tu membresía.';
    }
    if (statusCode == 403 || code?.contains('blocked') == true) {
      if (error.message.isNotEmpty &&
          !error.message.toLowerCase().contains('permiso')) {
        return error.message;
      }
      return 'No tienes permiso o no estas relacionado con este recurso.';
    }
    if (statusCode == 404) {
      return 'Esta función estará disponible cuando el servidor se actualice.';
    }
    if (statusCode == 400) {
      if (message.contains('subscribe-intents')) {
        return 'Este plan requiere pago con Mercado Pago.';
      }
      if (message.contains('cotizacion') || message.contains('cotización')) {
        return 'Este plan requiere cotizacion comercial.';
      }
      if (message.contains('insufficient') ||
          message.contains('saldo insuficiente')) {
        return 'Saldo insuficiente. Recarga tu wallet con Mercado Pago o transferencia.';
      }
      if (message.contains('amount') && message.contains('membership')) {
        return 'No envies monto para membresias. El backend calcula el cobro.';
      }
      if (message.contains('plan no encontrado') ||
          message.contains('plan not found')) {
        return 'Plan no encontrado.';
      }
      return sanitized;
    }
    if (message.contains('network') || message.contains('conexion')) {
      return 'No pudimos conectar con el servidor. Revisa tu conexión.';
    }
    if (message.contains('could not be converted') ||
        message.contains('system.text.json') ||
        message.contains('json path') ||
        message.contains('validation errors') ||
        message.contains('field is required')) {
      return sanitized;
    }

    return sanitized;
  }

  /// Mensajes del flujo de recuperación de contraseña OTP.
  /// Devuelve texto amigable o null si no aplica.
  static String? _passwordRecoveryMessage(String lowerMessage) {
    final message = lowerMessage;
    if (message.contains('proveedor de correo') ||
        message.contains('correo no configurado') ||
        message.contains('email provider') ||
        message.contains('mail provider')) {
      return 'El servidor aún no tiene configurado el envío de correos. '
          'Intenta más tarde o contacta soporte.';
    }
    if (message.contains('debes esperar antes de solicitar')) {
      return 'Espera unos segundos antes de pedir otro código.';
    }
    if (message.contains('codigo no encontrado') ||
        message.contains('código no encontrado')) {
      return 'No encontramos un código activo. Solicita uno nuevo.';
    }
    if (message.contains('codigo invalido') ||
        message.contains('código inválido')) {
      return 'Código incorrecto. Revisa e inténtalo de nuevo.';
    }
    if (message.contains('codigo expirado') ||
        message.contains('código expirado')) {
      return 'El código expiró. Solicita uno nuevo.';
    }
    if (message.contains('codigo bloqueado') ||
        message.contains('código bloqueado')) {
      return 'Demasiados intentos. Espera unos minutos o solicita un código nuevo.';
    }
    if (message.contains('usuario no encontrado')) {
      return 'No encontramos esa cuenta. Vuelve a solicitar el código.';
    }
    return null;
  }
}
