import 'package:dio/dio.dart';

import '../session/session_manager.dart';
import 'auth_token_refresher.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SessionManager sessionManager,
    required AuthTokenRefresher tokenRefresher,
    required Dio dio,
  })  : _sessionManager = sessionManager,
        _tokenRefresher = tokenRefresher,
        _dio = dio;

  final SessionManager _sessionManager;
  final AuthTokenRefresher _tokenRefresher;
  final Dio _dio;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isAuthEndpoint(options)) {
      options.headers.remove('Authorization');
      handler.next(options);
      return;
    }

    final token = await _sessionManager.accessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final alreadyRetried = err.requestOptions.extra['authRetried'] == true;

    if (statusCode != 401 || alreadyRetried) {
      handler.next(err);
      return;
    }

    final refreshedToken = await _tokenRefresher.refreshAccessToken();
    if (refreshedToken == null) {
      handler.next(err);
      return;
    }

    final requestOptions = err.requestOptions;
    requestOptions.extra['authRetried'] = true;
    requestOptions.headers['Authorization'] = 'Bearer $refreshedToken';

    try {
      final response = await _dio.fetch<dynamic>(requestOptions);
      handler.resolve(response);
    } catch (error) {
      handler.next(err);
    }
  }

  bool _isAuthEndpoint(RequestOptions options) {
    final path = options.path.toLowerCase();
    return options.extra['skipAuth'] == true || path.contains('/api/auth/');
  }
}
