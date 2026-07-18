import 'dart:typed_data';

import 'package:ciervo_clud/core/errors/app_exception.dart';
import 'package:ciervo_clud/core/network/api_envelope_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects HTTP 200 when the API envelope reports failure', () async {
    final dio = Dio()..httpClientAdapter = _FailureEnvelopeAdapter();
    dio.interceptors.add(ApiEnvelopeInterceptor());

    await expectLater(
      dio.post<void>('/mutation'),
      throwsA(
        isA<DioException>().having(
          (error) => error.error,
          'typed envelope error',
          isA<AppException>().having(
            (error) => error.code,
            'error code',
            'RULE_REJECTED',
          ),
        ),
      ),
    );
  });
}

class _FailureEnvelopeAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"status":false,"value":null,"msg":"Operación rechazada",'
      '"errorCode":"RULE_REJECTED"}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
