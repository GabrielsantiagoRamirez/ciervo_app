import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';

abstract final class BonusErrorMessages {
  static String fromObject(Object error) =>
      from(ErrorMapper.fromObject(error));

  static String from(AppException error) {
    final code = (error.code ?? '').toLowerCase();
    final message = error.message.toLowerCase();

    if (code.contains('sold_out') ||
        message.contains('agotado') ||
        message.contains('sold out')) {
      return 'Este bono ya esta agotado.';
    }
    if (code.contains('expired') || message.contains('venc')) {
      return 'Este bono ya vencio.';
    }
    if (code.contains('already_claimed') ||
        message.contains('ya reclam') ||
        message.contains('already claimed')) {
      return 'Ya reclamaste este bono.';
    }
    if (error.statusCode == 401 ||
        code.contains('unauthorized') ||
        message.contains('no autenticado')) {
      return 'Inicia sesion para usar bonos.';
    }
    if (code.contains('forbidden') || error.statusCode == 403) {
      return 'No tienes permiso para esta accion.';
    }
    if (code.contains('insufficient') ||
        message.contains('saldo') ||
        message.contains('balance')) {
      return 'Saldo insuficiente para aplicar este bono.';
    }
    return error.message;
  }
}
