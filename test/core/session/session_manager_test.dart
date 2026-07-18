import 'package:ciervo_clud/core/session/auth_tokens.dart';
import 'package:ciervo_clud/core/session/session_manager.dart';
import 'package:ciervo_clud/core/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('persists access and refresh as one versioned bundle', () async {
    final storage = _MemorySecureStorage();
    final manager = SessionManager(storage);

    await manager.saveTokens(
      const AuthTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
        refreshPath: '/api/v1/kids/auth/refresh',
      ),
    );

    expect(await manager.accessToken(), 'access');
    expect(await manager.refreshToken(), 'refresh');
    expect(storage.values['ciervo.accessToken'], isNull);
    expect(storage.values['ciervo.refreshToken'], isNull);
    expect(storage.values['ciervo.authTokens.v2'], contains('refreshPath'));
  });

  test(
    'invalidates a legacy session once after auth contract change',
    () async {
      final storage = _MemorySecureStorage({
        'ciervo.accessToken': 'legacy-access',
        'ciervo.refreshToken': 'legacy-refresh',
      });
      final manager = SessionManager(storage);

      await manager.restore();

      expect(manager.didInvalidateLegacySession, isTrue);
      expect(await manager.accessToken(), isNull);
      expect(storage.values['ciervo.authContractVersion'], '2');

      final nextLaunch = SessionManager(storage);
      await nextLaunch.restore();
      expect(nextLaunch.didInvalidateLegacySession, isFalse);
    },
  );
}

class _MemorySecureStorage implements SecureStorage {
  _MemorySecureStorage([Map<String, String>? values]) : values = {...?values};

  final Map<String, String> values;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<void> deleteAll() async => values.clear();

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
