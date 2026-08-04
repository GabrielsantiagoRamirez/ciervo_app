import 'dart:convert';

import 'package:ciervo_clud/core/session/auth_token_claims.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extrae identidad estable para aislar estado por usuario', () {
    final payload = base64Url
        .encode(
          utf8.encode(
            jsonEncode({
              'nameidentifier': 'user-42',
              'role': '4',
              'childProfileId': 9,
            }),
          ),
        )
        .replaceAll('=', '');
    final claims = AuthTokenClaims.fromJwt('header.$payload.signature');

    expect(claims.userId, 'user-42');
    expect(claims.childProfileId, 9);
    expect(claims.routeKind, 'Kid');
  });

  test('extrae userId desde claim nameid de .NET JWT', () {
    final payload = base64Url
        .encode(
          utf8.encode(
            jsonEncode({
              'nameid': '81935499',
              'role': '1',
            }),
          ),
        )
        .replaceAll('=', '');
    final claims = AuthTokenClaims.fromJwt('header.$payload.signature');

    expect(claims.userId, '81935499');
    expect(claims.isExplicitClient, isTrue);
  });
}
