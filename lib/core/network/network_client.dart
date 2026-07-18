import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../session/session_manager.dart';
import 'api_envelope_interceptor.dart';
import 'auth_interceptor.dart';
import 'auth_token_refresher.dart';
import 'correlation_interceptor.dart';
import 'retry_interceptor.dart';

class NetworkClient {
  NetworkClient({
    required AppConfig config,
    required SessionManager sessionManager,
    required AuthTokenRefresher tokenRefresher,
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
    dio.interceptors.add(CorrelationInterceptor());
    dio.interceptors.add(RetryInterceptor(dio));
    dio.interceptors.add(ApiEnvelopeInterceptor());
    dio.interceptors.add(
      AuthInterceptor(
        sessionManager: sessionManager,
        tokenRefresher: tokenRefresher,
        dio: dio,
      ),
    );
  }

  final Dio dio;
}
