import 'dart:convert';

import 'package:ciervo_clud/core/session/auth_token_claims.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps numeric production roles to route kinds', () {
    expect(AuthTokenClaims.fromJwt(_jwt({'role': 1})).routeKind, 'Client');
    expect(
      AuthTokenClaims.fromJwt(_jwt({'role': 2})).routeKind,
      'BusinessOwner',
    );
    expect(AuthTokenClaims.fromJwt(_jwt({'role': 3})).routeKind, 'SuperAdmin');
    expect(AuthTokenClaims.fromJwt(_jwt({'role': 4})).routeKind, 'Kid');
  });

  test('maps production account kinds without trusting client ids', () {
    expect(
      AuthTokenClaims.fromJwt(_jwt({'accountKind': 'BusinessUser'})).routeKind,
      'BusinessOwner',
    );
    expect(
      AuthTokenClaims.fromJwt(_jwt({'accountKind': 'PlatformAdmin'})).routeKind,
      'SuperAdmin',
    );
  });

  test('MOVE Client gate fails closed for ambiguous and non-client JWTs', () {
    expect(AuthTokenClaims.fromJwt(_jwt({'role': 1})).isExplicitClient, isTrue);
    expect(
      AuthTokenClaims.fromJwt(_jwt({'role': '1'})).isExplicitClient,
      isTrue,
    );
    expect(
      AuthTokenClaims.fromJwt(
        _jwt({
          'role': ['1', 'Client'],
        }),
      ).isExplicitClient,
      isTrue,
    );
    expect(
      AuthTokenClaims.fromJwt(_jwt({'accountKind': 'Client'})).isExplicitClient,
      isFalse,
    );
    expect(
      AuthTokenClaims.fromJwt(_jwt({'role': 4})).isExplicitClient,
      isFalse,
    );
    expect(AuthTokenClaims.fromJwt(_jwt({})).isExplicitClient, isFalse);
  });
}

String _jwt(Map<String, dynamic> claims) {
  final payload = base64Url.encode(utf8.encode(jsonEncode(claims)));
  return 'header.$payload.signature';
}
