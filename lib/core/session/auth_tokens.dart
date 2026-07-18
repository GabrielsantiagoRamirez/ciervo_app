class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.refreshPath,
    this.deviceId,
  });

  final String accessToken;
  final String refreshToken;
  final String? refreshPath;
  final String? deviceId;
}
