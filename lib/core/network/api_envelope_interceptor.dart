import 'package:dio/dio.dart';

import 'api_response_unwrapper.dart';

class ApiEnvelopeInterceptor extends Interceptor {
  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final data = response.data;
    if (data is Map<String, dynamic> && data['status'] == false) {
      try {
        unwrapApiResponse(data);
      } catch (error) {
        handler.reject(
          DioException(
            requestOptions: response.requestOptions,
            response: response,
            error: error,
            type: DioExceptionType.badResponse,
            message: data['msg']?.toString(),
          ),
        );
        return;
      }
    }
    handler.next(response);
  }
}
