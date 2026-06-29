import 'package:dio/dio.dart';

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
    final response = error.response;
    final data = response?.data;
    final backendMessage = data is Map<String, dynamic>
        ? data['message']?.toString() ??
            data['msg']?.toString() ??
            data['error']?.toString()
        : null;

    return AppException(
      message: backendMessage ?? _fallbackMessage(error),
      code: data is Map<String, dynamic> ? data['code']?.toString() : null,
      statusCode: response?.statusCode,
      cause: error,
    );
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
