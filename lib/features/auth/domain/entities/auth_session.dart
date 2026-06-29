import '../../../../core/session/auth_tokens.dart';

class AuthSession {
  const AuthSession({
    required this.tokens,
    this.userId,
    this.email,
  });

  final AuthTokens tokens;
  final String? userId;
  final String? email;
}
