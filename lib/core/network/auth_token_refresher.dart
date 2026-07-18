import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_response_unwrapper.dart';
import '../session/auth_tokens.dart';
import '../session/session_manager.dart';
import 'correlation_interceptor.dart';

class AuthTokenRefresher {
  AuthTokenRefresher({
    required AppConfig config,
    required SessionManager sessionManager,
  }) : _config = config,
       _sessionManager = sessionManager,
       _dio = Dio(
         BaseOptions(
           baseUrl: config.apiBaseUrl,
           connectTimeout: config.connectTimeout,
           receiveTimeout: config.receiveTimeout,
           headers: const {
             'Accept': 'application/json',
             'Content-Type': 'application/json',
           },
         ),
       ) {
    _dio.interceptors.add(CorrelationInterceptor());
  }

  final AppConfig _config;
  final SessionManager _sessionManager;
  final Dio _dio;
  Future<String?>? _refreshInFlight;

  Future<String?> refreshAccessToken() {
    final activeRefresh = _refreshInFlight;
    if (activeRefresh != null) return activeRefresh;

    late final Future<String?> operation;
    operation = _performRefresh().whenComplete(() {
      if (identical(_refreshInFlight, operation)) {
        _refreshInFlight = null;
      }
    });
    _refreshInFlight = operation;
    return operation;
  }

  Future<String?> _performRefresh() async {
    final currentTokens = await _sessionManager.tokens();
    final refreshToken = currentTokens?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      await _sessionManager.clear();
      return null;
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        currentTokens?.refreshPath ?? _config.refreshTokenPath,
        data: {'refreshToken': refreshToken},
      );
      final source = unwrapApiMap(response.data);
      final accessToken =
          source['accessToken']?.toString() ?? source['token']?.toString();
      final nextRefreshToken =
          source['refreshToken']?.toString() ?? refreshToken;

      if (accessToken == null || accessToken.isEmpty) {
        await _sessionManager.clear();
        return null;
      }

      await _sessionManager.saveTokens(
        AuthTokens(
          accessToken: accessToken,
          refreshToken: nextRefreshToken,
          refreshPath: currentTokens?.refreshPath,
        ),
      );
      return accessToken;
    } catch (_) {
      await _sessionManager.clear();
      return null;
    }
  }
}
