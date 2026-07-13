import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'firebase_id_token.dart';

/// Wrapper del SDK Firebase Auth (teléfono + email).
class FirebaseAuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  bool get isSignedIn => currentUser != null;

  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  String? get phoneNumber => currentUser?.phoneNumber;

  String? get email => currentUser?.email;

  Future<String> freshIdToken({bool forceRefresh = true}) async {
    final user = currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No hay sesión Firebase activa.',
      );
    }

    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(Duration(milliseconds: 350 * attempt));
        await user.reload();
      }
      try {
        final result = await user.getIdTokenResult(forceRefresh || attempt > 0);
        final token = result.token;
        if (token != null &&
            token.isNotEmpty &&
            FirebaseIdToken.isValidIdToken(token)) {
          if (kDebugMode) {
            final kid = FirebaseIdToken.decodeHeader(token)['kid'];
            debugPrint('[AUTH] Firebase ID token kid=$kid len=${token.length}');
          }
          return token;
        }
        lastError = 'Token sin kid o malformado (intento ${attempt + 1}).';
      } catch (error) {
        lastError = error;
      }
    }

    throw FirebaseAuthException(
      code: 'no-token',
      message:
          'No se pudo obtener el ID token de Firebase. '
                  '${lastError ?? ''}'
              .trim(),
    );
  }

  Future<void> reloadUser() async {
    await currentUser?.reload();
  }

  Future<void> sendEmailVerification() async {
    final user = currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'Inicia sesión para verificar tu correo.',
      );
    }
    await user.sendEmailVerification();
  }

  /// Cierra sesión Firebase antes de un nuevo flujo SMS (evita conflictos de credencial).
  Future<void> prepareForPhoneAuth() async {
    if (currentUser != null) {
      if (kDebugMode) {
        debugPrint('[AUTH] Cerrando sesión Firebase previa al flujo SMS.');
      }
      await signOut();
    }
  }

  Future<UserCredential> signInWithPhoneCredential({
    required String verificationId,
    required String smsCode,
  }) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );
    return signInWithCredentialRecovering(credential);
  }

  /// Login SMS normal con `signInWithCredential` (nunca `linkWithCredential`).
  Future<UserCredential> signInWithCredentialRecovering(
    AuthCredential credential,
  ) async {
    try {
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (error) {
      if (_shouldRetryAfterSignOut(error.code)) {
        if (kDebugMode) {
          debugPrint(
            '[AUTH] Reintentando signIn tras signOut (${error.code}).',
          );
        }
        await signOut();
        return _auth.signInWithCredential(credential);
      }
      rethrow;
    }
  }

  bool _shouldRetryAfterSignOut(String code) {
    return code == 'credential-already-in-use' ||
        code == 'provider-already-linked' ||
        code == 'account-exists-with-different-credential';
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<UserCredential> createUserWithEmail({
    required String email,
    required String password,
  }) => _auth.createUserWithEmailAndPassword(
    email: email.trim(),
    password: password,
  );

  Future<void> linkEmailToCurrentUser(String email) async {
    final user = currentUser;
    if (user == null) return;
    final trimmed = email.trim();
    if (trimmed.isEmpty || user.email == trimmed) return;
    await user.verifyBeforeUpdateEmail(trimmed);
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(PhoneAuthCredential credential) onCompleted,
    required void Function(FirebaseAuthException error) onFailed,
    int? forceResendingToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      forceResendingToken: forceResendingToken,
      verificationCompleted: onCompleted,
      verificationFailed: onFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> signOut() => _auth.signOut();

  /// Revierte registro Firebase si el backend falló tras crear la cuenta.
  Future<void> rollbackRecentRegistration() async {
    final user = currentUser;
    if (user == null) return;
    try {
      await user.delete();
    } catch (_) {
      await signOut();
    }
  }
}
