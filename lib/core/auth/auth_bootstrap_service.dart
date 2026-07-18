import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../errors/app_exception.dart';
import '../firebase/firebase_auth_service.dart';
import '../firebase/phone_country.dart';
import '../network/auth_token_refresher.dart';
import '../session/session_manager.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import 'auth_pending_registration_store.dart';

enum AuthBootstrapOutcome {
  authenticated,
  unauthenticated,
  pendingRegistration,
}

/// Reconcilia sesión Firebase + JWT Ciervo al abrir la app.
class AuthBootstrapService {
  AuthBootstrapService({
    required SessionManager sessionManager,
    required FirebaseAuthService firebaseAuth,
    required AuthRepository authRepository,
    required AuthTokenRefresher tokenRefresher,
    required AuthPendingRegistrationStore pendingRegistration,
    required AuthStartupMessageStore startupMessage,
  }) : _sessionManager = sessionManager,
       _firebaseAuth = firebaseAuth,
       _authRepository = authRepository,
       _tokenRefresher = tokenRefresher,
       _pendingRegistration = pendingRegistration,
       _startupMessage = startupMessage;

  final SessionManager _sessionManager;
  final FirebaseAuthService _firebaseAuth;
  final AuthRepository _authRepository;
  final AuthTokenRefresher _tokenRefresher;
  final AuthPendingRegistrationStore _pendingRegistration;
  final AuthStartupMessageStore _startupMessage;

  Future<AuthBootstrapOutcome> reconcile() async {
    _pendingRegistration.clear();

    if (_sessionManager.didInvalidateLegacySession) {
      _startupMessage.set(
        'Actualizamos la seguridad de tu sesión. Vuelve a iniciar sesión.',
      );
      await _clearAllSessions();
      return AuthBootstrapOutcome.unauthenticated;
    }

    final hasJwt = await _sessionManager.accessToken() != null;
    final firebaseUser = _firebaseAuth.currentUser;

    if (firebaseUser != null) {
      return _reconcileWithFirebaseUser(firebaseUser, hasJwt: hasJwt);
    }

    if (hasJwt) {
      final refreshed = await _tokenRefresher.refreshAccessToken();
      if (refreshed != null) {
        if (kDebugMode) {
          debugPrint('[AUTH] JWT restaurado sin sesión Firebase activa.');
        }
        return AuthBootstrapOutcome.authenticated;
      }
      await _sessionManager.clear();
    }

    return AuthBootstrapOutcome.unauthenticated;
  }

  Future<AuthBootstrapOutcome> _reconcileWithFirebaseUser(
    User firebaseUser, {
    required bool hasJwt,
  }) async {
    if (kDebugMode) {
      final uid = firebaseUser.uid;
      debugPrint(
        '[AUTH] Sesión Firebase activa uid=${uid.length > 8 ? uid.substring(0, 8) : uid}…',
      );
    }

    try {
      final token = await _firebaseAuth.freshIdToken(forceRefresh: false);

      if (hasJwt) {
        final refreshed = await _tokenRefresher.refreshAccessToken();
        if (refreshed != null) {
          return AuthBootstrapOutcome.authenticated;
        }
      }

      final contact = _contactFromFirebaseUser(firebaseUser);
      final check = await _authRepository.firebaseCheckUser(
        firebaseIdToken: token,
        phone: contact.phoneNational,
        email: contact.email,
        countryCode: contact.countryCode,
      );

      return await check.when(
        success: (result) async {
          if (result.exists || result.requiresFirebaseLink) {
            return _firebaseLoginAndPersist(
              token: token,
              phone: contact.phoneNational,
              email: contact.email,
              countryCode: contact.countryCode,
            );
          }

          if (contact.phoneNational != null) {
            _pendingRegistration.set(
              phoneNational: contact.phoneNational!,
              phoneE164: contact.phoneE164 ?? '',
              countryCode: contact.countryCode,
            );
          }
          return AuthBootstrapOutcome.pendingRegistration;
        },
        failure: (error) async {
          if (hasJwt) {
            final refreshed = await _tokenRefresher.refreshAccessToken();
            if (refreshed != null) {
              return AuthBootstrapOutcome.authenticated;
            }
          }
          await _clearAllSessions();
          return AuthBootstrapOutcome.unauthenticated;
        },
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[AUTH] reconcile Firebase falló: $error');
      }
      if (hasJwt) {
        final refreshed = await _tokenRefresher.refreshAccessToken();
        if (refreshed != null) {
          return AuthBootstrapOutcome.authenticated;
        }
      }
      await _clearAllSessions();
      return AuthBootstrapOutcome.unauthenticated;
    }
  }

  Future<AuthBootstrapOutcome> _firebaseLoginAndPersist({
    required String token,
    String? phone,
    String? email,
    required String countryCode,
  }) async {
    final login = await _authRepository.firebaseLogin(
      firebaseIdToken: token,
      phone: phone,
      email: email,
      countryCode: countryCode,
    );

    return await login.when(
      success: (_) async => AuthBootstrapOutcome.authenticated,
      failure: (error) async {
        if (_isInactiveAccount(error)) {
          _startupMessage.set(_inactiveAccountMessage(error));
          await _clearAllSessions();
          return AuthBootstrapOutcome.unauthenticated;
        }
        await _clearAllSessions();
        return AuthBootstrapOutcome.unauthenticated;
      },
    );
  }

  _FirebaseContact _contactFromFirebaseUser(User user) {
    final rawPhone = user.phoneNumber?.trim();
    if (rawPhone == null || rawPhone.isEmpty) {
      return _FirebaseContact(email: user.email?.trim(), countryCode: 'CO');
    }

    final e164 = rawPhone.startsWith('+') ? rawPhone : '+$rawPhone';
    final digits = e164.replaceAll(RegExp(r'\D'), '');
    String countryCode = 'CO';
    String? national;

    if (digits.startsWith('57')) {
      countryCode = 'CO';
      national = digits.substring(2);
    } else if (digits.startsWith('56')) {
      countryCode = 'CL';
      national = digits.substring(2);
    } else {
      national = PhoneCountry.nationalDigits(
        countryCode: countryCode,
        rawInput: digits,
      );
    }

    return _FirebaseContact(
      phoneNational: national,
      phoneE164: e164,
      email: user.email?.trim(),
      countryCode: countryCode,
    );
  }

  bool _isInactiveAccount(Object error) {
    if (error is! AppException) return false;
    final code = error.code?.toUpperCase() ?? '';
    final message = error.message.toLowerCase();
    return error.statusCode == 403 &&
        (code.contains('BLOCKED') ||
            code.contains('INACTIVE') ||
            code.contains('DISABLED') ||
            message.contains('inactiv') ||
            message.contains('bloquead'));
  }

  String _inactiveAccountMessage(Object error) {
    if (error is AppException &&
        error.message.isNotEmpty &&
        !error.message.toLowerCase().contains('permiso')) {
      return error.message;
    }
    return 'Tu cuenta no está activa. Contacta soporte.';
  }

  Future<void> _clearAllSessions() async {
    try {
      await _firebaseAuth.signOut();
    } catch (_) {}
    await _sessionManager.clear();
  }
}

class _FirebaseContact {
  const _FirebaseContact({
    this.phoneNational,
    this.phoneE164,
    this.email,
    this.countryCode = 'CO',
  });

  final String? phoneNational;
  final String? phoneE164;
  final String? email;
  final String countryCode;
}
