import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../config/app_environment.dart';
import '../logging/app_logger.dart';
import '../session/session_manager.dart';
import 'auth_interceptor.dart';
import 'auth_token_refresher.dart';

class NetworkClient {
  NetworkClient({
    required AppConfig config,
    required SessionManager sessionManager,
    required AuthTokenRefresher tokenRefresher,
    required AppLogger logger,
  }) : dio = Dio(
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
    dio.interceptors.add(
      AuthInterceptor(
        sessionManager: sessionManager,
        tokenRefresher: tokenRefresher,
        dio: dio,
      ),
    );
    if (config.environment.enablesVerboseLogs) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (object) => logger.info(object.toString()),
        ),
      );
    }
  }

  final Dio dio;
}
