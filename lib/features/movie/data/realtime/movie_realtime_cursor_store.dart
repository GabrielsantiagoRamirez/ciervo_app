import '../../../../core/session/auth_token_claims.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/storage/secure_storage.dart';

class MovieRealtimeCursorStore {
  const MovieRealtimeCursorStore(this._storage, this._sessionManager);

  final SecureStorage _storage;
  final SessionManager _sessionManager;

  Future<int> read() async =>
      int.tryParse(await _storage.read(await _key()) ?? '') ?? 0;

  Future<void> write(int cursor) async {
    if (cursor <= 0) return;
    await _storage.write(await _key(), '$cursor');
  }

  Future<String> _key() async {
    final token = await _sessionManager.accessToken();
    final identity = token == null
        ? 'anonymous'
        : AuthTokenClaims.fromJwt(token).userId ?? 'unknown';
    return 'ciervo.movie.realtime.$identity.cursor';
  }
}
