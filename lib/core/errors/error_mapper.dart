import 'package:dio/dio.dart';

import '../network/api_models.dart';
import 'app_exception.dart';

abstract final class ErrorMapper {
  static AppException fromObject(Object error) {
    if (error is AppException) {
      return error;
    }

    if (error is DioException) {
      return fromDio(error);
    }

    return AppException(
      message: 'Ocurrio un error inesperado.',
      code: 'unexpected_error',
      cause: error,
    );
  }

  static AppException fromDio(DioException error) {
    final interceptorError = error.error;
    if (interceptorError is AppException) {
      return AppException(
        message: interceptorError.message,
        code: interceptorError.code,
        statusCode: error.response?.statusCode ?? interceptorError.statusCode,
        correlationId: interceptorError.correlationId,
        fieldErrors: interceptorError.fieldErrors,
        cause: error,
      );
    }

    final response = error.response;
    final data = response?.data;
    final map = data is Map
        ? Map<String, dynamic>.from(data)
        : const <String, dynamic>{};
    final problem = ProblemDetailsModel.fromJson(map);
    final backendMessage = map.isNotEmpty
        ? problem.safeMessage ??
              map['message']?.toString() ??
              map['msg']?.toString() ??
              map['error']?.toString()
        : null;
    final correlationId =
        _nonEmptyString(map['correlationId']) ??
        _nonEmptyString(response?.headers.value('x-correlation-id'));

    return AppException(
      message: backendMessage ?? _fallbackMessage(error),
      code:
          _nonEmptyString(map['errorCode']) ??
          _nonEmptyString(map['code']) ??
          _codeFromMsg(map['msg']),
      statusCode: response?.statusCode,
      correlationId: correlationId,
      fieldErrors: problem.errors,
      cause: error,
    );
  }

  /// Cuando el backend pone el código en `msg` (ej. PHYSICAL_NFC_ALREADY_REGISTERED).
  static String? _codeFromMsg(Object? msg) {
    final text = msg?.toString().trim();
    if (text == null || text.isEmpty) return null;
    if (RegExp(r'^[A-Z][A-Z0-9_]+$').hasMatch(text)) return text;
    return null;
  }

  static String? _nonEmptyString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static String _fallbackMessage(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'La conexion tardo demasiado. Intenta nuevamente.',
      DioExceptionType.badResponse => 'No pudimos completar la solicitud.',
      DioExceptionType.cancel => 'La solicitud fue cancelada.',
      DioExceptionType.connectionError =>
        'No hay conexion disponible con el servidor.',
      DioExceptionType.badCertificate =>
        'No se pudo validar la conexion segura.',
      DioExceptionType.unknown => 'Ocurrio un error de conexion.',
    };
  }
}
