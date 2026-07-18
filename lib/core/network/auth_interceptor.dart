import 'package:dio/dio.dart';

import '../session/session_manager.dart';
import 'auth_token_refresher.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SessionManager sessionManager,
    required AuthTokenRefresher tokenRefresher,
    required Dio dio,
  }) : _sessionManager = sessionManager,
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

    if (statusCode != 401 ||
        alreadyRetried ||
        _isAuthEndpoint(err.requestOptions)) {
      handler.next(err);
      return;
    }

    final failedToken = _bearerToken(
      err.requestOptions.headers['Authorization']?.toString(),
    );
    final currentToken = await _sessionManager.accessToken();
    final token =
        currentToken != null &&
            currentToken.isNotEmpty &&
            currentToken != failedToken
        ? currentToken
        : await _tokenRefresher.refreshAccessToken();
    if (token == null) {
      return handler.next(err);
    }

    final requestOptions = err.requestOptions;
    requestOptions.extra['authRetried'] = true;
    requestOptions.headers['Authorization'] = 'Bearer $token';

    try {
      final response = await _dio.fetch<dynamic>(requestOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    } catch (_) {
      handler.next(err);
    }
  }

  bool _isAuthEndpoint(RequestOptions options) {
    final path = options.path.toLowerCase();
    return options.extra['skipAuth'] == true ||
        path.contains('/api/auth/') ||
        path.contains('/api/v1/kids/auth/');
  }

  String? _bearerToken(String? authorization) {
    if (authorization == null ||
        !authorization.toLowerCase().startsWith('bearer ')) {
      return null;
    }
    return authorization.substring(7).trim();
  }
}
