import '../utils/display_labels.dart';
import 'app_exception.dart';

abstract final class UserErrorMessage {
  static String from(Object error) {
    if (error is! AppException) {
      return 'Ocurrió un error inesperado.';
    }

    final statusCode = error.statusCode;
    final code = error.code?.toUpperCase();
    final message = error.message.toLowerCase();
    final sanitized = DisplayLabels.sanitizeBackendMessage(error.message);

    final codeMessage = switch (code) {
      'FILE_TOO_LARGE' => 'La imagen supera el tamaño permitido.',
      'INVALID_FILE_TYPE' => 'Formato de imagen no permitido.',
      'USER_NOT_PARTICIPANT' => 'No tienes acceso a esta conversación.',
      'INSUFFICIENT_BALANCE' =>
        'Saldo insuficiente. Recarga tu wallet con Mercado Pago o transferencia.',
      _ => null,
    };
    if (codeMessage != null) return codeMessage;

    if (statusCode == 401) {
      return 'Credenciales inválidas o sesión expirada.';
    }
    if (statusCode == 429) {
      return 'Demasiados intentos. Espera unos segundos e intenta de nuevo.';
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
      if (message.contains('insufficient') || message.contains('saldo insuficiente')) {
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
    if (statusCode == 403 &&
        (message.contains('limite') ||
            message.contains('límite') ||
            message.contains('plan_limit'))) {
      return error.message.isNotEmpty
          ? error.message
          : 'Limite de plan alcanzado.';
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
}
