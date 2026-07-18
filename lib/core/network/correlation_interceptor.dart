import 'dart:math';

import 'package:dio/dio.dart';

class CorrelationInterceptor extends Interceptor {
  CorrelationInterceptor({Random? random})
    : _random = random ?? Random.secure();

  static const headerName = 'X-Correlation-ID';
  static const extraKey = 'correlationId';

  final Random _random;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final provided = options.headers[headerName]?.toString();
    final correlationId = _isValid(provided) ? provided! : _uuidV4();
    options.headers[headerName] = correlationId;
    options.extra[extraKey] = correlationId;
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    response.extra[extraKey] =
        response.headers.value(headerName) ??
        response.requestOptions.extra[extraKey];
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    err.response?.extra[extraKey] =
        err.response?.headers.value(headerName) ??
        err.requestOptions.extra[extraKey];
    handler.next(err);
  }

  bool _isValid(String? value) {
    return value != null && RegExp(r'^[A-Za-z0-9._:-]{1,64}$').hasMatch(value);
  }

  String _uuidV4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
