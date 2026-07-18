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
}
