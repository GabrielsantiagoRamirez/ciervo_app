import 'dart:typed_data';

import 'package:ciervo_clud/core/network/correlation_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('adds a valid correlation id and preserves the server id', () async {
    final adapter = _RecordingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    dio.interceptors.add(CorrelationInterceptor());

    final response = await dio.get<dynamic>('/resource');
    final sentId =
        adapter.lastOptions!.headers[CorrelationInterceptor.headerName]
            as String;

    expect(
      sentId,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-'
          r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(
      response.extra[CorrelationInterceptor.extraKey],
      'server-correlation-id',
    );
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        CorrelationInterceptor.headerName: ['server-correlation-id'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
