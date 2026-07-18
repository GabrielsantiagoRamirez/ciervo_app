import 'dart:async';
import 'dart:convert';

import '../storage/secure_storage.dart';
import 'auth_tokens.dart';
import 'session_state.dart';

class SessionManager {
  SessionManager(this._storage);

  static const _accessTokenKey = 'ciervo.accessToken';
  static const _refreshTokenKey = 'ciervo.refreshToken';
  static const _tokenBundleKey = 'ciervo.authTokens.v2';
  static const _contractVersionKey = 'ciervo.authContractVersion';
  static const _currentContractVersion = '2';

  final SecureStorage _storage;
  final StreamController<SessionState> _controller =
      StreamController<SessionState>.broadcast();

  SessionState _state = const SessionState.unknown();
  bool _didInvalidateLegacySession = false;

  SessionState get state => _state;

  Stream<SessionState> get stream => _controller.stream;

  bool get didInvalidateLegacySession => _didInvalidateLegacySession;

  Future<void> restore() async {
    try {
      _didInvalidateLegacySession = false;
      final storedVersion = await _storage.read(_contractVersionKey);
      final legacyAccessToken = await _storage.read(_accessTokenKey);
      final legacyRefreshToken = await _storage.read(_refreshTokenKey);

      if (storedVersion != _currentContractVersion &&
          (legacyAccessToken != null || legacyRefreshToken != null)) {
        await _deleteTokenData();
        await _storage.write(_contractVersionKey, _currentContractVersion);
        _didInvalidateLegacySession = true;
        _emit(const SessionState.unauthenticated());
        return;
      }

      if (storedVersion != _currentContractVersion) {
        await _storage.write(_contractVersionKey, _currentContractVersion);
      }

      final tokens = await _readTokenBundle();
      _emit(
        tokens != null
            ? const SessionState.authenticated()
            : const SessionState.unauthenticated(),
      );
    } catch (_) {
      _emit(const SessionState.unauthenticated());
    }
  }

  Future<String?> accessToken() async {
    return (await tokens())?.accessToken;
  }

  Future<String?> refreshToken() async {
    return (await tokens())?.refreshToken;
  }

  Future<AuthTokens?> tokens() => _readTokenBundle();

  Future<void> saveTokens(AuthTokens tokens) async {
    final bundle = jsonEncode({
      'accessToken': tokens.accessToken,
      'refreshToken': tokens.refreshToken,
      if (tokens.refreshPath != null) 'refreshPath': tokens.refreshPath,
      if (tokens.deviceId != null) 'deviceId': tokens.deviceId,
    });
    await _storage.write(_tokenBundleKey, bundle);
    await _storage.write(_contractVersionKey, _currentContractVersion);
    await _storage.delete(_accessTokenKey);
    await _storage.delete(_refreshTokenKey);
    _emit(const SessionState.authenticated());
  }

  Future<void> clear() async {
    await _deleteTokenData();
    await _storage.write(_contractVersionKey, _currentContractVersion);
    _emit(const SessionState.unauthenticated());
  }

  Future<void> _deleteTokenData() async {
    await _storage.delete(_tokenBundleKey);
    await _storage.delete(_accessTokenKey);
    await _storage.delete(_refreshTokenKey);
  }

  Future<AuthTokens?> _readTokenBundle() async {
    final raw = await _storage.read(_tokenBundleKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final accessToken = decoded['accessToken']?.toString() ?? '';
      final refreshToken = decoded['refreshToken']?.toString() ?? '';
      if (accessToken.isEmpty || refreshToken.isEmpty) return null;
      return AuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        refreshPath: decoded['refreshPath']?.toString(),
        deviceId: decoded['deviceId']?.toString(),
      );
    } on FormatException {
      return null;
    }
  }

  void markUnauthenticated() => _emit(const SessionState.unauthenticated());

  void dispose() {
    _controller.close();
  }

  void _emit(SessionState state) {
    _state = state;
    _controller.add(state);
  }
}
