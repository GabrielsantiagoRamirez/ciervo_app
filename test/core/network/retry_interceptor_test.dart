import 'package:ciervo_clud/core/network/retry_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('considera transitorios timeout, desconexion y 5xx', () {
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
    final disconnected = DioException(
      requestOptions: request,
      type: DioExceptionType.connectionError,
    );
    final rateLimited = DioException(
      requestOptions: request,
      response: Response<void>(requestOptions: request, statusCode: 429),
      type: DioExceptionType.badResponse,
    );

    expect(RetryPolicy.isTransient(timeout), isTrue);
    expect(RetryPolicy.isTransient(disconnected), isTrue);
    expect(RetryPolicy.isTransient(serverError), isTrue);
    expect(RetryPolicy.isTransient(conflict), isFalse);
    expect(RetryPolicy.isTransient(rateLimited), isFalse);
  });

  test('solo repite mutaciones con Idempotency-Key header u opt-in', () {
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
          data: {'amount': 10, 'idempotencyKey': 'intent-en-body-no-es-valido'},
        ),
      ),
      isFalse,
    );
    final payload = {'amount': 10};
    final options = RequestOptions(
      path: '/x',
      method: 'PUT',
      data: payload,
      headers: {'idempotency-key': 'intent-123'},
    );
    expect(RetryPolicy.isReplaySafe(options), isTrue);
    expect(options.headers['idempotency-key'], 'intent-123');
    expect(identical(options.data, payload), isTrue);
    expect(
      RetryPolicy.isReplaySafe(
        RequestOptions(
          path: '/x',
          method: 'POST',
          headers: {'Idempotency-Key': '  '},
        ),
      ),
      isFalse,
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
