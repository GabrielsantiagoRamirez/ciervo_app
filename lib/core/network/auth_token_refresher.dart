import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../errors/error_mapper.dart';
import 'api_response_unwrapper.dart';
import '../session/auth_tokens.dart';
import '../session/session_manager.dart';

class AuthTokenRefresher {
  AuthTokenRefresher({
    required AppConfig config,
    required SessionManager sessionManager,
  })  : _config = config,
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
        );

  final AppConfig _config;
  final SessionManager _sessionManager;
  final Dio _dio;

  Future<String?> refreshAccessToken() async {
    final refreshToken = await _sessionManager.refreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _sessionManager.clear();
      return null;
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _config.refreshTokenPath,
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
        ),
      );
      return accessToken;
    } catch (error) {
      ErrorMapper.fromObject(error);
      await _sessionManager.clear();
      return null;
    }
  }
}
