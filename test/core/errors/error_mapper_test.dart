import 'package:ciervo_clud/core/errors/error_mapper.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps validation problem details and correlation id', () {
    final request = RequestOptions(path: '/api/payments');
    final error = DioException(
      requestOptions: request,
      response: Response<dynamic>(
        requestOptions: request,
        statusCode: 400,
        data: {
          'title': 'Solicitud inválida',
          'detail': 'Revisa los datos enviados.',
          'correlationId': 'problem-123',
          'errors': {
            'Amount': ['Debe ser mayor que cero'],
          },
        },
      ),
      type: DioExceptionType.badResponse,
    );

    final mapped = ErrorMapper.fromDio(error);

    expect(mapped.message, 'Revisa los datos enviados.');
    expect(mapped.statusCode, 400);
    expect(mapped.correlationId, 'problem-123');
    expect(mapped.fieldErrors['Amount'], ['Debe ser mayor que cero']);
  });

  for (final status in [400, 401, 403, 404, 409, 410, 422, 429, 500]) {
    test('preserves HTTP $status and safe backend metadata', () {
      final request = RequestOptions(path: '/api/v1/resource');
      final mapped = ErrorMapper.fromDio(
        DioException(
          requestOptions: request,
          response: Response<dynamic>(
            requestOptions: request,
            statusCode: status,
            headers: Headers.fromMap({
              'x-correlation-id': ['http-$status'],
            }),
            data: {
              'status': status,
              'detail': 'Mensaje seguro $status',
              'errorCode': 'HTTP_$status',
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(mapped.statusCode, status);
      expect(mapped.message, 'Mensaje seguro $status');
      expect(mapped.code, 'HTTP_$status');
      expect(mapped.correlationId, 'http-$status');
    });
  }

  test('maps offline failures without exposing transport internals', () {
    final mapped = ErrorMapper.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/api/v1/resource'),
        type: DioExceptionType.connectionError,
        message: 'SocketException: secret-host.internal',
      ),
    );

    expect(mapped.statusCode, isNull);
    expect(mapped.message, 'No hay conexion disponible con el servidor.');
    expect(mapped.message, isNot(contains('secret-host')));
  });
}
