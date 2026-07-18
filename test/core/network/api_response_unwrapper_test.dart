import 'package:ciervo_clud/core/errors/app_exception.dart';
import 'package:ciervo_clud/core/network/api_response_unwrapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('unwrapApiResponse', () {
    test('returns value when status is true', () {
      final result = unwrapApiResponse({
        'status': true,
        'value': {'id': 1},
        'msg': null,
      });
      expect(result, {'id': 1});
    });

    test('throws AppException when status is false', () {
      expect(
        () => unwrapApiResponse({
          'status': false,
          'msg': 'Saldo insuficiente',
          'errorCode': 'insufficient_balance',
          'correlationId': 'request-123',
          'errors': {
            'Amount': ['Debe ser mayor que cero'],
          },
        }),
        throwsA(
          isA<AppException>()
              .having((e) => e.message, 'message', 'Saldo insuficiente')
              .having((e) => e.code, 'code', 'insufficient_balance')
              .having((e) => e.correlationId, 'correlationId', 'request-123')
              .having((e) => e.fieldErrors['Amount'], 'fieldErrors', [
                'Debe ser mayor que cero',
              ]),
        ),
      );
    });

    test('unwrapApiList reads items envelope', () {
      final list = unwrapApiList({
        'status': true,
        'value': {
          'items': [1, 2, 3],
        },
      });
      expect(list, [1, 2, 3]);
    });
  });
}
