import 'dart:convert';

class AuthTokenClaims {
  const AuthTokenClaims({
    required this.raw,
    required this.claims,
    this.accountKind,
    this.role,
    this.businessRoleId,
  });

  factory AuthTokenClaims.fromJwt(String token) {
    final parts = token.split('.');
    if (parts.length < 2) {
      return AuthTokenClaims(raw: token, claims: const {});
    }

    try {
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final decoded = jsonDecode(payload);
      final claims = decoded is Map<String, dynamic>
          ? decoded
          : const <String, dynamic>{};
      return AuthTokenClaims(
        raw: token,
        claims: claims,
        accountKind: _firstString(claims, const [
          'accountKind',
          'account_kind',
          'typ',
          'userType',
          'user_type',
        ]),
        role: _firstString(claims, const [
          'role',
          'roleName',
          'role_name',
          'http://schemas.microsoft.com/ws/2008/06/identity/claims/role',
        ]),
        businessRoleId: _firstString(claims, const [
          'businessRoleId',
          'business_role_id',
          'roleId',
          'role_id',
        ]),
      );
    } catch (_) {
      return AuthTokenClaims(raw: token, claims: const {});
    }
  }

  final String raw;
  final Map<String, dynamic> claims;
  final String? accountKind;
  final String? role;
  final String? businessRoleId;

  String get routeKind {
    final values = [
      accountKind,
      role,
      claims['accountType']?.toString(),
      claims['account_type']?.toString(),
    ].whereType<String>().map((item) => item.toLowerCase()).join(' ');

    if (values.contains('superadmin') || values.contains('super_admin')) {
      return 'SuperAdmin';
    }
    if (values.contains('businessowner') ||
        values.contains('business_owner') ||
        values.contains('owner') ||
        values.contains('dueno') ||
        values.contains('dueño')) {
      return 'BusinessOwner';
    }
    if (values.contains('staff') || values.contains('employee')) {
      return 'Staff';
    }
    if (values.contains('kid') ||
        role?.toLowerCase() == 'kid' ||
        role == '4') {
      return 'Kid';
    }
    return 'Client';
  }
}

String? _firstString(Map<String, dynamic> claims, List<String> keys) {
  for (final key in keys) {
    final value = claims[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }
  return null;
}
