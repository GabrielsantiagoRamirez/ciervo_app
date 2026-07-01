import 'package:firebase_auth/firebase_auth.dart';

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
    final token = await user.getIdToken(forceRefresh);
    if (token == null || token.isEmpty) {
      throw FirebaseAuthException(
        code: 'no-token',
        message: 'No se pudo obtener el token de Firebase.',
      );
    }
    return token;
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

  Future<UserCredential> signInWithPhoneCredential({
    required String verificationId,
    required String smsCode,
  }) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

  Future<UserCredential> createUserWithEmail({
    required String email,
    required String password,
  }) =>
      _auth.createUserWithEmailAndPassword(
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
}
