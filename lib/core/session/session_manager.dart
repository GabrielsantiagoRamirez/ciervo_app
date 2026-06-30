import 'dart:async';

import '../storage/secure_storage.dart';
import 'auth_tokens.dart';
import 'session_state.dart';

class SessionManager {
  SessionManager(this._storage);

  static const _accessTokenKey = 'ciervo.accessToken';
  static const _refreshTokenKey = 'ciervo.refreshToken';

  final SecureStorage _storage;
  final StreamController<SessionState> _controller =
      StreamController<SessionState>.broadcast();

  SessionState _state = const SessionState.unknown();

  SessionState get state => _state;

  Stream<SessionState> get stream => _controller.stream;

  Future<void> restore() async {
    try {
      final accessToken = await _storage.read(_accessTokenKey);
      final refreshToken = await _storage.read(_refreshTokenKey);
      _emit(
        accessToken != null && refreshToken != null
            ? const SessionState.authenticated()
            : const SessionState.unauthenticated(),
      );
    } catch (_) {
      _emit(const SessionState.unauthenticated());
    }
  }

  Future<String?> accessToken() => _storage.read(_accessTokenKey);

  Future<String?> refreshToken() => _storage.read(_refreshTokenKey);

  Future<void> saveTokens(AuthTokens tokens) async {
    await _storage.write(_accessTokenKey, tokens.accessToken);
    await _storage.write(_refreshTokenKey, tokens.refreshToken);
    _emit(const SessionState.authenticated());
  }

  Future<void> clear() async {
    await _storage.delete(_accessTokenKey);
    await _storage.delete(_refreshTokenKey);
    _emit(const SessionState.unauthenticated());
  }

  void dispose() {
    _controller.close();
  }

  void _emit(SessionState state) {
    _state = state;
    _controller.add(state);
  }
}
