import 'package:ciervo_clud/core/network/retry_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('solo considera transitorios timeout y 5xx', () {
    final request = RequestOptions(path: '/api/v1/resource');
    final timeout = DioException(
      requestOptions: request,
      type: DioExceptionType.receiveTimeout,
    );
    final serverError = DioException(
      requestOptions: request,
      response: Response<void>(requestOptions: request, statusCode: 503),
      type: DioExceptionType.badResponse,
    );
    final conflict = DioException(
      requestOptions: request,
      response: Response<void>(requestOptions: request, statusCode: 409),
      type: DioExceptionType.badResponse,
    );

    expect(RetryPolicy.isTransient(timeout), isTrue);
    expect(RetryPolicy.isTransient(serverError), isTrue);
    expect(RetryPolicy.isTransient(conflict), isFalse);
  });

  test('no repite mutaciones sin idempotencia u opt-in', () {
    expect(
      RetryPolicy.isReplaySafe(RequestOptions(path: '/x', method: 'GET')),
      isTrue,
    );
    expect(
      RetryPolicy.isReplaySafe(
        RequestOptions(path: '/x', method: 'POST', data: {'amount': 10}),
      ),
      isFalse,
    );
    expect(
      RetryPolicy.isReplaySafe(
        RequestOptions(
          path: '/x',
          method: 'POST',
          data: {'amount': 10, 'idempotencyKey': 'intent-123'},
        ),
      ),
      isTrue,
    );
    expect(
      RetryPolicy.isReplaySafe(
        RequestOptions(
          path: '/x',
          method: 'DELETE',
          extra: {'allowRetry': true},
        ),
      ),
      isTrue,
    );
  });
}
