import 'package:flutter/foundation.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../../../core/session/auth_token_claims.dart';
import '../../../../core/session/session_manager.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../dtos/login_request_dto.dart';
import '../dtos/register_request_dto.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SessionManager sessionManager,
  }) : _remoteDataSource = remoteDataSource,
       _sessionManager = sessionManager;

  final AuthRemoteDataSource _remoteDataSource;
  final SessionManager _sessionManager;

  @override
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  }) async {
    try {
      final dto = await _remoteDataSource.login(
        LoginRequestDto(email: email, password: password),
      );
      final session = dto.toDomain();
      _logAuthDecision(session.tokens.accessToken);
      await _sessionManager.saveTokens(session.tokens);
      return Success(session);
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      final refreshToken = await _sessionManager.refreshToken();
      if (refreshToken != null) {
        await _remoteDataSource.logout(refreshToken);
      }
    } catch (_) {
      // Local session must be cleared even if the server-side logout fails.
    }
    await _sessionManager.clear();
    return const Success<void>(null);
  }

  @override
  Future<Result<AuthSession>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String identityDocument,
    required String documentType,
  }) async {
    try {
      await _remoteDataSource.register(
        RegisterRequestDto(
          firstName: firstName,
          lastName: lastName,
          email: email,
          phone: phone,
          password: password,
          identityDocument: identityDocument,
          documentType: documentType,
        ),
      );
      final dto = await _remoteDataSource.login(
        LoginRequestDto(email: email, password: password),
      );
      final session = dto.toDomain();
      _logAuthDecision(session.tokens.accessToken);
      await _sessionManager.saveTokens(session.tokens);
      return Success(session);
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  void _logAuthDecision(String accessToken) {
    final claims = AuthTokenClaims.fromJwt(accessToken);
    debugPrint('[AUTH] JWT recibido: $accessToken');
    debugPrint('[AUTH] accountKind: ${claims.accountKind}');
    debugPrint('[AUTH] role: ${claims.role}');
    debugPrint('[AUTH] businessRoleId: ${claims.businessRoleId}');
  }
}
