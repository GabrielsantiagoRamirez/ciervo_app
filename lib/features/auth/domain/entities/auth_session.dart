import '../../../../core/session/auth_tokens.dart';

class AuthSession {
  const AuthSession({
    required this.tokens,
    this.userId,
    this.email,
    this.authAction,
    this.linkedLegacy = false,
  });

  final AuthTokens tokens;
  final String? userId;
  final String? email;
  final String? authAction;
  final bool linkedLegacy;

  bool get isLegacyLink => authAction == 'link_legacy' || linkedLegacy;
}
