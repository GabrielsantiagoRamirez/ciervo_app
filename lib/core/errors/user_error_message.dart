import 'app_exception.dart';

abstract final class UserErrorMessage {
  static String from(Object error) {
    if (error is! AppException) {
      return 'Ocurrio un error inesperado.';
    }

    final statusCode = error.statusCode;
    final code = error.code?.toLowerCase();
    final message = error.message.toLowerCase();

    if (statusCode == 401) {
      return 'Credenciales invalidas o sesion expirada.';
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
      return 'El recurso solicitado no existe.';
    }
    if (statusCode == 400) {
      if (message.contains('subscribe-intents')) {
        return 'Este plan requiere pago con Mercado Pago.';
      }
      if (message.contains('cotizacion') || message.contains('cotización')) {
        return 'Este plan requiere cotizacion comercial.';
      }
      if (message.contains('amount') && message.contains('membership')) {
        return 'No envies monto para membresias. El backend calcula el cobro.';
      }
      if (message.contains('plan no encontrado') ||
          message.contains('plan not found')) {
        return 'Plan no encontrado.';
      }
      return error.message.isNotEmpty
          ? error.message
          : 'Revisa los datos ingresados e intenta nuevamente.';
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
      return 'No pudimos conectar con el servidor. Revisa tu conexion.';
    }
    if (message.contains('could not be converted') ||
        message.contains('system.text.json') ||
        message.contains('json path') ||
        message.contains('validation errors')) {
      return 'Revisa los datos ingresados e intenta nuevamente.';
    }

    return error.message;
  }
}
