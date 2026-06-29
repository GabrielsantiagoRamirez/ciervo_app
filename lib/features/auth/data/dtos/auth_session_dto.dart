import '../../../../core/session/auth_tokens.dart';
import '../../domain/entities/auth_session.dart';

class AuthSessionDto {
  const AuthSessionDto({
    required this.accessToken,
    required this.refreshToken,
    this.userId,
    this.email,
    this.fullName,
    this.roleId,
    this.accountKind,
  });

  factory AuthSessionDto.fromJson(Map<String, dynamic> json) {
    final data = json['value'] ?? json['data'];
    final source = data is Map<String, dynamic> ? data : json;
    final user = source['user'] ?? source['client'];
    final userMap = user is Map<String, dynamic> ? user : source;

    return AuthSessionDto(
      accessToken: _requiredString(source, const [
        'accessToken',
        'token',
        'jwt',
      ]),
      refreshToken: _requiredString(source, const [
        'refreshToken',
        'refresh_token',
      ]),
      userId: _optionalString(userMap, const [
        'id',
        'userId',
        'clientId',
      ]) ??
          _optionalString(source, const ['userId']),
      email: _optionalString(userMap, const ['email', 'mail']) ??
          _optionalString(source, const ['email']),
      fullName: _optionalString(source, const ['fullName', 'name']),
      roleId: _optionalString(source, const ['roleId', 'role']),
      accountKind: _optionalString(source, const ['accountKind']),
    );
  }

  final String accessToken;
  final String refreshToken;
  final String? userId;
  final String? email;
  final String? fullName;
  final String? roleId;
  final String? accountKind;

  AuthSession toDomain() {
    return AuthSession(
      tokens: AuthTokens(accessToken: accessToken, refreshToken: refreshToken),
      userId: userId,
      email: email,
    );
  }

  static String _requiredString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    throw const FormatException('Token de autenticacion no encontrado.');
  }

  static String? _optionalString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }
}
