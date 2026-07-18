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
    final map = data is Map
        ? Map<String, dynamic>.from(data)
        : const <String, dynamic>{};
    final backendMessage = map.isNotEmpty
        ? map['detail']?.toString() ??
              map['message']?.toString() ??
              map['msg']?.toString() ??
              map['error']?.toString() ??
              map['title']?.toString()
        : null;
    final correlationId =
        _nonEmptyString(map['correlationId']) ??
        _nonEmptyString(response?.headers.value('x-correlation-id'));

    return AppException(
      message: backendMessage ?? _fallbackMessage(error),
      code: _nonEmptyString(map['errorCode']) ?? _nonEmptyString(map['code']),
      statusCode: response?.statusCode,
      correlationId: correlationId,
      fieldErrors: _fieldErrors(map['errors']),
      cause: error,
    );
  }

  static String? _nonEmptyString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static Map<String, List<String>> _fieldErrors(Object? raw) {
    if (raw is! Map) return const <String, List<String>>{};

    return Map<String, List<String>>.unmodifiable(
      raw.map((key, value) {
        final messages = value is Iterable
            ? value
                  .map((item) => item.toString().trim())
                  .where((item) => item.isNotEmpty)
                  .toList(growable: false)
            : <String>[
                if (value != null && value.toString().trim().isNotEmpty)
                  value.toString().trim(),
              ];
        return MapEntry(key.toString(), messages);
      }),
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
