class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.refreshPath,
  });

  final String accessToken;
  final String refreshToken;
  final String? refreshPath;
}
