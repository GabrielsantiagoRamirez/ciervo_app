import 'package:flutter/foundation.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/kids/selected_kid_context.dart';
import '../../../../core/notifications/ciervo_push_service.dart';
import '../../../../core/result/result.dart';
import '../../../../core/session/auth_token_claims.dart';
import '../../../../core/session/session_manager.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../dtos/account_lookup_dto.dart';
import '../dtos/firebase_auth_dtos.dart';
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
    try {
      await getIt<CiervoPushService>().unregisterAllTokens();
    } catch (_) {}
    getIt<SelectedKidContext>().clear();
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
    required String countryCode,
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
          countryCode: countryCode,
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

  @override
  Future<Result<AuthSession>> firebaseLogin({
    required String firebaseIdToken,
    String? phone,
  }) async {
    try {
      final dto = await _remoteDataSource.firebaseLogin(
        firebaseIdToken: firebaseIdToken,
        phone: phone,
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
  Future<Result<AuthSession>> firebaseRegister({
    required String firebaseIdToken,
    required Map<String, dynamic> profile,
  }) async {
    try {
      final dto = await _remoteDataSource.firebaseRegister(
        firebaseIdToken: firebaseIdToken,
        profile: profile,
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
  Future<Result<FirebaseCheckUserResult>> firebaseCheckUser({
    required String firebaseIdToken,
    String? phone,
  }) async {
    try {
      return Success(
        await _remoteDataSource.firebaseCheckUser(
          firebaseIdToken: firebaseIdToken,
          phone: phone,
        ),
      );
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<VerificationSyncResult>> firebaseSyncVerification({
    required String firebaseIdToken,
  }) async {
    try {
      return Success(
        await _remoteDataSource.firebaseSyncVerification(
          firebaseIdToken: firebaseIdToken,
        ),
      );
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<AccountLookupResult>> lookupAccount({
    String? email,
    String? phone,
  }) async {
    try {
      return Success(
        await _remoteDataSource.lookupAccount(email: email, phone: phone),
      );
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void>> sendEmailVerificationCode(String email) async {
    try {
      await _remoteDataSource.sendEmailVerificationCode(email);
      return const Success(null);
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void>> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    try {
      await _remoteDataSource.verifyEmailCode(email: email, code: code);
      return const Success(null);
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
