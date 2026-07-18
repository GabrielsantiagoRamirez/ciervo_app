import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

/// Reintenta fallos transitorios sin repetir mutaciones no idempotentes.
///
/// Las mutaciones solo son elegibles cuando su body contiene `idempotencyKey`
/// o el caller declara `extra['allowRetry'] == true`.
class RetryInterceptor extends Interceptor {
  RetryInterceptor(this._dio, {this.maxRetries = 2, Random? random})
    : _random = random ?? Random.secure();

  final Dio _dio;
  final int maxRetries;
  final Random _random;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final attempt = options.extra['retryAttempt'] as int? ?? 0;
    if (attempt >= maxRetries ||
        !RetryPolicy.isTransient(err) ||
        !RetryPolicy.isReplaySafe(options)) {
      handler.next(err);
      return;
    }

    options.extra['retryAttempt'] = attempt + 1;
    final baseMilliseconds = 300 * (1 << attempt);
    final jitterMilliseconds = _random.nextInt(151);
    await Future<void>.delayed(
      Duration(milliseconds: baseMilliseconds + jitterMilliseconds),
    );

    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    } catch (_) {
      handler.next(err);
    }
  }
}

abstract final class RetryPolicy {
  static bool isTransient(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return true;
    }
    final status = error.response?.statusCode;
    return status != null && status >= 500 && status <= 599;
  }

  static bool isReplaySafe(RequestOptions options) {
    final method = options.method.toUpperCase();
    if (method == 'GET' || method == 'HEAD' || method == 'OPTIONS') return true;
    if (options.extra['allowRetry'] == true) return true;

    final data = options.data;
    return data is Map &&
        data['idempotencyKey']?.toString().trim().isNotEmpty == true;
  }
}
